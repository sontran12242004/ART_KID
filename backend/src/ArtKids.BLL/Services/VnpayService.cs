using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using ArtKids.BLL.Common;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ArtKids.BLL.Services;

public sealed class VnpayService(IUnitOfWork store, ICurrentUser actor, IConfiguration config)
    : ServiceBase(store, actor)
{
    private string Setting(string key) => config[$"Vnpay:{key}"] ?? "";

    public bool IsConfigured =>
        bool.TryParse(Setting("Enabled"), out var enabled)
        && enabled
        && !string.IsNullOrWhiteSpace(Setting("TmnCode"))
        && !string.IsNullOrWhiteSpace(Setting("HashSecret"))
        && !Setting("TmnCode").Contains("REPLACE", StringComparison.OrdinalIgnoreCase)
        && !Setting("HashSecret").Contains("REPLACE", StringComparison.OrdinalIgnoreCase);

    public void EnsureConfigured() =>
        Require(
            IsConfigured,
            "VNPay Sandbox chưa được cấu hình. Vui lòng điền Vnpay:TmnCode và Vnpay:HashSecret tại backend.",
            503
        );

    private static string Canonical(IEnumerable<KeyValuePair<string, string>> data) =>
        string.Join(
            "&",
            data.Where(x =>
                    x.Key.StartsWith("vnp_", StringComparison.Ordinal)
                    && x.Key is not ("vnp_SecureHash" or "vnp_SecureHashType")
                    && !string.IsNullOrEmpty(x.Value)
                )
                .OrderBy(x => x.Key, StringComparer.Ordinal)
                .Select(x => WebUtility.UrlEncode(x.Key) + "=" + WebUtility.UrlEncode(x.Value))
        );

    private string Sign(IEnumerable<KeyValuePair<string, string>> data) =>
        Convert
            .ToHexString(
                HMACSHA512.HashData(
                    Encoding.UTF8.GetBytes(Setting("HashSecret")),
                    Encoding.UTF8.GetBytes(Canonical(data))
                )
            )
            .ToLowerInvariant();

    public bool Verify(IReadOnlyDictionary<string, string> data)
    {
        if (!IsConfigured || !data.TryGetValue("vnp_SecureHash", out var supplied))
            return false;
        try
        {
            return CryptographicOperations.FixedTimeEquals(
                Convert.FromHexString(Sign(data)),
                Convert.FromHexString(supplied)
            );
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private async Task<Order> ParentOrder(string id)
    {
        Roles("parent");
        var order = await Get<Order>(id);
        Require(order.ParentId == Actor.Id, "Order not found.", 404);
        return order;
    }

    public async Task<object> Status(string id)
    {
        var order = await ParentOrder(id);
        return new
        {
            order.Id,
            order.OrderCode,
            order.PaymentStatus,
            order.TotalAmountVnd,
            order.Status,
            canPay = order.PaymentMethodName == "vnpay"
                && order.PaymentStatus != "paid"
                && order.Status == "pending_confirmation",
            isConfigured = IsConfigured,
        };
    }

    public Task<object> Create(string id, string ip) =>
        Store.TransactionAsync<object>(async () =>
        {
            EnsureConfigured();
            var order = await ParentOrder(id);
            Require(
                order.PaymentMethodName == "vnpay"
                    && order.Status == "pending_confirmation"
                    && order.PaymentStatus != "paid",
                "Đơn hàng không thể thanh toán VNPay.",
                409
            );
            Require(order.TotalAmountVnd > 0, "VNPay yêu cầu số tiền lớn hơn 0.");
            var itemIds = Q<OrderItem>().Where(x => x.OrderId == id).Select(x => x.Id);
            Require(
                !await Q<InventoryReservation>()
                    .AnyAsync(x =>
                        itemIds.Contains(x.OrderItemId)
                        && (x.Status != "reserved" || x.ExpiresAt <= DateTime.UtcNow)
                    ),
                "Đơn hàng đã hết thời gian giữ hàng. Vui lòng hủy và đặt lại.",
                409
            );
            var payment = await Q<VnpayPayment>()
                .Where(x =>
                    x.OrderId == id && x.Status == "pending" && x.ExpiresAt > DateTime.UtcNow
                )
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync();
            if (payment is null)
            {
                payment = new VnpayPayment
                {
                    OrderId = id,
                    AmountVnd = order.TotalAmountVnd,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                };
                Add(payment);
            }
            var zone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
            string Date(DateTime value) =>
                TimeZoneInfo
                    .ConvertTimeFromUtc(value, zone)
                    .ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture);
            var data = new Dictionary<string, string>
            {
                ["vnp_Version"] = "2.1.0",
                ["vnp_Command"] = "pay",
                ["vnp_TmnCode"] = Setting("TmnCode"),
                ["vnp_Amount"] = checked(payment.AmountVnd * 100).ToString(
                    CultureInfo.InvariantCulture
                ),
                ["vnp_CurrCode"] = "VND",
                ["vnp_TxnRef"] = payment.Id,
                ["vnp_OrderInfo"] = "Thanh toan " + order.OrderCode,
                ["vnp_OrderType"] = "other",
                ["vnp_Locale"] = "vn",
                ["vnp_ReturnUrl"] = Setting("ReturnUrl"),
                ["vnp_IpAddr"] = ip,
                ["vnp_CreateDate"] = Date(payment.CreatedAt),
                ["vnp_ExpireDate"] = Date(payment.ExpiresAt),
            };
            var gateway = Setting("PaymentUrl");
            Require(
                gateway == "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html",
                "Only the VNPay Sandbox gateway is enabled.",
                503
            );
            return new
            {
                paymentUrl = gateway + "?" + Canonical(data) + "&vnp_SecureHash=" + Sign(data),
                payment.Id,
                payment.ExpiresAt,
            };
        });

    public async Task<(string Code, string Message)> Ipn(IReadOnlyDictionary<string, string> data)
    {
        if (!Verify(data))
            return ("97", "Invalid signature");
        return await Store.TransactionAsync(async () =>
        {
            if (!data.TryGetValue("vnp_TxnRef", out var reference))
                return ("01", "Order not found");
            var payment = await Q<VnpayPayment>().SingleOrDefaultAsync(x => x.Id == reference);
            if (payment is null)
                return ("01", "Order not found");
            var order = await Get<Order>(payment.OrderId);
            if (data.GetValueOrDefault("vnp_TmnCode") != Setting("TmnCode"))
                return ("97", "Invalid merchant");
            if (
                !long.TryParse(
                    data.GetValueOrDefault("vnp_Amount"),
                    NumberStyles.None,
                    CultureInfo.InvariantCulture,
                    out var amount
                )
                || amount != checked(payment.AmountVnd * 100)
                || order.TotalAmountVnd != payment.AmountVnd
            )
                return ("04", "Invalid amount");
            if (payment.Status != "pending")
                return ("02", "Already confirmed");
            payment.ResponseCode = data.GetValueOrDefault("vnp_ResponseCode");
            if (
                payment.ResponseCode != "00"
                || data.GetValueOrDefault("vnp_TransactionStatus") != "00"
            )
            {
                payment.Status = "failed";
                return ("00", "Confirm success");
            }
            var transactionNo = data.GetValueOrDefault("vnp_TransactionNo");
            if (string.IsNullOrWhiteSpace(transactionNo) || transactionNo == "0")
                return ("99", "Invalid transaction");
            if (
                await Q<VnpayPayment>()
                    .AnyAsync(x => x.TransactionNo == transactionNo && x.Id != payment.Id)
            )
                return ("99", "Duplicate transaction");
            payment.Status = "paid";
            payment.PaidAt = DateTime.UtcNow;
            payment.TransactionNo = transactionNo;
            // Record verified funds even for late/cancelled orders; fulfillment remains blocked
            // by the order's cancellation/reservation checks and can be reconciled by an admin.
            var alreadyPaid = order.PaymentStatus == "paid";
            order.PaymentStatus = "paid";
            order.PaidAt ??= payment.PaidAt;
            Add(
                new OrderTrackingEvent
                {
                    OrderId = order.Id,
                    Title = "VNPay: đã nhận thanh toán",
                    Description =
                        order.Status == "cancelled"
                        || alreadyPaid
                        || payment.ExpiresAt <= DateTime.UtcNow
                            ? "Giao dịch đến muộn, đơn đã hủy hoặc có thanh toán trước đó. Cần quản trị viên đối soát và hoàn tiền nếu cần."
                            : "VNPay Sandbox đã xác nhận thanh toán. Đơn đang chờ xử lý giao hàng.",
                }
            );
            return ("00", "Confirm success");
        });
    }

    public async Task<string> ReturnUrl(IReadOnlyDictionary<string, string> data)
    {
        var front = Setting("FrontendReturnUrl");
        if (!Verify(data) || data.GetValueOrDefault("vnp_TmnCode") != Setting("TmnCode"))
            return front + "?result=invalid";
        var payment = await Q<VnpayPayment>()
            .SingleOrDefaultAsync(x => x.Id == data.GetValueOrDefault("vnp_TxnRef"));
        if (
            payment is null
            || !long.TryParse(
                data.GetValueOrDefault("vnp_Amount"),
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out var amount
            )
            || amount != checked(payment.AmountVnd * 100)
        )
            return front + "?result=invalid";
        return front
            + "?orderId="
            + Uri.EscapeDataString(payment.OrderId)
            + "&result="
            + (
                data.GetValueOrDefault("vnp_ResponseCode") == "00"
                && data.GetValueOrDefault("vnp_TransactionStatus") == "00"
                    ? "pending"
                    : "failed"
            );
    }
}
