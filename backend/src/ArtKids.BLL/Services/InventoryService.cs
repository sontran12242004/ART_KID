using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class InventoryService(IUnitOfWork store, ICurrentUser actor)
    : ServiceBase(store, actor)
{
    public async Task<object> Stock(int page, int size)
    {
        Roles("admin");
        return await Q<InventorySku>()
            .OrderBy(x => x.Sku)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
    }

    public async Task<InventorySku> BySku(string sku)
    {
        Roles("admin");
        return await Q<InventorySku>().SingleOrDefaultAsync(x => x.Sku == sku)
            ?? throw new BusinessException(404, "SKU not found.");
    }

    public async Task<InventorySku> Create(InventoryRequest r)
    {
        Roles("admin");
        var p = await Get<Product>(r.ProductId);
        Require(
            p.FulfillmentMode == "platform",
            "Seller listings do not use warehouse inventory.",
            409
        );
        Require(
            !await Q<InventorySku>().AnyAsync(x => x.Sku == r.Sku || x.ProductId == r.ProductId),
            "SKU or product inventory already exists.",
            409
        );
        var sku = new InventorySku
        {
            ProductId = p.Id,
            Sku = r.Sku,
            KitName = p.Name,
            QuantityAvailable = r.QuantityAvailable,
            ReorderThreshold = r.ReorderThreshold,
            UnitCostVnd = r.UnitCostVnd,
            WarehouseLocation = r.WarehouseLocation,
        };
        Add(sku);
        await Store.SaveAsync();
        return sku;
    }

    public Task<InventorySku> Adjust(string id, StockAdjustmentRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            Roles("admin");
            var sku = await Get<InventorySku>(id);
            Require(
                sku.QuantityAvailable + r.Delta >= 0,
                "Cannot adjust available stock below zero.",
                409
            );
            sku.QuantityAvailable += r.Delta;
            return sku;
        });
    }

    public Task<FulfillmentOrder> CreateShipment(ShipmentRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            Roles("admin");
            var o = await Get<Order>(r.OrderId);
            Require(o.Status is "preparing" or "shipping", "Confirm order before shipping.", 409);
            var old = await Q<FulfillmentOrder>()
                .SingleOrDefaultAsync(x =>
                    x.OrderId == r.OrderId
                    && x.InventorySkuId == r.InventorySkuId
                    && x.SubscriptionKitDeliveryId == r.SubscriptionKitDeliveryId
                );
            if (old is not null)
                return old;
            var sku = await Get<InventorySku>(r.InventorySkuId);
            var ids = Q<OrderItem>()
                .Where(x =>
                    x.OrderId == o.Id
                    && (r.SubscriptionKitDeliveryId != null || x.ItemType == "kit")
                )
                .Select(x => x.Id);
            var reserved = await Q<InventoryReservation>()
                .Where(x =>
                    ids.Contains(x.OrderItemId)
                    && x.InventorySkuId == sku.Id
                    && x.Status == "committed"
                )
                .ToListAsync();
            Require(reserved.Count > 0, "SKU is not allocated to this order.");
            Require(
                !await Q<FulfillmentOrder>()
                    .AnyAsync(x => x.Carrier == r.Carrier && x.TrackingNumber == r.TrackingNumber),
                "Tracking number already exists.",
                409
            );
            var quantity = reserved.Sum(x => x.Quantity);
            if (r.SubscriptionKitDeliveryId is not null)
            {
                var delivery = await Get<SubscriptionKitDelivery>(r.SubscriptionKitDeliveryId);
                var subscription = await Get<Subscription>(delivery.SubscriptionId);
                var item = await Get<OrderItem>(subscription.OrderItemId);
                Require(
                    item.OrderId == o.Id && delivery.InventorySkuId == sku.Id,
                    "Scheduled kit does not belong to this order/SKU."
                );
                Require(
                    delivery.ScheduledFor <= DateTime.UtcNow.AddDays(7),
                    "This kit is not due for dispatch yet.",
                    409
                );
                quantity = delivery.Quantity;
            }

            var a = await Q<OrderShippingInfo>().SingleAsync(x => x.OrderId == o.Id);
            var s = new FulfillmentOrder
            {
                OrderId = o.Id,
                InventorySkuId = sku.Id,
                SubscriptionKitDeliveryId = r.SubscriptionKitDeliveryId,
                KitName = sku.KitName,
                Quantity = quantity,
                Carrier = r.Carrier,
                TrackingNumber = r.TrackingNumber,
                ShippingAddress = a.FullAddress,
                RecipientName = a.RecipientName,
                RecipientPhone = a.PhoneNumber,
                EstimatedDeliveryDate = r.EstimatedDeliveryDate,
            };
            Add(s);
            return s;
        });
    }

    public async Task<object> Shipments(int page, int size)
    {
        var q = Q<FulfillmentOrder>();
        if (Actor.Role != "admin")
        {
            var ids = Q<Order>().Where(x => x.ParentId == Actor.Id).Select(x => x.Id);
            q = q.Where(x => ids.Contains(x.OrderId));
        }

        return await q.OrderByDescending(x => x.CreatedAt)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
    }

    public async Task<FulfillmentOrder> Track(string trackingNumber)
    {
        var s =
            await Q<FulfillmentOrder>().FirstOrDefaultAsync(x => x.TrackingNumber == trackingNumber)
            ?? throw new BusinessException(404, "Shipment not found.");
        var o = await Get<Order>(s.OrderId);
        Require(Actor.Role == "admin" || o.ParentId == Actor.Id, "Shipment not found.", 404);
        return s;
    }

    public Task<FulfillmentOrder> UpdateStatus(string id, string status)
    {
        Roles("admin");
        return ApplyStatus(id, status);
    }

    // Only the HMAC-verified webhook controller may call this entry point.
    public Task<FulfillmentOrder> ApplyWebhook(string id, string status)
    {
        return ApplyStatus(id, status);
    }

    private Task<FulfillmentOrder> ApplyStatus(string id, string status)
    {
        return Store.TransactionAsync(async () =>
        {
            var s = await Get<FulfillmentOrder>(id);
            if (s.Status == status)
                return s;
            Require(
                (s.Status == "packed" && status == "shipping")
                    || (s.Status == "shipping" && (status is "delivered" or "returned")),
                "Invalid shipment state transition.",
                409
            );
            s.Status = status;
            var o = await Get<Order>(s.OrderId);
            if (status == "shipping")
            {
                s.ShippedAt = DateTime.UtcNow;
                o.Status = "shipping";
            }

            if (status == "returned")
            {
                (await Get<InventorySku>(s.InventorySkuId)).QuantityAvailable += s.Quantity;
            }

            await Store.SaveAsync();
            if (status == "delivered")
            {
                s.DeliveredAt = DateTime.UtcNow;
                await OrderFulfillment.UpdateCompletion(Store, o);
            }

            Add(
                new OrderTrackingEvent
                {
                    OrderId = o.Id,
                    Title = status,
                    Description = $"{s.Carrier} / {s.TrackingNumber}",
                }
            );
            Notify(o.ParentId, "Cập nhật giao hàng", status, o.Id);
            return s;
        });
    }
}
