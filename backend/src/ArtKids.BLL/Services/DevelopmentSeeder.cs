using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ArtKids.BLL.Services;

public sealed class DevelopmentSeeder(
    IUnitOfWork store,
    IPasswordHasher<User> hasher,
    IConfiguration config
)
{
    public async Task Seed()
    {
        if (await store.Repository<User>().Query.AnyAsync())
            return;
        await store.TransactionAsync(async () =>
        {
            var password = config["Seed:Password"] ?? "ArtKids-Test-2026!";
            User User(string id, string email, string name, string role)
            {
                var u = new User
                {
                    Id = id,
                    Email = email,
                    FullName = name,
                    Role = role,
                };
                u.PasswordHash = hasher.HashPassword(u, password);
                u.ParentPinHash = hasher.HashPassword(u, "2468");
                store.Repository<User>().Add(u);
                return u;
            }

            User("admin_test_01", "admin.test@example.invalid", "ArtKids Test Admin", "admin");
            User(
                "instructor_test_01",
                "instructor.test@example.invalid",
                "ArtKids Test Instructor",
                "instructor"
            );
            User(
                "instructor_test_02",
                "instructor2.test@example.invalid",
                "Other Test Instructor",
                "instructor"
            );
            User("parent_test_01", "parent.test@example.invalid", "Nguyen Test Parent", "parent");
            await store.SaveAsync();
            foreach (
                var (id, name, year) in new[]
                {
                    ("child-1", "Bo Test", 2018),
                    ("child-2", "Mi Test", 2021),
                    ("child-empty", "New Test Child", 2022),
                }
            )
                store
                    .Repository<ChildProfile>()
                    .Add(
                        new()
                        {
                            Id = id,
                            ParentId = "parent_test_01",
                            Nickname = name,
                            BirthYear = year,
                        }
                    );
            store
                .Repository<AvatarPreset>()
                .Add(
                    new()
                    {
                        Id = "avatar_cat",
                        Name = "Mèo họa sĩ",
                        IsForChild = true,
                        Type = "icon",
                        IconName = "pets",
                    }
                );
            store
                .Repository<Course>()
                .Add(
                    new()
                    {
                        Id = "course_basics",
                        Title = "Vẽ cơ bản",
                        Description = "Khóa học miễn phí để thử các API học tập.",
                        PriceVnd = 0,
                        InstructorId = "instructor_test_01",
                        IsPublished = true,
                    }
                );
            store
                .Repository<Course>()
                .Add(
                    new()
                    {
                        Id = "course_animals",
                        Title = "Vẽ động vật",
                        Description = "Khóa học trả phí để thử checkout và cấp quyền học.",
                        PriceVnd = 150000,
                        InstructorId = "instructor_test_01",
                        IsPublished = true,
                    }
                );
            store
                .Repository<SubscriptionPlan>()
                .Add(
                    new()
                    {
                        Id = "plan_monthly",
                        Name = "Học vẽ 1 tháng",
                        PriceVnd = 199000,
                        PriceMonthly = 199000,
                        DurationMonths = 1,
                        Features = ["Đăng ký các khóa học đã xuất bản", "Theo dõi tiến độ"],
                    }
                );
            store
                .Repository<SubscriptionPlan>()
                .Add(
                    new()
                    {
                        Id = "plan_quarterly",
                        Name = "Học vẽ 3 tháng",
                        PriceVnd = 499000,
                        PriceMonthly = 166333,
                        DurationMonths = 3,
                        Features = ["Đăng ký các khóa học đã xuất bản"],
                    }
                );
            await store.SaveAsync();
            store
                .Repository<Lesson>()
                .Add(
                    new()
                    {
                        Id = "lesson_basics_1",
                        CourseId = "course_basics",
                        Title = "Nét vẽ đầu tiên",
                        OrderIndex = 1,
                        PracticeInstructions = "Vẽ một con mèo trên giấy rồi chụp ảnh nộp bài.",
                    }
                );
            store
                .Repository<Lesson>()
                .Add(
                    new()
                    {
                        Id = "lesson_basics_2",
                        CourseId = "course_basics",
                        Title = "Phối màu",
                        OrderIndex = 2,
                    }
                );
            store
                .Repository<Lesson>()
                .Add(
                    new()
                    {
                        Id = "lesson_animals_1",
                        CourseId = "course_animals",
                        Title = "Vẽ mèo",
                        OrderIndex = 1,
                    }
                );
            store
                .Repository<Enrollment>()
                .Add(
                    new()
                    {
                        Id = "enrollment_bo_basics",
                        ChildId = "child-1",
                        CourseId = "course_basics",
                    }
                );
            var products = new[]
            {
                ("prod_kit_animal", "Bộ học cụ vẽ động vật", 180000L, "course_kit"),
                ("prod_kit_acrylic", "Bộ màu acrylic", 220000L, "course_kit"),
                ("prod_kit_fairytale", "Bộ vẽ cổ tích", 250000L, "course_kit"),
                ("prod_kit_clay", "Bộ đất nặn", 190000L, "course_kit"),
                ("prod_tool_brushes", "Bộ cọ vẽ", 80000L, "individual_tool"),
                ("prod_tool_kuretake", "Bộ màu nước", 150000L, "individual_tool"),
            };
            foreach (var (id, name, price, category) in products)
            {
                store
                    .Repository<Product>()
                    .Add(
                        new()
                        {
                            Id = id,
                            Name = name,
                            Description = "Học cụ mẫu phục vụ kiểm thử backend.",
                            PriceVnd = price,
                            Category = category,
                            CreatedBy = "admin_test_01",
                            KitItems = ["Học cụ", "Hướng dẫn"],
                        }
                    );
                store
                    .Repository<InventorySku>()
                    .Add(
                        new()
                        {
                            Id = "stock_" + id,
                            Sku = "SKU-" + id.ToUpperInvariant(),
                            ProductId = id,
                            KitName = name,
                            QuantityAvailable = 50,
                            ReorderThreshold = 5,
                            UnitCostVnd = price / 2,
                            WarehouseLocation = "Test warehouse",
                        }
                    );
            }

            store
                .Repository<Voucher>()
                .Add(
                    new()
                    {
                        Id = "voucher_artkids10",
                        Code = "ARTKIDS10",
                        Title = "Giảm 10%",
                        DiscountType = "percentage",
                        DiscountValue = 10,
                        MinOrderAmount = 200000,
                        MaxDiscountAmount = 50000,
                        ExpiryDate = DateTime.UtcNow.AddYears(1),
                        UsageLimit = 100,
                    }
                );
            store
                .Repository<Voucher>()
                .Add(
                    new()
                    {
                        Id = "voucher_kid30k",
                        Code = "KID30K",
                        Title = "Giảm 30.000đ",
                        DiscountType = "fixedAmount",
                        DiscountValue = 30000,
                        MinOrderAmount = 150000,
                        ExpiryDate = DateTime.UtcNow.AddYears(1),
                        UsageLimit = 100,
                    }
                );
            store
                .Repository<Voucher>()
                .Add(
                    new()
                    {
                        Id = "voucher_expired",
                        Code = "EXPIRED20",
                        Title = "Voucher hết hạn",
                        DiscountValue = 20,
                        ExpiryDate = DateTime.UtcNow.AddDays(-1),
                        UsageLimit = 100,
                    }
                );
            for (var i = 1; i <= 20; i++)
                store
                    .Repository<Badge>()
                    .Add(
                        new()
                        {
                            Id = "badge_" + i,
                            DisplayOrder = i,
                            Title = i <= 10 ? $"Họa sĩ sáng tạo {i}" : $"Học tập chăm chỉ {i - 10}",
                            Condition =
                                i <= 10 ? $"Nộp {i} bài vẽ" : $"Hoàn thành {i - 10} bài học",
                            Meaning = "Khích lệ bé học và thực hành",
                            Metric = i <= 10 ? "submissions" : "lessons",
                            MaxProgress = i <= 10 ? i : i - 10,
                            Category = i <= 10 ? "achievement" : "habit",
                        }
                    );
            store
                .Repository<PictureSet>()
                .Add(
                    new()
                    {
                        Id = "living_room",
                        Title = "Phòng khách",
                        Description = "Vẽ và ghép các bạn thú.",
                        ThumbnailAsset = "assets/images/matching_game/living_room.png",
                        BackgroundAsset = "assets/images/matching_game/living_room.png",
                    }
                );
            foreach (var (animal, i) in new[] { ("cat", 0), ("dog", 1), ("bird", 2) })
                store
                    .Repository<PictureSlot>()
                    .Add(
                        new()
                        {
                            PictureSetId = "living_room",
                            Animal = animal,
                            SequenceIndex = i,
                            LeftPercent = .1 + i * .25,
                            TopPercent = .4,
                            WidthPercent = .2,
                            HeightPercent = .3,
                        }
                    );
            return true;
        });
    }
}
