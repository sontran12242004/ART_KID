using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

// A mixed order is complete only after every platform allocation and every seller has delivered.
internal static class OrderFulfillment
{
    public static bool CanSellerFulfill(Order order) =>
        order.Status != "cancelled"
        && (order.PaymentMethodName == "cod" || order.PaymentStatus == "paid");

    public static string SellerStatus(Order order, string? fulfillmentStatus) =>
        order.Status == "cancelled"
            ? "cancelled"
            : fulfillmentStatus ?? (CanSellerFulfill(order) ? "preparing" : "pending_payment");

    public static Task<bool> SellerDispatched(IUnitOfWork store, string orderId) =>
        store
            .Repository<SellerFulfillment>()
            .Query.AnyAsync(s =>
                s.OrderId == orderId
                && (s.ShippedAt != null || s.Status == "shipping" || s.Status == "delivered")
            );

    public static async Task UpdateCompletion(IUnitOfWork store, Order order)
    {
        if (order.Status == "cancelled")
            return;
        var items = store.Repository<OrderItem>().Query.Where(i => i.OrderId == order.Id);
        var itemIds = items.Select(i => i.Id);
        if (order.Status == "pending_confirmation" && await items.AnyAsync(i => i.SellerId == null))
            return;
        // A seller dispatch must not confirm, complete or expire the platform portion of a mixed order.
        if (
            await store
                .Repository<InventoryReservation>()
                .Query.AnyAsync(r => itemIds.Contains(r.OrderItemId) && r.Status == "reserved")
        )
            return;
        if (order.Status == "pending_confirmation" && CanSellerFulfill(order))
            order.Status = "preparing";
        var expected = await store
            .Repository<InventoryReservation>()
            .Query.Where(r => itemIds.Contains(r.OrderItemId) && r.Status == "committed")
            .SumAsync(r => r.Quantity);
        var delivered = await store
            .Repository<FulfillmentOrder>()
            .Query.Where(s => s.OrderId == order.Id && s.Status == "delivered")
            .SumAsync(s => s.Quantity);
        var sellerIds = await items
            .Where(i => i.SellerId != null)
            .Select(i => i.SellerId!)
            .Distinct()
            .ToListAsync();
        var sellerShipments = await store
            .Repository<SellerFulfillment>()
            .Query.Where(s => s.OrderId == order.Id)
            .ToListAsync();
        if (
            delivered == expected
            && sellerIds.All(id =>
                sellerShipments.Any(s => s.SellerId == id && s.Status == "delivered")
            )
        )
        {
            order.Status = "delivered";
            // Seller-reported delivery is not evidence of COD collection.
            if (order.PaymentStatus == "cod" && sellerIds.Count == 0)
            {
                order.PaymentStatus = "paid";
                order.PaidAt = DateTime.UtcNow;
            }
        }
        else if (
            sellerShipments.Any(s => s.Status is "shipping" or "delivered")
            || await store
                .Repository<FulfillmentOrder>()
                .Query.AnyAsync(s =>
                    s.OrderId == order.Id && (s.Status == "shipping" || s.Status == "delivered")
                )
        )
            order.Status = "shipping";
    }
}
