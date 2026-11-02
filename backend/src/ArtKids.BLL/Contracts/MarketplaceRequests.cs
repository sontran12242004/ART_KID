using System.ComponentModel.DataAnnotations;

namespace ArtKids.BLL.Contracts;

public sealed record SellerListingRequest(
    [Required, MaxLength(200)] string Name,
    [Range(1, 100000000)] long PriceVnd,
    [Required, MaxLength(10000)] string Description,
    [MaxLength(64)] string? ImageAssetId = null,
    [MaxLength(64)] string? CourseId = null,
    bool IsAvailable = true,
    [Range(1, int.MaxValue)] int? ExpectedRevision = null
);

public sealed record ListingReviewRequest(
    [Required, RegularExpression("^(approved|rejected)$")] string Status,
    [Range(1, int.MaxValue)] int ExpectedRevision,
    [MaxLength(1000)] string? Reason = null
);

public sealed record ListingAvailabilityRequest(
    bool IsAvailable,
    [Range(1, int.MaxValue)] int ExpectedRevision
);

public sealed record SellerFulfillmentRequest(
    [Required, RegularExpression("^(GHN|VNPost|GHTK)$")] string Carrier,
    [Required, RegularExpression("^(preparing|shipping|delivered)$")] string Status,
    [MaxLength(100)] string? TrackingNumber = null
);
