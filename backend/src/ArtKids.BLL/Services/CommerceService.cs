using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class CommerceService(
    IUnitOfWork store,
    ICurrentUser actor,
    MarketplaceService marketplace
) : ServiceBase(store, actor)
{
    public async Task<object> Products(
        int page,
        int size,
        string? search,
        string? category,
        string? courseId = null
    )
    {
        var q = Q<Product>().Where(x => x.IsActive && x.ApprovalStatus == "approved");
        if (!string.IsNullOrWhiteSpace(search))
            q = q.Where(x => x.Name.Contains(search));
        if (category is not null && category != "all")
            q = q.Where(x => x.Category == category);
        if (courseId is not null)
            q = q.Where(x => x.CourseId == courseId);
        return new
        {
            total = await q.CountAsync(),
            page = Page(page),
            pageSize = Size(size),
            items = await q.OrderBy(x => x.Name)
                .Skip((Page(page) - 1) * Size(size))
                .Take(Size(size))
                .Select(x => new
                {
                    product = x,
                    inStock = x.FulfillmentMode == "seller"
                        ? x.IsAvailable
                        : Q<InventorySku>()
                            .Any(s => s.ProductId == x.Id && s.QuantityAvailable > 0),
                })
                .ToListAsync(),
        };
    }

    public async Task<object> Product(string id)
    {
        var p = await Get<Product>(id);
        Require(p.IsActive && p.ApprovalStatus == "approved", "Product not found.", 404);
        return new
        {
            product = p,
            inStock = p.FulfillmentMode == "seller"
                ? p.IsAvailable
                : await Q<InventorySku>()
                    .AnyAsync(x => x.ProductId == id && x.QuantityAvailable > 0),
        };
    }

    public Task<Product> CreateCourseProduct(string courseId, CourseProductRequest r)
    {
        return marketplace.Save(
            null,
            new SellerListingRequest(
                r.Name,
                r.PriceVnd,
                r.Description,
                r.ImageAssetId,
                courseId,
                r.QuantityAvailable > 0
            )
        );
    }

    public async Task<Product> SaveProduct(string? id, ProductRequest r)
    {
        Roles("admin");
        if (r.CourseId is not null)
            await Get<Course>(r.CourseId);
        if (r.RecommendedSubscriptionPlanId is not null)
            await Get<SubscriptionPlan>(r.RecommendedSubscriptionPlanId);
        Require(
            r.OriginalPriceVnd is null || r.OriginalPriceVnd >= 0,
            "Original price must be nonnegative."
        );
        var p = id is null ? new Product { CreatedBy = Actor.Id } : await Get<Product>(id);
        Require(
            p.FulfillmentMode == "platform",
            "Use the marketplace review workflow for seller listings.",
            409
        );
        p.Name = r.Name;
        p.PriceVnd = r.PriceVnd;
        p.OriginalPriceVnd = r.OriginalPriceVnd;
        p.Description = r.Description;
        p.Category = r.Category;
        p.ThumbnailUrl = r.ThumbnailUrl;
        p.CourseId = r.CourseId;
        p.RecommendedSubscriptionPlanId = r.RecommendedSubscriptionPlanId;
        p.Images = r.Images ?? [];
        p.KitItems = r.KitItems ?? [];
        p.IsActive = r.IsActive;
        if (id is null)
            Add(p);
        await Store.SaveAsync();
        return p;
    }

    public async Task<object> CourseProducts(string courseId)
    {
        await TeachCourse(courseId);
        return await Q<Product>()
            .Where(p =>
                p.CourseId == courseId
                && p.IsActive
                && (Actor.Role == "admin" || p.CreatedBy == Actor.Id)
            )
            .OrderBy(p => p.Name)
            .Select(p => new
            {
                product = p,
                quantityAvailable = p.FulfillmentMode == "seller"
                    ? (p.IsAvailable ? 1 : 0)
                    : Q<InventorySku>()
                        .Where(s => s.ProductId == p.Id)
                        .Select(s => s.QuantityAvailable)
                        .FirstOrDefault(),
                quantityReserved = p.FulfillmentMode == "seller"
                    ? 0
                    : Q<InventorySku>()
                        .Where(s => s.ProductId == p.Id)
                        .Select(s => s.QuantityReserved)
                        .FirstOrDefault(),
            })
            .ToListAsync();
    }

    public async Task<Product> UpdateCourseProduct(
        string courseId,
        string productId,
        CourseProductUpdateRequest r
    )
    {
        await TeachCourse(courseId);
        var p = await marketplace.Listing(productId);
        Require(p.CourseId == courseId, "Product not found.", 404);
        // Legacy numeric stock is interpreted as binary availability; no warehouse record is changed.
        return await marketplace.Save(
            productId,
            new SellerListingRequest(
                r.Name,
                r.PriceVnd,
                r.Description,
                r.ImageAssetId,
                courseId,
                r.QuantityAvailable > 0,
                p.Revision
            )
        );
    }

    public async Task<bool> DeleteCourseProduct(string courseId, string productId)
    {
        await TeachCourse(courseId);
        var p = await marketplace.Listing(productId);
        Require(p.CourseId == courseId, "Product not found.", 404);
        return await marketplace.Delete(productId);
    }

    public async Task<object> Plans()
    {
        return await Q<SubscriptionPlan>()
            .Where(x => x.IsActive || Actor.Role == "admin")
            .OrderBy(x => x.PriceVnd)
            .ToListAsync();
    }

    public async Task<SubscriptionPlan> SavePlan(string? id, PlanRequest r)
    {
        Roles("admin");
        if (r.IncludesKit)
        {
            Require(r.KitInventorySkuId is not null, "Choose a kit SKU for kit-inclusive plans.");
            await Get<InventorySku>(r.KitInventorySkuId!);
        }

        var p = id is null ? new SubscriptionPlan() : await Get<SubscriptionPlan>(id);
        p.Name = r.Name;
        p.PriceVnd = r.PriceVnd;
        p.PriceMonthly = r.PriceVnd / r.DurationMonths;
        p.DurationMonths = r.DurationMonths;
        p.IncludesKit = r.IncludesKit;
        p.KitDeliveryIncluded = r.IncludesKit;
        p.Features = r.Features ?? [];
        p.IsActive = r.IsActive;
        p.KitInventorySkuId = r.IncludesKit ? r.KitInventorySkuId : null;
        p.KitQuantity = r.KitQuantity;
        if (id is null)
            Add(p);
        await Store.SaveAsync();
        return p;
    }

    private async Task<Cart> CartEntity()
    {
        Roles("parent");
        var cart = await Q<Cart>().SingleOrDefaultAsync(x => x.ParentId == Actor.Id);
        if (cart is not null)
            return cart;
        cart = new Cart { ParentId = Actor.Id };
        Add(cart);
        await Store.SaveAsync();
        return cart;
    }

    public async Task<object> Cart()
    {
        var c = await CartEntity();
        return new
        {
            c.Id,
            items = await (
                from i in Q<CartItem>()
                join p in Q<Product>() on i.ProductId equals p.Id
                where i.CartId == c.Id && p.IsActive && p.ApprovalStatus == "approved"
                select new
                {
                    i.Id,
                    i.ProductId,
                    i.Quantity,
                    product = p,
                }
            ).ToListAsync(),
        };
    }

    public Task<object> SetCartItem(CartItemRequest r)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var c = await CartEntity();
            var p = await Get<Product>(r.ProductId);
            if (r.Quantity > 0)
                Require(
                    p.IsActive
                        && p.ApprovalStatus == "approved"
                        && (p.FulfillmentMode != "seller" || p.IsAvailable),
                    "Product is unavailable."
                );
            var item = await Q<CartItem>()
                .SingleOrDefaultAsync(x => x.CartId == c.Id && x.ProductId == p.Id);
            if (r.Quantity == 0)
            {
                if (item is not null)
                    Remove(item);
            }
            else
            {
                if (item is null)
                {
                    item = new CartItem { CartId = c.Id, ProductId = p.Id };
                    Add(item);
                }

                item.Quantity = r.Quantity;
            }

            await Store.SaveAsync();
            return await Cart();
        });
    }

    public async Task<object> Vouchers()
    {
        return await Q<Voucher>()
            .Where(x => x.IsUsable && x.UsageLimit > 0 && x.ExpiryDate > DateTime.UtcNow)
            .OrderBy(x => x.Code)
            .ToListAsync();
    }

    public async Task<Voucher> SaveVoucher(string? id, VoucherRequest r)
    {
        Roles("admin");
        Require(
            r.DiscountType != "percentage" || r.DiscountValue <= 100,
            "Percentage cannot exceed 100."
        );
        Require(
            r.MaxDiscountAmount is null || r.MaxDiscountAmount >= 0,
            "Discount cap must be nonnegative."
        );
        Require(r.ExpiryDate.Kind == DateTimeKind.Utc, "ExpiryDate must be UTC (Z).");
        Require(
            !await Q<Voucher>().AnyAsync(x => x.Code == r.Code && x.Id != id),
            "Voucher code already exists.",
            409
        );
        var v = id is null ? new Voucher() : await Get<Voucher>(id);
        v.Code = r.Code;
        v.Title = r.Title;
        v.DiscountType = r.DiscountType;
        v.DiscountValue = r.DiscountValue;
        v.MinOrderAmount = r.MinOrderAmount;
        v.MaxDiscountAmount = r.MaxDiscountAmount;
        v.ExpiryDate = r.ExpiryDate;
        v.UsageLimit = r.UsageLimit;
        v.IsUsable = r.IsUsable;
        if (id is null)
            Add(v);
        await Store.SaveAsync();
        return v;
    }

    private async Task<(Voucher voucher, long discount)> Discount(string code, long subtotal)
    {
        code = code.Trim().ToUpperInvariant();
        var v =
            await Q<Voucher>().SingleOrDefaultAsync(x => x.Code == code)
            ?? throw new BusinessException(404, "Voucher not found.");
        Require(v.IsUsable && v.UsageLimit > 0, "Voucher unavailable.");
        Require(v.ExpiryDate > DateTime.UtcNow, "Voucher expired.");
        Require(subtotal >= v.MinOrderAmount, "Minimum order amount not met.");
        var value =
            v.DiscountType == "percentage"
                ? (long)Math.Round(subtotal * v.DiscountValue / 100m, MidpointRounding.AwayFromZero)
                : v.DiscountValue;
        if (v.MaxDiscountAmount is not null)
            value = Math.Min(value, v.MaxDiscountAmount.Value);
        return (v, Math.Min(subtotal, value));
    }

    public async Task<object> ValidateVoucher(VoucherValidateRequest r)
    {
        var (v, d) = await Discount(r.Code, r.SubtotalVnd);
        return new
        {
            isValid = true,
            voucher = v,
            discountAmountVnd = d,
        };
    }

    public Task<object> Checkout(CheckoutRequest r)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            Roles("parent");
            var old = await Q<Order>()
                .SingleOrDefaultAsync(x =>
                    x.ParentId == Actor.Id && x.IdempotencyKey == r.IdempotencyKey
                );
            if (old is not null)
                return await OrderDetail(old.Id);
            if (r.ChildId is not null)
                await OwnChild(r.ChildId);
            Require(
                r.Items.Select(x => x.ItemType + ":" + x.ItemId).Distinct().Count()
                    == r.Items.Count,
                "Duplicate checkout lines are not allowed."
            );
            var order = new Order
            {
                ParentId = Actor.Id,
                ChildId = r.ChildId,
                IdempotencyKey = r.IdempotencyKey,
                OrderCode = "AK-" + Guid.NewGuid().ToString("N")[..16].ToUpperInvariant(),
                PaymentMethodName = r.PaymentMethod,
                PaymentStatus = r.PaymentMethod == "cod" ? "cod" : "pending",
            };
            Add(order);
            var hasSeller = false;
            var hasLegacy = false;
            var physical = false;
            var includedDelivery = false;
            foreach (var line in r.Items)
            {
                var item = new OrderItem
                {
                    OrderId = order.Id,
                    ItemType = line.ItemType,
                    Quantity = line.Quantity,
                };
                switch (line.ItemType)
                {
                    case "kit":
                        var p = await Get<Product>(line.ItemId);
                        Require(
                            p.IsActive
                                && p.ApprovalStatus == "approved"
                                && (p.FulfillmentMode != "seller" || p.IsAvailable),
                            "Product is unavailable."
                        );
                        physical = true;
                        item.ProductId = p.Id;
                        item.Title = p.Name;
                        item.ThumbnailUrl = p.ThumbnailUrl;
                        item.UnitPriceVnd = p.PriceVnd;
                        item.KitItems = p.KitItems.ToList();
                        if (p.FulfillmentMode == "seller")
                        {
                            item.SellerId = p.CreatedBy;
                            hasSeller = true;
                        }
                        else
                        {
                            var sku =
                                await Q<InventorySku>()
                                    .SingleOrDefaultAsync(x => x.ProductId == p.Id)
                                ?? throw new BusinessException(
                                    409,
                                    "Product has no available inventory."
                                );
                            Require(
                                sku.QuantityAvailable >= line.Quantity,
                                "Insufficient stock.",
                                409
                            );
                            sku.QuantityAvailable -= line.Quantity;
                            sku.QuantityReserved += line.Quantity;
                            Add(
                                new InventoryReservation
                                {
                                    OrderItemId = item.Id,
                                    InventorySkuId = sku.Id,
                                    Quantity = line.Quantity,
                                    ExpiresAt = DateTime.UtcNow.AddMinutes(30),
                                }
                            );
                        }
                        break;
                    case "course":
                        Require(
                            r.ChildId is not null && line.Quantity == 1,
                            "Course checkout needs a child and quantity 1."
                        );
                        var c = await Get<Course>(line.ItemId);
                        Require(!c.IsDeleted && c.IsPublished, "Course is unavailable.");
                        Require(
                            !await Q<Enrollment>()
                                .AnyAsync(x =>
                                    x.ChildId == r.ChildId
                                    && x.CourseId == c.Id
                                    && x.OrderItemId != null
                                ),
                            "Child already owns this course.",
                            409
                        );
                        item.CourseId = c.Id;
                        item.Title = c.Title;
                        item.UnitPriceVnd = c.PriceVnd;
                        break;
                    case "subscription":
                        Require(line.Quantity == 1, "Subscription quantity must be 1.");
                        var plan = await Get<SubscriptionPlan>(line.ItemId);
                        Require(plan.IsActive, "Plan is unavailable.");
                        item.PlanId = plan.Id;
                        item.Title = plan.Name;
                        item.UnitPriceVnd = plan.PriceVnd;
                        item.DurationMonths = plan.DurationMonths;
                        order.OrderType = "subscription";
                        if (plan.IncludesKit)
                        {
                            Require(
                                plan.KitInventorySkuId is not null,
                                "Plan does not have a kit SKU.",
                                409
                            );
                            var kit = await Get<InventorySku>(plan.KitInventorySkuId!);
                            var quantity = checked(plan.KitQuantity * plan.DurationMonths);
                            Require(
                                kit.QuantityAvailable >= quantity,
                                "Insufficient stock to allocate the prepaid subscription kits.",
                                409
                            );
                            kit.QuantityAvailable -= quantity;
                            kit.QuantityReserved += quantity;
                            physical = true;
                            includedDelivery = true;
                            item.KitInventorySkuId = kit.Id;
                            item.KitQuantity = plan.KitQuantity;
                            Add(
                                new InventoryReservation
                                {
                                    OrderItemId = item.Id,
                                    InventorySkuId = kit.Id,
                                    Quantity = quantity,
                                    ExpiresAt = DateTime.UtcNow.AddMinutes(30),
                                }
                            );
                        }

                        break;
                    default:
                        throw new BusinessException(400, "Unknown item type.");
                }

                hasLegacy |= item.SellerId is null;
                order.SubtotalVnd = checked(order.SubtotalVnd + item.UnitPriceVnd * item.Quantity);
                Add(item);
            }

            if (physical)
            {
                Require(r.Shipping is not null, "Shipping information is required.");
                Add(
                    new OrderShippingInfo
                    {
                        OrderId = order.Id,
                        RecipientName = r.Shipping!.RecipientName,
                        PhoneNumber = r.Shipping.PhoneNumber,
                        FullAddress = r.Shipping.FullAddress,
                    }
                );
                order.ShippingFeeVnd = includedDelivery || order.SubtotalVnd >= 300000 ? 0 : 30000;
            }

            if (r.VoucherCode is not null)
            {
                var (v, d) = await Discount(r.VoucherCode, order.SubtotalVnd);
                order.VoucherId = v.Id;
                order.VoucherCode = v.Code;
                order.DiscountVnd = d;
                v.UsageLimit--;
            }

            Require(
                r.PaymentMethod != "cod" || r.Items.All(x => x.ItemType == "kit"),
                "COD is available only for one-time physical kit purchases. Digital courses/subscriptions require verified transfer."
            );
            if (hasSeller && !hasLegacy && r.PaymentMethod == "cod")
                order.Status = "preparing";
            order.TotalAmountVnd = order.SubtotalVnd + order.ShippingFeeVnd - order.DiscountVnd;
            Add(
                new OrderTrackingEvent
                {
                    OrderId = order.Id,
                    Title = "Đã đặt hàng",
                    Description = hasSeller
                        ? (
                            r.PaymentMethod == "cod"
                                ? "Đơn COD đã được tạo. Giảng viên có thể chuẩn bị học cụ; tiền COD chưa được xác minh đã thu."
                                : "Đơn đang chờ xác minh chuyển khoản. Vui lòng chờ hướng dẫn về tài khoản nhận tiền và quy trình xác minh; chưa thể giao hàng."
                        )
                        : "Awaiting admin confirmation; no payment gateway has been charged.",
                }
            );
            var cart = await Q<Cart>().SingleOrDefaultAsync(x => x.ParentId == Actor.Id);
            if (cart is not null)
                foreach (
                    var item in await Q<CartItem>().Where(x => x.CartId == cart.Id).ToListAsync()
                )
                    Remove(item);
            await Store.SaveAsync();
            if (hasSeller && r.PaymentMethod == "cod")
                foreach (
                    var sellerId in await Q<OrderItem>()
                        .Where(i => i.OrderId == order.Id && i.SellerId != null)
                        .Select(i => i.SellerId!)
                        .Distinct()
                        .ToListAsync()
                )
                    await SellerOrderTracking.Record(
                        Store,
                        order,
                        sellerId,
                        "preparing",
                        readyOnly: true
                    );
            return await OrderDetail(order.Id);
        });
    }

    private async Task<Order> OwnOrder(string id)
    {
        var o = await Get<Order>(id);
        Require(Actor.Role == "admin" || o.ParentId == Actor.Id, "Order not found.", 404);
        return o;
    }

    public async Task<object> Orders(int page, int size)
    {
        Roles("parent", "admin");
        var q = Q<Order>();
        if (Actor.Role != "admin")
            q = q.Where(x => x.ParentId == Actor.Id);
        var orders = await q.OrderByDescending(x => x.CreatedAt)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
        await SetOrderActions(orders);
        return orders;
    }

    private async Task SetOrderActions(List<Order> orders)
    {
        var ids = orders.Select(o => o.Id).ToList();
        var lines = await Q<OrderItem>()
            .Where(i => ids.Contains(i.OrderId))
            .Select(i => new { i.OrderId, i.SellerId })
            .ToListAsync();
        var dispatched = await Q<SellerFulfillment>()
            .Where(s =>
                ids.Contains(s.OrderId)
                && (s.ShippedAt != null || s.Status == "shipping" || s.Status == "delivered")
            )
            .Select(s => s.OrderId)
            .Distinct()
            .ToListAsync();
        foreach (var o in orders)
        {
            var ownLines = lines.Where(i => i.OrderId == o.Id).ToList();
            o.HasMarketplaceItems = ownLines.Any(i => i.SellerId != null);
            var hasLegacy = ownLines.Any(i => i.SellerId == null);
            o.AwaitingMarketplacePayment =
                o.HasMarketplaceItems
                && o.PaymentMethodName != "cod"
                && o.PaymentStatus != "paid"
                && o.Status != "cancelled";
            o.RequiresLegacyConfirmation =
                hasLegacy && o.Status == "pending_confirmation" && !o.AwaitingMarketplacePayment;
            o.CanCancel =
                (
                    o.Status == "pending_confirmation"
                    || (
                        o.HasMarketplaceItems
                        && !hasLegacy
                        && o.PaymentMethodName == "cod"
                        && o.Status == "preparing"
                    )
                )
                && !dispatched.Contains(o.Id)
                && (!o.HasMarketplaceItems || o.PaymentStatus != "paid");
        }
    }

    public async Task<object> OrderDetail(string id)
    {
        var order = await OwnOrder(id);
        await SetOrderActions([order]);
        var items = await Q<OrderItem>().Where(x => x.OrderId == id).ToListAsync();
        var sellerIds = items
            .Where(i => i.SellerId != null)
            .Select(i => i.SellerId!)
            .Distinct()
            .ToList();
        var sellers = await Q<User>()
            .Where(u => sellerIds.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.FullName);
        var fulfillments = await Q<SellerFulfillment>().Where(s => s.OrderId == id).ToListAsync();
        var trackingEvents = await Q<OrderTrackingEvent>()
            .Where(e => e.OrderId == id)
            .OrderBy(e => e.Timestamp)
            .ThenBy(e => e.CreatedAt)
            .ThenBy(e => e.Id)
            .ToListAsync();
        return new
        {
            order,
            items,
            shippingInfo = await Q<OrderShippingInfo>().SingleOrDefaultAsync(x => x.OrderId == id),
            trackingEvents = order.HasMarketplaceItems
                ? SellerOrderTracking.ForParent(trackingEvents)
                : trackingEvents,
            sellerFulfillments = fulfillments,
            sellerProgress = sellerIds
                .Select(sellerId =>
                {
                    var fulfillment = fulfillments.SingleOrDefault(f => f.SellerId == sellerId);
                    return new
                    {
                        sellerId,
                        sellerName = sellers[sellerId],
                        itemTitles = items
                            .Where(i => i.SellerId == sellerId)
                            .Select(i => i.Title)
                            .ToList(),
                        status = OrderFulfillment.SellerStatus(order, fulfillment?.Status),
                        carrier = string.IsNullOrWhiteSpace(fulfillment?.Carrier)
                            ? null
                            : fulfillment.Carrier,
                        trackingNumber = fulfillment?.TrackingNumber,
                        shippedAt = fulfillment?.ShippedAt,
                        deliveredAt = fulfillment?.DeliveredAt,
                    };
                })
                .ToList(),
            shipments = await Q<FulfillmentOrder>().Where(x => x.OrderId == id).ToListAsync(),
        };
    }

    public Task<object> Cancel(string id, string reason)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var o = await OwnOrder(id);
            if (o.Status == "cancelled")
                return await OrderDetail(id);
            await SetOrderActions([o]);
            Require(
                o.CanCancel,
                "This order cannot be cancelled after dispatch, payment or legacy confirmation.",
                409
            );
            await Release(o, reason);
            await Store.SaveAsync();
            return await OrderDetail(id);
        });
    }

    public async Task Release(Order o, string reason)
    {
        var itemIds = Q<OrderItem>().Where(x => x.OrderId == o.Id).Select(x => x.Id);
        foreach (
            var r in await Q<InventoryReservation>()
                .Where(x => itemIds.Contains(x.OrderItemId) && x.Status == "reserved")
                .ToListAsync()
        )
        {
            var sku = await Get<InventorySku>(r.InventorySkuId);
            sku.QuantityAvailable += r.Quantity;
            sku.QuantityReserved -= r.Quantity;
            r.Status = "released";
        }

        if (o.VoucherId is not null)
            (await Get<Voucher>(o.VoucherId)).UsageLimit++;
        o.Status = "cancelled";
        o.CancelReason = reason;
        Add(
            new OrderTrackingEvent
            {
                OrderId = o.Id,
                Title = "Đã hủy",
                Description = reason,
                CancelReason = reason,
            }
        );
    }

    public Task<object> Confirm(string id)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            Roles("admin");
            var o = await Get<Order>(id);
            var items = await Q<OrderItem>().Where(x => x.OrderId == id).ToListAsync();
            var hasSeller = items.Any(i => i.SellerId != null);
            Require(
                !hasSeller || o.PaymentMethodName == "cod" || o.PaymentStatus == "paid",
                "Marketplace transfer verification policy is not configured. Do not confirm unverified funds.",
                409
            );
            if (hasSeller && items.All(i => i.SellerId != null) && o.PaymentMethodName == "cod")
            {
                Require(o.Status != "cancelled", "Order cannot be confirmed.", 409);
                // Backward-compatible no-op; seller-only COD never requires this endpoint.
                if (o.Status == "pending_confirmation")
                    o.Status = "preparing";
                return await OrderDetail(id);
            }
            if (o.Status is "preparing" or "shipping" or "delivered")
                return await OrderDetail(id);
            Require(o.Status == "pending_confirmation", "Order cannot be confirmed.", 409);
            var sellerDispatched = await OrderFulfillment.SellerDispatched(Store, id);
            var itemIds = items.Select(x => x.Id).ToList();
            var reservations = await Q<InventoryReservation>()
                .Where(x => itemIds.Contains(x.OrderItemId))
                .ToListAsync();
            Require(
                reservations.All(x =>
                    x.Status == "reserved" && (x.ExpiresAt > DateTime.UtcNow || sellerDispatched)
                ),
                "Stock reservation expired; cancel this order and checkout again.",
                409
            );
            foreach (var r in reservations)
            {
                (await Get<InventorySku>(r.InventorySkuId)).QuantityReserved -= r.Quantity;
                r.Status = "committed";
            }

            foreach (var i in items)
            {
                if (i.ProductId is not null && i.SellerId is null)
                    (await Get<Product>(i.ProductId)).SoldCount += i.Quantity;
                if (i.CourseId is not null)
                {
                    var enrollment = await Q<Enrollment>()
                        .SingleOrDefaultAsync(x =>
                            x.ChildId == o.ChildId && x.CourseId == i.CourseId
                        );
                    Require(
                        enrollment?.OrderItemId is null,
                        "Child already owns this course. Cancel this duplicate pending order.",
                        409
                    );
                    if (enrollment is null)
                        Add(
                            new Enrollment
                            {
                                ChildId = o.ChildId!,
                                CourseId = i.CourseId,
                                OrderItemId = i.Id,
                            }
                        );
                    else
                        enrollment.OrderItemId = i.Id;
                }

                if (i.PlanId is not null)
                {
                    var p = await Get<SubscriptionPlan>(i.PlanId);
                    var now = DateTime.UtcNow;
                    var active = await Q<Subscription>()
                        .Where(x =>
                            x.ParentId == o.ParentId
                            && x.PlanId == p.Id
                            && x.ChildId == o.ChildId
                            && x.Status == "active"
                            && x.EndsAt > now
                        )
                        .OrderByDescending(x => x.EndsAt)
                        .FirstOrDefaultAsync();
                    var start = active?.EndsAt ?? now;
                    var duration = i.DurationMonths ?? p.DurationMonths;
                    var subscription = new Subscription
                    {
                        ParentId = o.ParentId,
                        ChildId = o.ChildId,
                        PlanId = p.Id,
                        OrderItemId = i.Id,
                        StartsAt = start,
                        EndsAt = start.AddMonths(duration),
                    };
                    Add(subscription);
                    if (i.KitInventorySkuId is not null)
                        for (var index = 0; index < duration; index++)
                            Add(
                                new SubscriptionKitDelivery
                                {
                                    SubscriptionId = subscription.Id,
                                    InventorySkuId = i.KitInventorySkuId,
                                    DeliveryIndex = index + 1,
                                    ScheduledFor = start.AddMonths(index),
                                    Quantity = i.KitQuantity,
                                }
                            );
                }
            }

            if (o.PaymentMethodName != "cod" && o.PaymentStatus != "paid")
            {
                o.PaymentStatus = "paid";
                o.PaidAt = DateTime.UtcNow;
            }

            o.Status =
                reservations.Count > 0 || items.Any(i => i.SellerId != null)
                    ? "preparing"
                    : "delivered";
            Add(
                new OrderTrackingEvent
                {
                    OrderId = id,
                    Title = "Đã xác nhận",
                    Description = hasSeller
                        ? "Phần hàng do ART_KID xử lý đã được xác nhận."
                        : "Confirmed by administrator.",
                }
            );
            Notify(o.ParentId, "Đơn hàng đã xác nhận", o.OrderCode, id);
            await Store.SaveAsync();
            if (hasSeller)
                await OrderFulfillment.UpdateCompletion(Store, o);
            return await OrderDetail(id);
        });
    }

    public async Task<object> Subscriptions()
    {
        return await Q<Subscription>()
            .Where(x => x.ParentId == Actor.Id)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<object> KitDeliveries(string id)
    {
        var subscription = await Get<Subscription>(id);
        Require(
            Actor.Role == "admin" || subscription.ParentId == Actor.Id,
            "Subscription not found.",
            404
        );
        return await Q<SubscriptionKitDelivery>()
            .Where(x => x.SubscriptionId == id)
            .OrderBy(x => x.DeliveryIndex)
            .Select(x => new
            {
                delivery = x,
                shipment = Q<FulfillmentOrder>()
                    .FirstOrDefault(s => s.SubscriptionKitDeliveryId == x.Id),
            })
            .ToListAsync();
    }

    public async Task ExpireReservations()
    {
        var expiredItemIds = Q<InventoryReservation>()
            .Where(x => x.Status == "reserved" && x.ExpiresAt < DateTime.UtcNow)
            .Select(x => x.OrderItemId);
        var orderIds = await Q<OrderItem>()
            .Where(x => expiredItemIds.Contains(x.Id))
            .Select(x => x.OrderId)
            .Distinct()
            .ToListAsync();
        foreach (var id in orderIds)
            await Store.TransactionAsync(async () =>
            {
                var o = await Get<Order>(id);
                if (
                    o.Status == "pending_confirmation"
                    && !await OrderFulfillment.SellerDispatched(Store, id)
                )
                    await Release(o, "Stock reservation expired.");
                return true;
            });
    }
}
