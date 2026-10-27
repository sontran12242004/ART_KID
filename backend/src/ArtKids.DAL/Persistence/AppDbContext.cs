using System.Text.Json;
using ArtKids.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace ArtKids.DAL.Persistence;

public abstract class AppDbContext(DbContextOptions options) : DbContext(options)
{
    protected override void OnModelCreating(ModelBuilder b)
    {
        var types = typeof(Entity)
            .Assembly.GetTypes()
            .Where(t => t.IsSubclassOf(typeof(Entity)) && !t.IsAbstract);
        foreach (var type in types)
        {
            var entity = b.Entity(type);
            entity.HasBaseType((Type?)null);
            var singular = Snake(type.Name);
            entity.ToTable(
                singular
                    is "lesson_progress"
                        or "matching_game_progress"
                        or "order_shipping_info"
                        or "live_session_attendance"
                    ? singular
                    : singular + "s"
            );
            entity.HasKey(nameof(Entity.Id));
            foreach (var p in entity.Metadata.GetProperties())
            {
                p.SetColumnName(Snake(p.Name));
                if (p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?))
                {
                    p.SetPrecision(18);
                    p.SetScale(2);
                }

                // SQLite otherwise stores decimal as TEXT, which breaks numeric CHECK comparisons.
                if (Database.IsSqlite() && p.ClrType == typeof(decimal))
                {
                    p.SetValueConverter(
                        new ValueConverter<decimal, double>(v => (double)v, v => (decimal)v)
                    );
                    p.SetColumnType("REAL");
                }

                if (p.ClrType == typeof(List<string>))
                {
                    p.SetValueConverter(
                        new ValueConverter<List<string>, string>(
                            v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                            v =>
                                JsonSerializer.Deserialize<List<string>>(
                                    v,
                                    (JsonSerializerOptions?)null
                                )!
                        )
                    );
                    p.SetValueComparer(
                        new ValueComparer<List<string>>(
                            (a, c) => a!.SequenceEqual(c!),
                            v => v.Aggregate(0, (a, s) => HashCode.Combine(a, s.GetHashCode())),
                            v => v.ToList()
                        )
                    );
                }
            }
        }

        void F<T, P>(string property)
            where T : Entity
            where P : Entity =>
            b.Entity<T>()
                .HasOne<P>()
                .WithMany()
                .HasForeignKey(property)
                .OnDelete(DeleteBehavior.Restrict);
        F<User, AvatarPreset>("AvatarPresetId");
        F<RefreshToken, User>("UserId");
        F<ChildProfile, User>("ParentId");
        F<ChildProfile, AvatarPreset>("AvatarPresetId");
        F<ParentalConsent, User>("ParentId");
        F<ParentalConsent, ChildProfile>("ChildId");
        F<Course, User>("InstructorId");
        F<Lesson, Course>("CourseId");
        F<Lesson, MediaAsset>("VideoAssetId");
        F<Enrollment, ChildProfile>("ChildId");
        F<Enrollment, Course>("CourseId");
        F<Enrollment, OrderItem>("OrderItemId");
        F<LessonProgress, Enrollment>("EnrollmentId");
        F<LessonProgress, Lesson>("LessonId");
        F<DrawingSubmission, ChildProfile>("ChildId");
        F<DrawingSubmission, Lesson>("LessonId");
        F<DrawingSubmission, LiveSession>("LiveSessionId");
        F<DrawingSubmission, MediaAsset>("ImageAssetId");
        F<SubmissionReview, DrawingSubmission>("SubmissionId");
        F<SubmissionReview, User>("InstructorId");
        F<AiGenerationJob, ChildProfile>("ChildId");
        F<AiGenerationJob, DrawingSubmission>("SubmissionId");
        F<AiGenerationJob, ParentalConsent>("ConsentId");
        F<AiCreature, DrawingSubmission>("SubmissionId");
        F<AiCreature, AiGenerationJob>("JobId");
        F<ChildBadge, ChildProfile>("ChildId");
        F<ChildBadge, Badge>("BadgeId");
        F<KidReward, ChildProfile>("ChildId");
        F<PictureSlot, PictureSet>("PictureSetId");
        F<MatchingGameProgress, PictureSet>("PictureSetId");
        F<MatchingGameProgress, ChildProfile>("ChildId");
        F<CompletedPicture, PictureSet>("PictureSetId");
        F<CompletedPicture, ChildProfile>("ChildId");
        F<Subscription, User>("ParentId");
        F<Subscription, ChildProfile>("ChildId");
        F<Subscription, SubscriptionPlan>("PlanId");
        F<Subscription, OrderItem>("OrderItemId");
        F<SubscriptionPlan, InventorySku>("KitInventorySkuId");
        F<SubscriptionKitDelivery, Subscription>("SubscriptionId");
        F<SubscriptionKitDelivery, InventorySku>("InventorySkuId");
        F<OrderItem, InventorySku>("KitInventorySkuId");
        F<Product, Course>("CourseId");
        F<Product, SubscriptionPlan>("RecommendedSubscriptionPlanId");
        F<Product, User>("CreatedBy");
        F<Cart, User>("ParentId");
        F<CartItem, Cart>("CartId");
        F<CartItem, Product>("ProductId");
        F<Order, User>("ParentId");
        F<Order, ChildProfile>("ChildId");
        F<Order, Voucher>("VoucherId");
        F<OrderItem, Order>("OrderId");
        F<OrderItem, Product>("ProductId");
        F<OrderItem, Course>("CourseId");
        F<OrderItem, SubscriptionPlan>("PlanId");
        F<OrderShippingInfo, Order>("OrderId");
        F<OrderTrackingEvent, Order>("OrderId");
        F<InventorySku, Product>("ProductId");
        F<InventoryReservation, OrderItem>("OrderItemId");
        F<InventoryReservation, InventorySku>("InventorySkuId");
        F<FulfillmentOrder, Order>("OrderId");
        F<FulfillmentOrder, InventorySku>("InventorySkuId");
        F<FulfillmentOrder, SubscriptionKitDelivery>("SubscriptionKitDeliveryId");
        F<LiveClass, Course>("CourseId");
        F<LiveClass, User>("InstructorId");
        F<LiveClassEnrollment, LiveClass>("ClassId");
        F<LiveClassEnrollment, ChildProfile>("ChildId");
        F<LiveSession, LiveClass>("ClassId");
        F<LiveSession, Lesson>("LessonId");
        F<LiveSessionAttendance, LiveSession>("SessionId");
        F<LiveSessionAttendance, LiveClassEnrollment>("ClassEnrollmentId");
        F<MediaAsset, User>("OwnerId");
        F<MediaAsset, ChildProfile>("ChildId");
        F<Notification, User>("UserId");
        b.Entity<User>().HasIndex(x => x.Email).IsUnique();
        b.Entity<RefreshToken>().HasIndex(x => x.TokenHash).IsUnique();
        b.Entity<Lesson>().HasIndex(x => new { x.CourseId, x.OrderIndex }).IsUnique();
        b.Entity<Enrollment>().HasIndex(x => new { x.ChildId, x.CourseId }).IsUnique();
        b.Entity<LessonProgress>().HasIndex(x => new { x.EnrollmentId, x.LessonId }).IsUnique();
        b.Entity<AiCreature>().HasIndex(x => x.JobId).IsUnique();
        b.Entity<ChildBadge>().HasIndex(x => new { x.ChildId, x.BadgeId }).IsUnique();
        b.Entity<PictureSlot>().HasIndex(x => new { x.PictureSetId, x.Animal }).IsUnique();
        b.Entity<MatchingGameProgress>()
            .HasIndex(x => new { x.ChildId, x.PictureSetId })
            .IsUnique();
        b.Entity<Subscription>().HasIndex(x => x.OrderItemId).IsUnique();
        b.Entity<Cart>().HasIndex(x => x.ParentId).IsUnique();
        b.Entity<CartItem>().HasIndex(x => new { x.CartId, x.ProductId }).IsUnique();
        b.Entity<Voucher>().HasIndex(x => x.Code).IsUnique();
        b.Entity<Order>().HasIndex(x => new { x.ParentId, x.IdempotencyKey }).IsUnique();
        b.Entity<Order>().HasIndex(x => x.OrderCode).IsUnique();
        b.Entity<OrderShippingInfo>().HasIndex(x => x.OrderId).IsUnique();
        b.Entity<InventorySku>().HasIndex(x => x.Sku).IsUnique();
        b.Entity<InventorySku>().HasIndex(x => x.ProductId).IsUnique();
        b.Entity<FulfillmentOrder>().HasIndex(x => x.SubscriptionKitDeliveryId).IsUnique();
        b.Entity<SubscriptionKitDelivery>()
            .HasIndex(x => new { x.SubscriptionId, x.DeliveryIndex })
            .IsUnique();
        b.Entity<FulfillmentOrder>().HasIndex(x => new { x.Carrier, x.TrackingNumber }).IsUnique();
        b.Entity<LiveClassEnrollment>().HasIndex(x => new { x.ClassId, x.ChildId }).IsUnique();
        b.Entity<LiveSessionAttendance>()
            .HasIndex(x => new { x.SessionId, x.ClassEnrollmentId })
            .IsUnique();
        b.Entity<SubmissionReview>().Property(x => x.Score).HasPrecision(4, 2);
        b.Entity<LiveClass>()
            .ToTable(t => t.HasCheckConstraint("ck_capacity", "capacity BETWEEN 1 AND 30"));
        b.Entity<InventorySku>()
            .ToTable(t =>
                t.HasCheckConstraint(
                    "ck_stock",
                    "quantity_available >= 0 AND quantity_reserved >= 0"
                )
            );
        b.Entity<SubmissionReview>()
            .ToTable(t => t.HasCheckConstraint("ck_score", "score BETWEEN 0 AND 10"));
        b.Entity<LiveSession>()
            .ToTable(t => t.HasCheckConstraint("ck_session_time", "ends_at > starts_at"));
        b.Entity<CartItem>().ToTable(t => t.HasCheckConstraint("ck_cart_quantity", "quantity > 0"));
        b.Entity<OrderItem>()
            .ToTable(t => t.HasCheckConstraint("ck_item", "quantity > 0 AND unit_price_vnd >= 0"));
        b.Entity<Order>()
            .ToTable(t =>
                t.HasCheckConstraint(
                    "ck_order_total",
                    "subtotal_vnd >= 0 AND shipping_fee_vnd >= 0 AND discount_vnd >= 0 AND total_amount_vnd = subtotal_vnd + shipping_fee_vnd - discount_vnd AND total_amount_vnd >= 0"
                )
            );
    }

    private static string Snake(string s)
    {
        return System
            .Text.RegularExpressions.Regex.Replace(s, "([a-z0-9])([A-Z])", "$1_$2")
            .ToLowerInvariant();
    }
}

public sealed class SqliteAppDbContext(DbContextOptions<SqliteAppDbContext> options)
    : AppDbContext(options);

public sealed class PostgresAppDbContext(DbContextOptions<PostgresAppDbContext> options)
    : AppDbContext(options);

public sealed class SqliteDesignFactory : IDesignTimeDbContextFactory<SqliteAppDbContext>
{
    public SqliteAppDbContext CreateDbContext(string[] args)
    {
        return new(
            new DbContextOptionsBuilder<SqliteAppDbContext>()
                .UseSqlite("Data Source=design.db")
                .Options
        );
    }
}

public sealed class PostgresDesignFactory : IDesignTimeDbContextFactory<PostgresAppDbContext>
{
    public PostgresAppDbContext CreateDbContext(string[] args)
    {
        return new(
            new DbContextOptionsBuilder<PostgresAppDbContext>()
                .UseNpgsql("Host=localhost;Database=artkids;Username=artkids;Password=design-only")
                .Options
        );
    }
}
