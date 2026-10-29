using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace ArtKids.DAL.Entities;

public abstract class Entity
{
    [MaxLength(64)]
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class User : Entity
{
    public string Email { get; set; } = "";
    public string FullName { get; set; } = "";
    public string? PhoneNumber { get; set; }
    public string? AvatarUrl { get; set; }
    public string? AvatarPresetId { get; set; }
    public string Role { get; set; } = "parent";

    [JsonIgnore]
    public string PasswordHash { get; set; } = "";

    [JsonIgnore]
    public string? ParentPinHash { get; set; }
    public bool HasCompletedCoppaConsent { get; set; }
    public DateTime? ParentalConsentAt { get; set; }
    public bool NotificationsEnabled { get; set; } = true;
    public bool DailyDrawingReminder { get; set; } = true;
    public bool IsActive { get; set; } = true;
}

public sealed class RefreshToken : Entity
{
    public string UserId { get; set; } = "";

    [JsonIgnore]
    public string TokenHash { get; set; } = "";
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}

public sealed class ChildProfile : Entity
{
    public string ParentId { get; set; } = "";
    public string Nickname { get; set; } = "";
    public int BirthYear { get; set; }
    public string? AvatarUrl { get; set; }
    public string? AvatarPresetId { get; set; }
    public string? Interests { get; set; }

    [JsonIgnore]
    public string? KidPinHash { get; set; }
    public int TotalPoints { get; set; }
}

public sealed class AvatarPreset : Entity
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public bool IsForChild { get; set; }
    public string Type { get; set; } = "asset";
    public string? AssetPath { get; set; }
    public string? IconName { get; set; }
    public string PrimaryColor { get; set; } = "#FF1982C4";
    public string SecondaryColor { get; set; } = "#FFFFFFFF";
}

public sealed class ParentalConsent : Entity
{
    public string ParentId { get; set; } = "";
    public string ChildId { get; set; } = "";
    public string Purpose { get; set; } = "data_processing";
    public string PolicyVersion { get; set; } = "1";
    public DateTime GrantedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RevokedAt { get; set; }
}

public sealed class Course : Entity
{
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public string? ThumbnailUrl { get; set; }
    public string AgeRange { get; set; } = "4–12 tuổi";
    public long PriceVnd { get; set; }
    public bool IncludesPhysicalKit { get; set; }
    public string InstructorId { get; set; } = "";
    public bool IsPublished { get; set; }
    public bool IsDeleted { get; set; }
}

public sealed class Lesson : Entity
{
    public string CourseId { get; set; } = "";
    public string Title { get; set; } = "";
    public int OrderIndex { get; set; }
    public string? VideoUrl { get; set; }
    public string? VideoAssetId { get; set; }
    public string? PracticeInstructions { get; set; }
}

public sealed class Enrollment : Entity
{
    public string ChildId { get; set; } = "";
    public string CourseId { get; set; } = "";
    public string? OrderItemId { get; set; }
    public DateTime EnrolledAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLearnedAt { get; set; }
}

public sealed class LessonProgress : Entity
{
    public string EnrollmentId { get; set; } = "";
    public string LessonId { get; set; } = "";
    public string Status { get; set; } = "not_started";
    public int LearningSeconds { get; set; }
    public DateTime? LastLearnedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public sealed class DrawingSubmission : Entity
{
    public string ChildId { get; set; } = "";
    public string? LessonId { get; set; }
    public string? LiveSessionId { get; set; }
    public string ImageAssetId { get; set; } = "";
    public string ImagePath { get; set; } = "";
    public string Status { get; set; } = "pending_review";
}

public sealed class SubmissionReview : Entity
{
    public string SubmissionId { get; set; } = "";
    public string InstructorId { get; set; } = "";
    public decimal Score { get; set; }
    public string Feedback { get; set; } = "";
    public DateTime ReviewedAt { get; set; } = DateTime.UtcNow;
}

public sealed class AiGenerationJob : Entity
{
    public string ChildId { get; set; } = "";
    public string SubmissionId { get; set; } = "";
    public string ConsentId { get; set; } = "";
    public string DrawingImageUrl { get; set; } = "";
    public string Status { get; set; } = "queued";
    public string? ErrorMessage { get; set; }
    public DateTime? CompletedAt { get; set; }
    public int Attempts { get; set; }

    [JsonIgnore]
    public DateTime? LeaseExpiresAt { get; set; }
}

public sealed class AiCreature : Entity
{
    public string SubmissionId { get; set; } = "";
    public string JobId { get; set; } = "";
    public string AnimalType { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string? Model2dUrl { get; set; }
    public string? Model3dUrl { get; set; }
    public string? AnimationUrl { get; set; }
    public string? AudioUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string CheeringMessage { get; set; } = "";
    public string? SuggestedAnimationId { get; set; }
    public string Status { get; set; } = "ready";
}

public sealed class Badge : Entity
{
    public int DisplayOrder { get; set; }
    public string Title { get; set; } = "";
    public string Emoji { get; set; } = "🎨";
    public string IconName { get; set; } = "palette";
    public string Condition { get; set; } = "";
    public string Meaning { get; set; } = "";
    public string Category { get; set; } = "achievement";
    public string PrimaryColor { get; set; } = "#FF1982C4";
    public string SecondaryColor { get; set; } = "#FFFFFFFF";
    public int MaxProgress { get; set; } = 1;
    public string Metric { get; set; } = "submissions";
    public string? ModelGlbPath { get; set; }
}

public sealed class ChildBadge : Entity
{
    public string ChildId { get; set; } = "";
    public string BadgeId { get; set; } = "";
    public int CurrentProgress { get; set; }
    public DateTime? UnlockedAt { get; set; }
}

public sealed class KidReward : Entity
{
    public string ChildId { get; set; } = "";
    public string Title { get; set; } = "";
    public string IconName { get; set; } = "star";
    public string Description { get; set; } = "";
    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;
}

public sealed class PictureSet : Entity
{
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public string ThumbnailAsset { get; set; } = "";
    public string BackgroundAsset { get; set; } = "";
    public double BgAspectRatio { get; set; } = 1.822;
}

public sealed class PictureSlot : Entity
{
    public string PictureSetId { get; set; } = "";
    public string Animal { get; set; } = "cat";
    public int SequenceIndex { get; set; }
    public double LeftPercent { get; set; }
    public double TopPercent { get; set; }
    public double WidthPercent { get; set; }
    public double HeightPercent { get; set; }
}

public sealed class MatchingGameProgress : Entity
{
    public string ChildId { get; set; } = "";
    public string PictureSetId { get; set; } = "";
    public string CurrentStep { get; set; } = "drawing";
    public int CurrentAnimalIndex { get; set; }
    public List<string> UnlockedStickers { get; set; } = [];
    public List<string> MatchedAnimals { get; set; } = [];
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;
}

public sealed class CompletedPicture : Entity
{
    public string ChildId { get; set; } = "";
    public string PictureSetId { get; set; } = "";
    public string PictureTitle { get; set; } = "";
    public string ThumbnailAsset { get; set; } = "";
    public DateTime CompletedAt { get; set; } = DateTime.UtcNow;
}

public sealed class SubscriptionPlan : Entity
{
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public long PriceMonthly { get; set; }
    public long PriceVnd { get; set; }
    public int DurationMonths { get; set; } = 1;
    public List<string> Features { get; set; } = [];
    public bool IncludesKit { get; set; }
    public bool KitDeliveryIncluded { get; set; }
    public bool IsActive { get; set; } = true;
    public string? KitInventorySkuId { get; set; }
    public int KitQuantity { get; set; } = 1;
}

public sealed class Subscription : Entity
{
    public string ParentId { get; set; } = "";
    public string? ChildId { get; set; }
    public string PlanId { get; set; } = "";
    public string OrderItemId { get; set; } = "";
    public string Status { get; set; } = "active";
    public DateTime StartsAt { get; set; }
    public DateTime EndsAt { get; set; }
}

public sealed class Product : Entity
{
    public string Name { get; set; } = "";
    public long PriceVnd { get; set; }
    public long? OriginalPriceVnd { get; set; }
    public string ThumbnailUrl { get; set; } = "";
    public List<string> Images { get; set; } = [];
    public string Description { get; set; } = "";
    public string Category { get; set; } = "individual_tool";
    public string? CourseId { get; set; }
    public string? RecommendedSubscriptionPlanId { get; set; }
    public List<string> KitItems { get; set; } = [];
    public decimal Rating { get; set; }
    public int SoldCount { get; set; }
    public string CreatedBy { get; set; } = "";
    public bool IsActive { get; set; } = true;
    public string ApprovalStatus { get; set; } = "approved";
    public string? RejectionReason { get; set; }
    public bool IsAvailable { get; set; } = true;
    public string FulfillmentMode { get; set; } = "platform";
    public string? ReviewedBy { get; set; }
    public DateTime? ReviewedAt { get; set; }

    [ConcurrencyCheck]
    public int Revision { get; set; } = 1;
}

public sealed class Cart : Entity
{
    public string ParentId { get; set; } = "";
}

public sealed class CartItem : Entity
{
    public string CartId { get; set; } = "";
    public string ProductId { get; set; } = "";
    public int Quantity { get; set; }
}

public sealed class Voucher : Entity
{
    public string Code { get; set; } = "";
    public string Title { get; set; } = "";
    public string DiscountType { get; set; } = "percentage";
    public long DiscountValue { get; set; }
    public long MinOrderAmount { get; set; }
    public long? MaxDiscountAmount { get; set; }
    public DateTime ExpiryDate { get; set; }
    public bool IsUsable { get; set; } = true;
    public int UsageLimit { get; set; }
    public string? Description { get; set; }
}

public sealed class Order : Entity
{
    public string OrderCode { get; set; } = "";
    public string ParentId { get; set; } = "";
    public string? ChildId { get; set; }
    public DateTime? PaidAt { get; set; }
    public string Status { get; set; } = "pending_confirmation";
    public string OrderType { get; set; } = "one_time_purchase";
    public string PaymentStatus { get; set; } = "pending";
    public string PaymentMethodName { get; set; } = "manual_transfer";
    public long SubtotalVnd { get; set; }
    public long ShippingFeeVnd { get; set; }
    public long DiscountVnd { get; set; }
    public string? VoucherId { get; set; }
    public string? VoucherCode { get; set; }
    public long TotalAmountVnd { get; set; }
    public string? CancelReason { get; set; }
    public string IdempotencyKey { get; set; } = "";
}

public sealed class OrderItem : Entity
{
    public string? SellerId { get; set; }
    public string OrderId { get; set; } = "";
    public string ItemType { get; set; } = "kit";
    public string? ProductId { get; set; }
    public string? CourseId { get; set; }
    public string? PlanId { get; set; }
    public string Title { get; set; } = "";
    public string? ThumbnailUrl { get; set; }
    public int Quantity { get; set; }
    public long UnitPriceVnd { get; set; }
    public List<string> KitItems { get; set; } = [];
    public int? DurationMonths { get; set; }
    public string? KitInventorySkuId { get; set; }
    public int KitQuantity { get; set; }
}

public sealed class SellerFulfillment : Entity
{
    public string OrderId { get; set; } = "";
    public string SellerId { get; set; } = "";
    public string Carrier { get; set; } = "";
    public string? TrackingNumber { get; set; }
    public string Status { get; set; } = "preparing";
    public DateTime? ShippedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
}

public sealed class OrderShippingInfo : Entity
{
    public string OrderId { get; set; } = "";
    public string RecipientName { get; set; } = "";
    public string PhoneNumber { get; set; } = "";
    public string FullAddress { get; set; } = "";
    public string? CarrierName { get; set; }
    public string? TrackingNumber { get; set; }
    public string? TrackingUrl { get; set; }
    public DateTime? EstimatedDeliveryDate { get; set; }
}

public sealed class OrderTrackingEvent : Entity
{
    public string OrderId { get; set; } = "";
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public bool IsPassed { get; set; } = true;
    public bool IsCurrent { get; set; } = true;
    public string? CancelReason { get; set; }
}

public sealed class InventorySku : Entity
{
    public string Sku { get; set; } = "";
    public string ProductId { get; set; } = "";
    public string KitName { get; set; } = "";
    public int QuantityAvailable { get; set; }
    public int QuantityReserved { get; set; }
    public int ReorderThreshold { get; set; }
    public long UnitCostVnd { get; set; }
    public string WarehouseLocation { get; set; } = "";
}

public sealed class InventoryReservation : Entity
{
    public string OrderItemId { get; set; } = "";
    public string InventorySkuId { get; set; } = "";
    public int Quantity { get; set; }
    public string Status { get; set; } = "reserved";
    public DateTime ExpiresAt { get; set; }
}

public sealed class FulfillmentOrder : Entity
{
    public string OrderId { get; set; } = "";
    public string InventorySkuId { get; set; } = "";
    public string KitName { get; set; } = "";
    public int Quantity { get; set; }
    public string Carrier { get; set; } = "";
    public string TrackingNumber { get; set; } = "";
    public string Status { get; set; } = "packed";
    public string ShippingAddress { get; set; } = "";
    public string RecipientName { get; set; } = "";
    public string RecipientPhone { get; set; } = "";
    public DateTime? EstimatedDeliveryDate { get; set; }
    public DateTime? ShippedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public string? SubscriptionKitDeliveryId { get; set; }
}

public sealed class SubscriptionKitDelivery : Entity
{
    public string SubscriptionId { get; set; } = "";
    public string InventorySkuId { get; set; } = "";
    public int DeliveryIndex { get; set; }
    public DateTime ScheduledFor { get; set; }
    public int Quantity { get; set; }
}

public sealed class LiveClass : Entity
{
    public string CourseId { get; set; } = "";
    public string InstructorId { get; set; } = "";
    public string Name { get; set; } = "";
    public int Capacity { get; set; } = 30;
    public string Status { get; set; } = "open";
}

public sealed class LiveClassEnrollment : Entity
{
    public string ClassId { get; set; } = "";
    public string ChildId { get; set; } = "";
    public string Status { get; set; } = "enrolled";
    public DateTime EnrolledAt { get; set; } = DateTime.UtcNow;
}

public sealed class LiveSession : Entity
{
    public string ClassId { get; set; } = "";
    public string? LessonId { get; set; }
    public string Title { get; set; } = "";
    public DateTime StartsAt { get; set; }
    public DateTime EndsAt { get; set; }
    public string Provider { get; set; } = "external";

    [JsonIgnore]
    public string? RoomUrl { get; set; }
    public string Status { get; set; } = "scheduled";
    public string? RecordingUrl { get; set; }
}

public sealed class LiveSessionAttendance : Entity
{
    public string SessionId { get; set; } = "";
    public string ClassEnrollmentId { get; set; } = "";
    public DateTime? FirstJoinedAt { get; set; }
    public DateTime? LastJoinedAt { get; set; }
    public DateTime? LastLeftAt { get; set; }
    public int TotalDurationSeconds { get; set; }
}

public sealed class MediaAsset : Entity
{
    public string OwnerId { get; set; } = "";
    public string? ChildId { get; set; }
    public string Kind { get; set; } = "drawing";

    [JsonIgnore]
    public string StorageKey { get; set; } = "";
    public string OriginalName { get; set; } = "";
    public string ContentType { get; set; } = "image/png";
    public long SizeBytes { get; set; }
}

public sealed class Notification : Entity
{
    public string UserId { get; set; } = "";
    public string Title { get; set; } = "";
    public string Message { get; set; } = "";
    public string? ReferenceId { get; set; }
    public DateTime? ReadAt { get; set; }
}
