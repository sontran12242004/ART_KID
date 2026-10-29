using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class MarketplaceService(IUnitOfWork store, ICurrentUser actor)
    : ServiceBase(store, actor)
{
    private async Task<Product> OwnListing(string id)
    {
        Roles("instructor");
        var p = await Get<Product>(id);
        Require(
            p.FulfillmentMode == "seller" && p.CreatedBy == Actor.Id && p.IsActive,
            "Listing not found.",
            404
        );
        return p;
    }

    private static void Pending(Product p)
    {
        p.ApprovalStatus = "pending";
        p.RejectionReason = null;
        p.ReviewedBy = null;
        p.ReviewedAt = null;
        p.Revision++;
    }

    public async Task<object> Listings(int page, int size, string? courseId = null)
    {
        Roles("instructor");
        var q = Q<Product>()
            .Where(p => p.FulfillmentMode == "seller" && p.CreatedBy == Actor.Id && p.IsActive);
        if (courseId is not null)
            q = q.Where(p => p.CourseId == courseId);
        return new
        {
            total = await q.CountAsync(),
            page = Page(page),
            pageSize = Size(size),
            items = await q.OrderByDescending(p => p.CreatedAt)
                .ThenBy(p => p.Id)
                .Skip((Page(page) - 1) * Size(size))
                .Take(Size(size))
                .ToListAsync(),
        };
    }

    public Task<Product> Listing(string id) => OwnListing(id);

    public Task<Product> Save(string? id, SellerListingRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            Roles("instructor");
            var p = id is null
                ? new Product
                {
                    CreatedBy = Actor.Id,
                    FulfillmentMode = "seller",
                    Revision = 0,
                }
                : await OwnListing(id);
            if (id is not null)
                Require(
                    r.ExpectedRevision is not null && r.ExpectedRevision == p.Revision,
                    "Listing has changed. Reload before editing.",
                    409
                );
            Require(
                !string.IsNullOrWhiteSpace(r.Name) && !string.IsNullOrWhiteSpace(r.Description),
                "Name and description are required."
            );
            if (r.CourseId is not null)
                await TeachCourse(r.CourseId);
            if (r.ImageAssetId is not null)
            {
                var image = await Get<MediaAsset>(r.ImageAssetId);
                Require(
                    image.Kind == "product_image" && image.OwnerId == Actor.Id,
                    "Choose a product image uploaded by your account.",
                    403
                );
                var url = $"/api/v1/media/products/{image.Id}";
                Require(
                    !await Q<Product>().AnyAsync(x => x.Id != p.Id && x.ThumbnailUrl == url),
                    "This image is already used by another product.",
                    409
                );
                p.ThumbnailUrl = url;
                p.Images = [url];
            }
            Require(p.ThumbnailUrl.Length > 0, "A product image is required.");
            p.Name = r.Name.Trim();
            p.Description = r.Description.Trim();
            p.PriceVnd = r.PriceVnd;
            p.CourseId = r.CourseId;
            p.Category = r.CourseId is null ? "individual_tool" : "course_kit";
            p.IsAvailable = r.IsAvailable;
            Pending(p);
            if (id is null)
                Add(p);
            return p;
        });
    }

    public Task<Product> Availability(string id, ListingAvailabilityRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var p = await OwnListing(id);
            Require(
                p.Revision == r.ExpectedRevision,
                "Listing has changed. Reload before editing.",
                409
            );
            p.IsAvailable = r.IsAvailable;
            Pending(p);
            return p;
        });
    }

    public Task<bool> Delete(string id)
    {
        return Store.TransactionAsync(async () =>
        {
            var p = await OwnListing(id);
            p.IsActive = false;
            p.Revision++;
            return true;
        });
    }

    public async Task<object> Reviews(int page, int size)
    {
        Roles("admin");
        var q = Q<Product>()
            .Where(p =>
                p.FulfillmentMode == "seller" && p.IsActive && p.ApprovalStatus == "pending"
            );
        return new
        {
            total = await q.CountAsync(),
            page = Page(page),
            pageSize = Size(size),
            items = await q.OrderBy(p => p.CreatedAt)
                .ThenBy(p => p.Id)
                .Skip((Page(page) - 1) * Size(size))
                .Take(Size(size))
                .ToListAsync(),
        };
    }

    public async Task<Product> ReviewDetail(string id)
    {
        Roles("admin");
        var p = await Get<Product>(id);
        Require(p.FulfillmentMode == "seller" && p.IsActive, "Listing not found.", 404);
        return p;
    }

    public Task<Product> Review(string id, ListingReviewRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var p = await ReviewDetail(id);
            Require(
                p.ApprovalStatus == "pending" && p.Revision == r.ExpectedRevision,
                "Listing has changed or was already reviewed. Reload before reviewing.",
                409
            );
            Require(r.Status is "approved" or "rejected", "Invalid review status.");
            Require(
                r.Status != "rejected" || !string.IsNullOrWhiteSpace(r.Reason),
                "A rejection reason is required."
            );
            if (r.Status == "approved" && p.CourseId is not null)
            {
                var course = await Get<Course>(p.CourseId);
                Require(
                    !course.IsDeleted && course.InstructorId == p.CreatedBy,
                    "The linked course is no longer available to this seller.",
                    409
                );
            }
            p.ApprovalStatus = r.Status;
            p.RejectionReason = r.Status == "rejected" ? r.Reason!.Trim() : null;
            p.ReviewedBy = Actor.Id;
            p.ReviewedAt = DateTime.UtcNow;
            p.Revision++;
            Notify(
                p.CreatedBy,
                "Kết quả duyệt học cụ",
                r.Status == "approved" ? "Học cụ đã được duyệt." : p.RejectionReason!,
                p.Id
            );
            return p;
        });
    }

    public async Task<object> Orders(int page, int size)
    {
        Roles("instructor");
        var ids = Q<OrderItem>().Where(i => i.SellerId == Actor.Id).Select(i => i.OrderId);
        var q = Q<Order>().Where(o => ids.Contains(o.Id));
        var rows = await q.OrderByDescending(o => o.CreatedAt)
            .ThenBy(o => o.Id)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .Select(o => new
            {
                order = o,
                fulfillmentStatus = Q<SellerFulfillment>()
                    .Where(s => s.OrderId == o.Id && s.SellerId == Actor.Id)
                    .Select(s => s.Status)
                    .FirstOrDefault(),
                subtotalVnd = Q<OrderItem>()
                    .Where(i => i.OrderId == o.Id && i.SellerId == Actor.Id)
                    .Sum(i => i.UnitPriceVnd * i.Quantity),
            })
            .ToListAsync();
        return new
        {
            total = await q.CountAsync(),
            page = Page(page),
            pageSize = Size(size),
            items = rows.Select(row => new
            {
                row.order.Id,
                row.order.OrderCode,
                row.order.Status,
                row.order.CreatedAt,
                row.subtotalVnd,
                canFulfill = OrderFulfillment.CanSellerFulfill(row.order),
                collectionUnverified = row.order.PaymentMethodName == "cod"
                    && row.order.PaymentStatus != "paid",
                awaitingPayment = row.order.Status != "cancelled"
                    && !OrderFulfillment.CanSellerFulfill(row.order),
                sellerStatus = OrderFulfillment.SellerStatus(row.order, row.fulfillmentStatus),
            }),
        };
    }

    private async Task<Order> OwnSellerOrder(string id)
    {
        Roles("instructor");
        Require(
            await Q<OrderItem>().AnyAsync(i => i.OrderId == id && i.SellerId == Actor.Id),
            "Order not found.",
            404
        );
        return await Get<Order>(id);
    }

    public async Task<object> OrderDetail(string id)
    {
        var o = await OwnSellerOrder(id);
        var items = await Q<OrderItem>()
            .Where(i => i.OrderId == id && i.SellerId == Actor.Id)
            .Select(i => new
            {
                i.Id,
                i.ProductId,
                i.Title,
                i.Quantity,
                i.UnitPriceVnd,
                i.ThumbnailUrl,
            })
            .ToListAsync();
        var fulfillment = await Q<SellerFulfillment>()
            .SingleOrDefaultAsync(s => s.OrderId == id && s.SellerId == Actor.Id);
        return new
        {
            o.Id,
            o.OrderCode,
            o.Status,
            o.CreatedAt,
            canFulfill = OrderFulfillment.CanSellerFulfill(o),
            collectionUnverified = o.PaymentMethodName == "cod" && o.PaymentStatus != "paid",
            awaitingPayment = o.Status != "cancelled" && !OrderFulfillment.CanSellerFulfill(o),
            sellerStatus = OrderFulfillment.SellerStatus(o, fulfillment?.Status),
            items,
            subtotalVnd = items.Sum(i => i.UnitPriceVnd * i.Quantity),
            shippingInfo = await Q<OrderShippingInfo>()
                .Where(s => s.OrderId == id)
                .Select(s => new
                {
                    s.RecipientName,
                    s.PhoneNumber,
                    s.FullAddress,
                })
                .SingleOrDefaultAsync(),
            fulfillment,
        };
    }

    public Task<SellerFulfillment> Fulfill(string id, SellerFulfillmentRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var o = await OwnSellerOrder(id);
            Require(
                OrderFulfillment.CanSellerFulfill(o),
                "Order is cancelled or awaiting verified payment.",
                409
            );
            var itemIds = Q<OrderItem>().Where(i => i.OrderId == id).Select(i => i.Id);
            Require(
                await OrderFulfillment.SellerDispatched(Store, id)
                    || !await Q<InventoryReservation>()
                        .AnyAsync(r =>
                            itemIds.Contains(r.OrderItemId)
                            && r.Status == "reserved"
                            && r.ExpiresAt <= DateTime.UtcNow
                        ),
                "Platform stock reservation expired. Reload the order before dispatch.",
                409
            );
            var s = await Q<SellerFulfillment>()
                .SingleOrDefaultAsync(s => s.OrderId == id && s.SellerId == Actor.Id);
            if (s is null)
            {
                s = new SellerFulfillment { OrderId = id, SellerId = Actor.Id };
                Add(s);
            }
            Require(r.Carrier is "GHN" or "VNPost" or "GHTK", "Choose a supported carrier.");
            Require(
                (s.Status == "preparing" && r.Status is "preparing" or "shipping")
                    || (s.Status == "shipping" && r.Status == "delivered")
                    || (
                        s.Status == r.Status
                        && s.Carrier == r.Carrier
                        && s.TrackingNumber == r.TrackingNumber
                    ),
                "Invalid seller shipping transition.",
                409
            );
            Require(
                s.Status == "preparing"
                    || (s.Carrier == r.Carrier && s.TrackingNumber == r.TrackingNumber),
                "Carrier and tracking cannot change after dispatch.",
                409
            );
            var firstDelivery = s.Status != "delivered" && r.Status == "delivered";
            s.Carrier = r.Carrier;
            s.TrackingNumber = string.IsNullOrWhiteSpace(r.TrackingNumber)
                ? null
                : r.TrackingNumber.Trim();
            s.Status = r.Status;
            if (r.Status == "shipping")
                s.ShippedAt ??= DateTime.UtcNow;
            if (r.Status == "delivered")
                s.DeliveredAt ??= DateTime.UtcNow;
            if (firstDelivery)
                foreach (
                    var i in await Q<OrderItem>()
                        .Where(i => i.OrderId == id && i.SellerId == Actor.Id)
                        .ToListAsync()
                )
                    (await Get<Product>(i.ProductId!)).SoldCount += i.Quantity;
            await Store.SaveAsync();
            await OrderFulfillment.UpdateCompletion(Store, o);
            return s;
        });
    }
}
