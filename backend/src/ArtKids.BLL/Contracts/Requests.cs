using System.ComponentModel.DataAnnotations;

namespace ArtKids.BLL.Contracts;

public sealed record RegisterRequest(
    [Required, EmailAddress, MaxLength(254)] string Email,
    [Required, MinLength(10), MaxLength(128)] string Password,
    [Required, MaxLength(150)] string FullName
);

public sealed record LoginRequest(
    [Required, EmailAddress] string Email,
    [Required] string Password
);

public sealed record RefreshRequest([Required] string RefreshToken);

public sealed record PinRequest([Required, RegularExpression("^[0-9]{4,6}$")] string Pin);

public sealed record SetPinRequest(
    [Required] string Password,
    [Required, RegularExpression("^[0-9]{4,6}$")] string Pin
);

public sealed record UserProfileRequest(
    [Required, MaxLength(150)] string FullName,
    [MaxLength(20)] string? PhoneNumber,
    string? AvatarPresetId,
    bool NotificationsEnabled = true,
    bool DailyDrawingReminder = true
);

public sealed record ChildRequest(
    [Required, MaxLength(100)] string Nickname,
    [Range(2000, 2100)] int BirthYear,
    string? AvatarPresetId = null,
    [MaxLength(1000)] string? Interests = null
);

public sealed record ConsentRequest(
    [Required] string ChildId,
    [Required, RegularExpression("^(data_processing|ai_generation)$")] string Purpose,
    [Required, MaxLength(30)] string PolicyVersion
);

public sealed record StaffRequest(
    [Required, EmailAddress] string Email,
    [Required, MinLength(10)] string Password,
    [Required] string FullName,
    [Required, RegularExpression("^(instructor|admin)$")] string Role
);

public sealed record CourseRequest(
    [Required, MaxLength(200)] string Title,
    [Required, MaxLength(10000)] string Description,
    [Required] string AgeRange,
    [Range(0, 100000000)] long PriceVnd,
    string? InstructorId = null,
    string? ThumbnailUrl = null,
    bool IncludesPhysicalKit = false,
    bool IsPublished = false
);

public sealed record LessonRequest(
    [Required, MaxLength(200)] string Title,
    [Range(0, 1000)] int OrderIndex,
    string? VideoAssetId = null,
    string? VideoUrl = null,
    [MaxLength(10000)] string? PracticeInstructions = null
);

public sealed record EnrollmentRequest([Required] string ChildId, [Required] string CourseId);

public sealed record VideoUploadRequest(
    [Required, MaxLength(255)] string FileName,
    [Range(1, 300000000)] long SizeBytes,
    [MaxLength(64)] string? LessonId = null
);

public sealed record VideoCompleteRequest(
    [Required, MaxLength(10000)] string UploadToken,
    [Required, MaxLength(200)] string Title,
    [Range(0, 1000)] int OrderIndex,
    [MaxLength(10000)] string? PracticeInstructions = null
);

public sealed record ProgressRequest(
    [Required] string ChildId,
    [Required] string LessonId,
    [Required, RegularExpression("^(in_progress|completed)$")] string Status,
    [Range(0, 3600)] int LearningSeconds = 0
);

public sealed record SubmissionRequest(
    [Required] string ChildId,
    [Required] string ImageAssetId,
    string? LessonId = null,
    string? LiveSessionId = null
);

public sealed record ReviewRequest(
    [Range(0, 10)] decimal Score,
    [Required, MaxLength(10000)] string Feedback
);

public sealed record LiveClassRequest(
    [Required] string CourseId,
    [Required, MaxLength(150)] string Name,
    [Range(1, 30)] int Capacity = 30,
    string? InstructorId = null
);

public sealed record LiveClassUpdateRequest(
    [Required, MaxLength(150)] string Name,
    [Range(1, 30)] int Capacity,
    [Required, RegularExpression("^(open|active|completed|cancelled)$")] string Status
);

public sealed record ClassEnrollmentRequest([Required] string ChildId);

public sealed record LiveSessionRequest(
    [Required, MaxLength(200)] string Title,
    DateTime StartsAt,
    DateTime EndsAt,
    string? LessonId = null,
    string? RoomUrl = null,
    [MaxLength(40)] string Provider = "external"
);

public sealed record SessionStateRequest(
    [Required, RegularExpression("^(live|completed|cancelled)$")] string Status,
    string? RecordingUrl = null
);

public sealed record CourseProductRequest(
    [Required, MaxLength(200)] string Name,
    [Range(1, 100000000)] long PriceVnd,
    [Required, MaxLength(10000)] string Description,
    [Required] string ImageAssetId,
    [Range(1, 1000000)] int QuantityAvailable
);

public sealed record CourseProductUpdateRequest(
    [Required, MaxLength(200)] string Name,
    [Range(1, 100000000)] long PriceVnd,
    [Required, MaxLength(10000)] string Description,
    [Range(0, 1000000)] int QuantityAvailable,
    string? ImageAssetId = null,
    [Range(0, 1000000)] int? ExpectedQuantityAvailable = null
);

public sealed record ProductRequest(
    [Required, MaxLength(200)] string Name,
    [Range(0, 100000000)] long PriceVnd,
    [Required, MaxLength(10000)] string Description,
    [Required, RegularExpression("^(course_kit|individual_tool|combo_saver)$")] string Category,
    string ThumbnailUrl = "",
    long? OriginalPriceVnd = null,
    string? CourseId = null,
    string? RecommendedSubscriptionPlanId = null,
    List<string>? Images = null,
    List<string>? KitItems = null,
    bool IsActive = true
);

public sealed record PlanRequest(
    [Required] string Name,
    [Range(0, 100000000)] long PriceVnd,
    [Range(1, 36)] int DurationMonths,
    bool IncludesKit = false,
    List<string>? Features = null,
    bool IsActive = true,
    string? KitInventorySkuId = null,
    [Range(1, 10)] int KitQuantity = 1
);

public sealed record CartItemRequest([Required] string ProductId, [Range(0, 99)] int Quantity);

public sealed record VoucherRequest(
    [Required, RegularExpression("^[A-Z0-9_-]{3,40}$")] string Code,
    [Required] string Title,
    [Required, RegularExpression("^(percentage|fixedAmount)$")] string DiscountType,
    [Range(0, 100000000)] long DiscountValue,
    [Range(0, 100000000)] long MinOrderAmount,
    long? MaxDiscountAmount,
    DateTime ExpiryDate,
    [Range(0, 1000000)] int UsageLimit,
    bool IsUsable = true
);

public sealed record VoucherValidateRequest(
    [Required] string Code,
    [Range(0, 1000000000)] long SubtotalVnd
);

public sealed record CheckoutItem(
    [Required, RegularExpression("^(kit|course|subscription)$")] string ItemType,
    [Required] string ItemId,
    [Range(1, 99)] int Quantity = 1
);

public sealed record ShippingRequest(
    [Required, MaxLength(150)] string RecipientName,
    [Required, MaxLength(20)] string PhoneNumber,
    [Required, MaxLength(500)] string FullAddress
);

public sealed record CheckoutRequest(
    [Required, MinLength(8), MaxLength(100)] string IdempotencyKey,
    [Required, MinLength(1), MaxLength(50)] List<CheckoutItem> Items,
    string? ChildId = null,
    string? VoucherCode = null,
    ShippingRequest? Shipping = null,
    [RegularExpression("^(manual_transfer|cod)$")] string PaymentMethod = "manual_transfer"
);

public sealed record CancelRequest([Required, MaxLength(1000)] string Reason);

public sealed record InventoryRequest(
    [Required] string ProductId,
    [Required, MaxLength(64)] string Sku,
    [Range(0, 1000000)] int QuantityAvailable,
    [Range(0, 1000000)] int ReorderThreshold,
    [Range(0, 100000000)] long UnitCostVnd,
    string WarehouseLocation = "Main warehouse"
);

public sealed record StockAdjustmentRequest(
    [Range(-1000000, 1000000)] int Delta,
    [Required, MaxLength(300)] string Reason
);

public sealed record ShipmentRequest(
    [Required] string OrderId,
    [Required] string InventorySkuId,
    [Required, RegularExpression("^(VNPost|GHN|GHTK)$")] string Carrier,
    [Required, MaxLength(100)] string TrackingNumber,
    DateTime? EstimatedDeliveryDate = null,
    string? SubscriptionKitDeliveryId = null
);

public sealed record ShipmentStatusRequest(
    [Required, RegularExpression("^(shipping|delivered|returned)$")] string Status
);

public sealed record GameProgressRequest(
    [Required, RegularExpression("^(drawing|matching)$")] string CurrentStep,
    [Range(0, 100)] int CurrentAnimalIndex,
    List<string> UnlockedStickers,
    List<string> MatchedAnimals
);

public sealed record PictureSetRequest(
    [Required] string Title,
    string Description,
    string ThumbnailAsset,
    string BackgroundAsset,
    double BgAspectRatio,
    List<SlotRequest> Slots
);

public sealed record SlotRequest(
    [Required] string Animal,
    int SequenceIndex,
    [Range(0, 1)] double LeftPercent,
    [Range(0, 1)] double TopPercent,
    [Range(0, 1)] double WidthPercent,
    [Range(0, 1)] double HeightPercent
);
