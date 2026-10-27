using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class LearningService(
    IUnitOfWork store,
    ICurrentUser actor,
    CloudinaryVideoClient cloud
) : ServiceBase(store, actor)
{
    public async Task<object> Courses(int page, int size, string? search)
    {
        var q = Q<Course>()
            .Where(x =>
                !x.IsDeleted
                && (
                    x.IsPublished
                    || Actor.Role == "admin"
                    || (Actor.Role == "instructor" && x.InstructorId == Actor.Id)
                )
            );
        if (!string.IsNullOrWhiteSpace(search))
            q = q.Where(x => x.Title.Contains(search));
        return new
        {
            total = await q.CountAsync(),
            page = Page(page),
            pageSize = Size(size),
            items = await q.OrderBy(x => x.Title)
                .Skip((Page(page) - 1) * Size(size))
                .Take(Size(size))
                .Select(x => new
                {
                    x.Id,
                    x.Title,
                    x.Description,
                    x.ThumbnailUrl,
                    x.AgeRange,
                    x.PriceVnd,
                    x.IncludesPhysicalKit,
                    x.InstructorId,
                    x.IsPublished,
                    totalLessons = Q<Lesson>().Count(l => l.CourseId == x.Id),
                })
                .ToListAsync(),
        };
    }

    public async Task<Course> Course(string id)
    {
        var c = await Get<Course>(id);
        var hasEnrollment =
            Actor.Role == "parent"
            && await (
                from enrollment in Q<Enrollment>()
                join child in Q<ChildProfile>() on enrollment.ChildId equals child.Id
                where enrollment.CourseId == id && child.ParentId == Actor.Id
                select enrollment.Id
            ).AnyAsync();
        Require(
            (!c.IsDeleted && c.IsPublished)
                || Actor.Role == "admin"
                || c.InstructorId == Actor.Id
                || hasEnrollment,
            "Course not found.",
            404
        );
        return c;
    }

    public async Task<Course> SaveCourse(string? id, CourseRequest r)
    {
        Roles("admin", "instructor");
        var teacher = Actor.Role == "instructor" ? Actor.Id : r.InstructorId ?? Actor.Id;
        var user = await Get<User>(teacher);
        Require(
            user.Role is "instructor" or "admin",
            "Course owner must be an instructor or admin."
        );
        var c = id is null ? new Course() : await TeachCourse(id);
        c.Title = r.Title;
        c.Description = r.Description;
        c.AgeRange = r.AgeRange;
        c.PriceVnd = r.PriceVnd;
        c.ThumbnailUrl = r.ThumbnailUrl;
        c.InstructorId = teacher;
        c.IncludesPhysicalKit = r.IncludesPhysicalKit;
        c.IsPublished = r.IsPublished;
        if (id is null)
            Add(c);
        await Store.SaveAsync();
        return c;
    }

    public Task<bool> DeleteCourse(string id)
    {
        return Store.TransactionAsync(async () =>
        {
            var course = await TeachCourse(id);
            course.IsDeleted = true;
            course.IsPublished = false;
            foreach (var product in await Q<Product>().Where(p => p.CourseId == id).ToListAsync())
                product.IsActive = false;
            return true;
        });
    }

    public async Task<object> Lessons(string courseId, string? childId = null)
    {
        await Course(courseId);
        var completedIds = new List<string>();
        if (childId is not null)
        {
            await OwnChild(childId);
            var enrollmentIds = Q<Enrollment>()
                .Where(x => x.ChildId == childId && x.CourseId == courseId)
                .Select(x => x.Id);
            completedIds = await Q<LessonProgress>()
                .Where(x => enrollmentIds.Contains(x.EnrollmentId) && x.Status == "completed")
                .Select(x => x.LessonId)
                .ToListAsync();
        }
        // Public catalogue contains metadata; private uploaded video bytes require enrolment.
        return await Q<Lesson>()
            .Where(x => x.CourseId == courseId)
            .OrderBy(x => x.OrderIndex)
            .Select(x => new
            {
                x.Id,
                x.CourseId,
                x.Title,
                x.OrderIndex,
                x.PracticeInstructions,
                hasVideo = x.VideoAssetId != null || x.VideoUrl != null,
                completed = completedIds.Contains(x.Id),
            })
            .ToListAsync();
    }

    public async Task<object> Lesson(string id, string? childId)
    {
        var l = await Get<Lesson>(id);
        var c = await Course(l.CourseId);
        if (Actor.Role != "admin" && c.InstructorId != Actor.Id)
        {
            Require(childId is not null, "childId is required.");
            await RequireEnrollment(childId!, c.Id);
        }

        var completed = false;
        var hasSubmission = false;
        if (childId is not null)
        {
            await OwnChild(childId);
            hasSubmission = await Q<DrawingSubmission>()
                .AnyAsync(x => x.ChildId == childId && x.LessonId == id);
            var enrollmentIds = Q<Enrollment>()
                .Where(x => x.ChildId == childId && x.CourseId == c.Id)
                .Select(x => x.Id);
            completed = await Q<LessonProgress>().AnyAsync(x =>
                enrollmentIds.Contains(x.EnrollmentId) && x.LessonId == id && x.Status == "completed"
            );
        }
        var nextLessonId = await Q<Lesson>()
            .Where(x => x.CourseId == c.Id && x.OrderIndex > l.OrderIndex)
            .OrderBy(x => x.OrderIndex)
            .Select(x => x.Id)
            .FirstOrDefaultAsync();

        return new
        {
            completed,
            hasSubmission,
            nextLessonId,
            l.Id,
            l.CourseId,
            l.Title,
            l.OrderIndex,
            l.VideoAssetId,
            VideoUrl = cloud.PlaybackUrl(l.VideoUrl),
            l.PracticeInstructions,
            l.CreatedAt,
        };
    }

    public async Task<Lesson> SaveLesson(string courseId, string? id, LessonRequest r)
    {
        await TeachCourse(courseId);
        var l = id is null ? new Lesson { CourseId = courseId } : await Get<Lesson>(id);
        Require(l.CourseId == courseId, "Lesson not found.", 404);
        Require(r.VideoAssetId is null || r.VideoUrl is null, "Choose one video source.");
        Require(
            !CloudinaryVideoClient.IsManagedUrl(r.VideoUrl) || l.VideoUrl == r.VideoUrl,
            "Cloudinary videos must be attached through the verified upload flow."
        );
        Require(
            !await Q<Lesson>()
                .AnyAsync(x =>
                    x.CourseId == courseId && x.OrderIndex == r.OrderIndex && x.Id != id
                ),
            "Lesson order already exists.",
            409
        );
        if (r.VideoAssetId is not null)
        {
            var asset = await Get<MediaAsset>(r.VideoAssetId);
            Require(
                asset.Kind == "video" && (Actor.Role == "admin" || asset.OwnerId == Actor.Id),
                "Invalid video asset."
            );
        }

        if (r.VideoUrl is not null)
            Require(
                Uri.TryCreate(r.VideoUrl, UriKind.Absolute, out var uri) && uri.Scheme == "https",
                "Video URL must be HTTPS."
            );
        l.Title = r.Title;
        l.OrderIndex = r.OrderIndex;
        l.VideoAssetId = r.VideoAssetId;
        l.VideoUrl = r.VideoUrl;
        l.PracticeInstructions = r.PracticeInstructions;
        if (id is null)
            Add(l);
        await Store.SaveAsync();
        return l;
    }

    public Task<Enrollment> Enroll(EnrollmentRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            Roles("parent", "admin");
            var child = await OwnChild(r.ChildId);
            var c = await Course(r.CourseId);
            var old = await Q<Enrollment>()
                .SingleOrDefaultAsync(x => x.ChildId == child.Id && x.CourseId == c.Id);
            if (old is not null)
                return old;
            Require(!c.IsDeleted && c.IsPublished, "Course is unavailable.", 404);
            var now = DateTime.UtcNow;
            var subscribed = await Q<Subscription>()
                .AnyAsync(x =>
                    x.ParentId == child.ParentId
                    && (x.ChildId == null || x.ChildId == child.Id)
                    && x.Status == "active"
                    && x.StartsAt <= now
                    && x.EndsAt > now
                );
            Require(
                c.PriceVnd == 0 || Actor.Role == "admin" || subscribed,
                "Purchase the course or an active subscription before enrolling.",
                403
            );
            var e = new Enrollment { ChildId = child.Id, CourseId = c.Id };
            Add(e);
            return e;
        });
    }

    public async Task<object> Progress(string childId)
    {
        await OwnChild(childId);
        var es = await Q<Enrollment>().Where(x => x.ChildId == childId).ToListAsync();
        var result = new List<object>();
        foreach (var e in es)
        {
            var c = await Get<Course>(e.CourseId);
            var total = await Q<Lesson>().CountAsync(x => x.CourseId == c.Id);
            var completed = await Q<LessonProgress>()
                .CountAsync(x => x.EnrollmentId == e.Id && x.Status == "completed");
            result.Add(
                new
                {
                    enrollmentId = e.Id,
                    courseId = c.Id,
                    courseTitle = c.Title,
                    courseThumbnail = c.ThumbnailUrl,
                    totalLessons = total,
                    completedLessons = completed,
                    e.LastLearnedAt,
                    status = total > 0 && completed == total ? "completed"
                    : e.LastLearnedAt is null ? "not_started"
                    : "in_progress",
                }
            );
        }

        return result;
    }

    public Task<LessonProgress> SaveProgress(ProgressRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var l = await Get<Lesson>(r.LessonId);
            await RequireEnrollment(r.ChildId, l.CourseId);
            if (r.Status == "completed")
                Require(
                    await Q<DrawingSubmission>().AnyAsync(x =>
                        x.ChildId == r.ChildId && x.LessonId == l.Id
                    ),
                    "Bé cần nộp bài vẽ canvas hoặc ảnh bài vẽ trên giấy trước khi hoàn thành bài học.",
                    409
                );
            var e = await Q<Enrollment>()
                .SingleAsync(x => x.ChildId == r.ChildId && x.CourseId == l.CourseId);
            var p = await Q<LessonProgress>()
                .SingleOrDefaultAsync(x => x.EnrollmentId == e.Id && x.LessonId == l.Id);
            if (p is null)
            {
                p = new LessonProgress { EnrollmentId = e.Id, LessonId = l.Id };
                Add(p);
            }

            if (p.Status != "completed")
                p.Status = r.Status;
            p.LearningSeconds = checked(p.LearningSeconds + r.LearningSeconds);
            p.LastLearnedAt = e.LastLearnedAt = DateTime.UtcNow;
            if (p.Status == "completed")
                p.CompletedAt ??= DateTime.UtcNow;
            await Store.SaveAsync();
            await RefreshBadges(r.ChildId);
            return p;
        });
    }

    public Task<DrawingSubmission> Submit(SubmissionRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            await OwnChild(r.ChildId);
            var asset = await Get<MediaAsset>(r.ImageAssetId);
            Require(
                asset.OwnerId == Actor.Id && asset.ChildId == r.ChildId && asset.Kind == "drawing",
                "Drawing asset does not belong to this child.",
                403
            );
            if (r.LessonId is not null)
            {
                var l = await Get<Lesson>(r.LessonId);
                await RequireEnrollment(r.ChildId, l.CourseId);
            }

            if (r.LiveSessionId is not null)
            {
                var session = await Get<LiveSession>(r.LiveSessionId);
                var cls = await Get<LiveClass>(session.ClassId);
                Require(
                    await Q<LiveClassEnrollment>()
                        .AnyAsync(x =>
                            x.ClassId == cls.Id && x.ChildId == r.ChildId && x.Status == "enrolled"
                        ),
                    "Child is not enrolled in this live class.",
                    403
                );
                if (r.LessonId is not null)
                {
                    var l = await Get<Lesson>(r.LessonId);
                    Require(
                        l.CourseId == cls.CourseId,
                        "Lesson and live class must belong to the same course."
                    );
                }
            }

            Require(
                await Q<ParentalConsent>()
                    .AnyAsync(x =>
                        x.ChildId == r.ChildId
                        && x.Purpose == "data_processing"
                        && x.RevokedAt == null
                    ),
                "Parental data-processing consent is required.",
                403
            );
            Require(
                !await Q<DrawingSubmission>().AnyAsync(x => x.ImageAssetId == asset.Id),
                "This drawing has already been submitted.",
                409
            );
            var s = new DrawingSubmission
            {
                ChildId = r.ChildId,
                LessonId = r.LessonId,
                LiveSessionId = r.LiveSessionId,
                ImageAssetId = asset.Id,
                ImagePath = $"/api/v1/media/{asset.Id}",
            };
            Add(s);
            await Store.SaveAsync();
            await RefreshBadges(r.ChildId);
            return s;
        });
    }

    public async Task EnsureSubmissionAccess(DrawingSubmission s, bool reviewing = false)
    {
        if (Actor.Role == "admin")
            return;
        if (!reviewing && Actor.Role == "parent")
        {
            await OwnChild(s.ChildId);
            return;
        }

        Roles("instructor");
        if (s.LiveSessionId is not null)
        {
            var session = await Get<LiveSession>(s.LiveSessionId);
            var cls = await Get<LiveClass>(session.ClassId);
            if (cls.InstructorId == Actor.Id)
                return;
        }

        Require(s.LessonId is not null, "This submission is not assigned to this instructor.", 403);
        await TeachCourse((await Get<Lesson>(s.LessonId!)).CourseId);
    }

    public async Task<object> Submission(string id)
    {
        var s = await Get<DrawingSubmission>(id);
        await EnsureSubmissionAccess(s);
        return new
        {
            submission = s,
            child = await Q<ChildProfile>().Where(x => x.Id == s.ChildId)
                .Select(x => new { x.Id, x.Nickname, x.BirthYear }).SingleAsync(),
            reviews = await Q<SubmissionReview>()
                .Where(x => x.SubmissionId == id)
                .OrderByDescending(x => x.ReviewedAt)
                .ToListAsync(),
        };
    }

    public async Task<object> GradingCourses()
    {
        Roles("admin", "instructor");
        return await Q<Course>()
            .Where(c => !c.IsDeleted && (Actor.Role == "admin" || c.InstructorId == Actor.Id))
            .OrderBy(c => c.Title)
            .Select(c => new {
                c.Id, c.Title,
                lessonCount = Q<Lesson>().Count(l => l.CourseId == c.Id),
                pendingCount = Q<DrawingSubmission>().Count(s => s.Status == "pending_review" &&
                    Q<Lesson>().Any(l => l.Id == s.LessonId && l.CourseId == c.Id))
            }).ToListAsync();
    }

    public async Task<object> GradingLessons(string courseId)
    {
        var course = await TeachCourse(courseId);
        return new {
            courseTitle = course.Title,
            lessons = await Q<Lesson>().Where(l => l.CourseId == courseId)
                .OrderBy(l => l.OrderIndex)
                .Select(l => new {
                    l.Id, l.Title, l.OrderIndex,
                    pendingCount = Q<DrawingSubmission>().Count(s => s.LessonId == l.Id && s.Status == "pending_review"),
                    totalCount = Q<DrawingSubmission>().Count(s => s.LessonId == l.Id)
                }).ToListAsync()
        };
    }

    public async Task<object> GradingSubmissions(string lessonId, bool pendingOnly, int page)
    {
        var lesson = await Get<Lesson>(lessonId);
        var course = await TeachCourse(lesson.CourseId);
        var submissions = Q<DrawingSubmission>().Where(s => s.LessonId == lessonId);
        if (pendingOnly) submissions = submissions.Where(s => s.Status == "pending_review");
        return new {
            lessonTitle = lesson.Title, courseTitle = course.Title,
            total = await submissions.CountAsync(),
            items = await (from s in submissions
                           join child in Q<ChildProfile>() on s.ChildId equals child.Id
                           orderby s.CreatedAt ascending, s.Id
                           select new { s.Id, s.Status, s.CreatedAt, s.ImageAssetId,
                               childId = child.Id, childName = child.Nickname, child.BirthYear })
                .Skip((Page(page) - 1) * 20).Take(20).ToListAsync()
        };
    }

    public async Task<object> Submissions(string? childId, int page, int size)
    {
        var q = Q<DrawingSubmission>();
        if (Actor.Role == "parent")
        {
            Require(childId is not null, "childId is required.");
            await OwnChild(childId!);
            q = q.Where(x => x.ChildId == childId);
        }
        else if (Actor.Role == "instructor")
        {
            var lessonIds = Q<Lesson>()
                .Where(l => Q<Course>().Any(c => c.Id == l.CourseId && c.InstructorId == Actor.Id))
                .Select(x => x.Id);
            var sessionIds = Q<LiveSession>()
                .Where(s =>
                    Q<LiveClass>().Any(c => c.Id == s.ClassId && c.InstructorId == Actor.Id)
                )
                .Select(x => x.Id);
            q = q.Where(x =>
                (x.LessonId != null && lessonIds.Contains(x.LessonId))
                || (x.LiveSessionId != null && sessionIds.Contains(x.LiveSessionId))
            );
        }

        if (childId is not null)
            q = q.Where(x => x.ChildId == childId);
        return await q.OrderByDescending(x => x.CreatedAt)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
    }

    public async Task<object> FamilySubmissionBrowser(string childId, string? courseId,
        string? lessonId, bool unassigned, string? status, int page)
    {
        var child = await OwnChild(childId);
        var submissions = Q<DrawingSubmission>().Where(s => s.ChildId == childId);
        if (lessonId is not null || unassigned)
        {
            var title = "Tranh ngoài bài học";
            if (lessonId is not null)
                title = (await Get<Lesson>(lessonId)).Title;
            submissions = unassigned ? submissions.Where(s => s.LessonId == null)
                : submissions.Where(s => s.LessonId == lessonId);
            var totalCount = await submissions.CountAsync();
            if (status is not null)
            {
                Require(status is "pending_review" or "reviewed", "Invalid status.");
                submissions = submissions.Where(s => s.Status == status);
            }
            return new {
                title, childName = child.Nickname, totalCount,
                total = await submissions.CountAsync(),
                items = await submissions.OrderByDescending(s => s.CreatedAt).ThenBy(s => s.Id)
                    .Skip((Page(page) - 1) * 20).Take(20)
                    .Select(s => new { s.Id, s.CreatedAt, s.Status }).ToListAsync()
            };
        }
        if (courseId is not null)
        {
            var course = await Get<Course>(courseId);
            return new {
                title = course.Title, childName = child.Nickname,
                items = await Q<Lesson>().Where(l => l.CourseId == courseId).OrderBy(l => l.OrderIndex)
                    .Select(l => new { l.Id, l.Title, l.OrderIndex,
                        totalCount = submissions.Count(s => s.LessonId == l.Id),
                        pendingCount = submissions.Count(s => s.LessonId == l.Id && s.Status == "pending_review"),
                        reviewedCount = submissions.Count(s => s.LessonId == l.Id && s.Status == "reviewed")
                    }).ToListAsync()
            };
        }
        return new {
            childName = child.Nickname,
            unassignedCount = await submissions.CountAsync(s => s.LessonId == null),
            items = await Q<Course>()
                .Where(c => Q<Enrollment>().Any(e => e.ChildId == childId && e.CourseId == c.Id)
                    || submissions.Any(s => Q<Lesson>().Any(l => l.Id == s.LessonId && l.CourseId == c.Id)))
                .OrderBy(c => c.Title)
                .Select(c => new { c.Id, c.Title,
                    totalCount = submissions.Count(s => Q<Lesson>().Any(l => l.Id == s.LessonId && l.CourseId == c.Id)),
                    pendingCount = submissions.Count(s => s.Status == "pending_review" && Q<Lesson>().Any(l => l.Id == s.LessonId && l.CourseId == c.Id)),
                    reviewedCount = submissions.Count(s => s.Status == "reviewed" && Q<Lesson>().Any(l => l.Id == s.LessonId && l.CourseId == c.Id))
                }).ToListAsync()
        };
    }

    public Task<SubmissionReview> Review(string id, ReviewRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var s = await Get<DrawingSubmission>(id);
            await EnsureSubmissionAccess(s, true);
            var review = new SubmissionReview
            {
                SubmissionId = id,
                InstructorId = Actor.Id,
                Score = r.Score,
                Feedback = r.Feedback,
            };
            Add(review);
            s.Status = "reviewed";
            var child = await Get<ChildProfile>(s.ChildId);
            Notify(child.ParentId, "Bài vẽ đã được nhận xét", r.Feedback, id);
            return review;
        });
    }

    public async Task<object> Badges(string childId)
    {
        await OwnChild(childId);
        await RefreshBadges(childId);
        await Store.SaveAsync();
        var progress = await Q<ChildBadge>().Where(x => x.ChildId == childId).ToListAsync();
        return (await Q<Badge>().OrderBy(x => x.DisplayOrder).ToListAsync()).Select(b => new
        {
            badge = b,
            currentProgress = progress.FirstOrDefault(x => x.BadgeId == b.Id)?.CurrentProgress ?? 0,
            isUnlocked = progress.Any(x => x.BadgeId == b.Id && x.UnlockedAt != null),
            unlockedAt = progress.FirstOrDefault(x => x.BadgeId == b.Id)?.UnlockedAt,
        });
    }

    public async Task RefreshBadges(string childId)
    {
        var count = await Q<DrawingSubmission>().CountAsync(x => x.ChildId == childId);
        var enrollmentIds = Q<Enrollment>().Where(x => x.ChildId == childId).Select(x => x.Id);
        var lessons = await Q<LessonProgress>()
            .CountAsync(x => enrollmentIds.Contains(x.EnrollmentId) && x.Status == "completed");
        foreach (var b in await Q<Badge>().ToListAsync())
        {
            var cb = await Q<ChildBadge>()
                .SingleOrDefaultAsync(x => x.ChildId == childId && x.BadgeId == b.Id);
            if (cb is null)
            {
                cb = new ChildBadge { ChildId = childId, BadgeId = b.Id };
                Add(cb);
            }

            cb.CurrentProgress = Math.Min(b.MaxProgress, b.Metric == "lessons" ? lessons : count);
            if (cb.CurrentProgress >= b.MaxProgress)
                cb.UnlockedAt ??= DateTime.UtcNow;
        }

        // Derived from persisted work rather than awarding points on every retry/read.
        (await Get<ChildProfile>(childId)).TotalPoints = count * 10 + lessons * 5;
    }
}
