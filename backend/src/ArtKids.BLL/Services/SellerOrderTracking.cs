using System.Security.Cryptography;
using System.Text;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

internal static class SellerOrderTracking
{
    // Called only inside the existing serializable checkout/fulfillment transaction.
    public static async Task Record(
        IUnitOfWork store,
        Order order,
        string sellerId,
        string status,
        bool readyOnly = false
    )
    {
        var key = Encoding.UTF8.GetBytes($"{order.Id}:{sellerId}:{status}");
        var id = "seller-" + Convert.ToHexString(SHA256.HashData(key))[..48];
        var events = store.Repository<OrderTrackingEvent>();
        if (await events.FindAsync(id) is not null)
            return;
        var name = await store
            .Repository<User>()
            .Query.Where(u => u.Id == sellerId)
            .Select(u => u.FullName)
            .SingleAsync();
        var (title, description) = status switch
        {
            "preparing" => (
                "Đang chuẩn bị học cụ",
                readyOnly
                    ? $"Học cụ của giảng viên {name} đã sẵn sàng để chuẩn bị."
                    : $"Giảng viên {name} cho biết đang chuẩn bị học cụ."
            ),
            "shipping" => (
                "Giảng viên báo đã gửi hàng",
                $"Giảng viên {name} cho biết đã gửi phần học cụ của mình. Thông tin này chưa được hãng vận chuyển xác minh."
            ),
            "delivered" => (
                "Giảng viên báo đã giao hàng",
                $"Giảng viên {name} cho biết đã giao phần học cụ của mình. Thông tin này chưa được hãng vận chuyển xác minh; không xác nhận đã thu tiền COD."
            ),
            _ => throw new InvalidOperationException("Unsupported seller tracking state."),
        };
        foreach (
            var old in await events
                .Query.Where(e => e.OrderId == order.Id && e.IsCurrent)
                .ToListAsync()
        )
        {
            old.IsCurrent = false;
            old.IsPassed = true;
        }
        events.Add(
            new OrderTrackingEvent
            {
                Id = id,
                OrderId = order.Id,
                Title = title,
                Description = description,
                IsCurrent = true,
                IsPassed = false,
            }
        );
        await store.SaveAsync();
    }

    // Response copies keep legacy stored history intact and make one latest milestone current.
    public static List<OrderTrackingEvent> ForParent(List<OrderTrackingEvent> events) =>
        events
            .Select(
                (e, index) =>
                    new OrderTrackingEvent
                    {
                        Id = e.Id,
                        CreatedAt = e.CreatedAt,
                        OrderId = e.OrderId,
                        Title = e.Title switch
                        {
                            "shipping" => "Phần hàng nền tảng đang được giao",
                            "delivered" => "Phần hàng nền tảng đã giao",
                            "returned" => "Phần hàng nền tảng đã hoàn trả",
                            _ => e.Title,
                        },
                        Description = Localize(e.Description),
                        Timestamp = e.Timestamp,
                        IsPassed = index < events.Count - 1,
                        IsCurrent = index == events.Count - 1,
                        CancelReason = e.CancelReason is null ? null : Localize(e.CancelReason),
                    }
            )
            .ToList();

    public static string Localize(string text) =>
        text switch
        {
            "Seller COD fulfillment may begin; collection is unverified." =>
                "Đơn COD đã được tạo. Giảng viên có thể chuẩn bị học cụ; tiền COD chưa được xác minh đã thu.",
            "Awaiting verified funds; marketplace transfer verification policy is not configured." =>
                "Đơn đang chờ xác minh chuyển khoản. Vui lòng chờ hướng dẫn về tài khoản nhận tiền và quy trình xác minh; chưa thể giao hàng.",
            "Awaiting admin confirmation; no payment gateway has been charged." =>
                "Đơn đã được tạo, đang chờ xử lý. Chưa ghi nhận khoản thanh toán qua cổng thanh toán.",
            "Confirmed by administrator." => "Quản trị viên đã ghi nhận việc xử lý đơn hàng.",
            "Stock reservation expired." =>
                "Đơn đã bị hủy do hết thời gian giữ phần hàng nền tảng.",
            _ => text,
        };
}
