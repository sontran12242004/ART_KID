using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class FamilyService(IUnitOfWork store, ICurrentUser actor) : ServiceBase(store, actor)
{
    public async Task<object> Children()
    {
        return await Q<ChildProfile>()
            .Where(x => x.ParentId == Actor.Id)
            .OrderBy(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<ChildProfile> Child(string id)
    {
        return await OwnChild(id);
    }

    public async Task<ChildProfile> SaveChild(string? id, ChildRequest r)
    {
        Roles("parent");
        Require(
            r.BirthYear <= DateTime.UtcNow.Year && r.BirthYear >= DateTime.UtcNow.Year - 18,
            "Birth year must describe a child aged 0–18."
        );
        if (r.AvatarPresetId is not null)
            await Get<AvatarPreset>(r.AvatarPresetId);
        var child = id is null ? new ChildProfile { ParentId = Actor.Id } : await OwnChild(id);
        child.Nickname = r.Nickname;
        child.BirthYear = r.BirthYear;
        child.AvatarPresetId = r.AvatarPresetId;
        child.Interests = r.Interests;
        if (id is null)
            Add(child);
        await Store.SaveAsync();
        return child;
    }

    public async Task<object> Avatars()
    {
        return await Q<AvatarPreset>().OrderBy(x => x.Name).ToListAsync();
    }

    public async Task<ParentalConsent> Consent(ConsentRequest r)
    {
        Roles("parent");
        await OwnChild(r.ChildId);
        var old = await Q<ParentalConsent>()
            .FirstOrDefaultAsync(x =>
                x.ParentId == Actor.Id
                && x.ChildId == r.ChildId
                && x.Purpose == r.Purpose
                && x.RevokedAt == null
            );
        if (old is not null)
            return old;
        var consent = new ParentalConsent
        {
            ParentId = Actor.Id,
            ChildId = r.ChildId,
            Purpose = r.Purpose,
            PolicyVersion = r.PolicyVersion,
        };
        Add(consent);
        var u = await Get<User>(Actor.Id);
        u.HasCompletedCoppaConsent = true;
        u.ParentalConsentAt = DateTime.UtcNow;
        await Store.SaveAsync();
        return consent;
    }

    public async Task<object> Consents(string childId)
    {
        await OwnChild(childId);
        return await Q<ParentalConsent>()
            .Where(x => x.ChildId == childId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task RevokeConsent(string id)
    {
        var row = await Get<ParentalConsent>(id);
        Require(row.ParentId == Actor.Id, "Consent not found.", 404);
        row.RevokedAt = DateTime.UtcNow;
        await Store.SaveAsync();
    }

    public async Task<object> Dashboard(string childId)
    {
        var child = await OwnChild(childId);
        var enrollments = await Q<Enrollment>()
            .Where(x => x.ChildId == childId)
            .Select(x => x.Id)
            .ToListAsync();
        return new
        {
            child,
            completedLessonsCount = await Q<LessonProgress>()
                .CountAsync(x => enrollments.Contains(x.EnrollmentId) && x.Status == "completed"),
            totalArtworksCount = await Q<DrawingSubmission>().CountAsync(x => x.ChildId == childId),
            totalBadgesCount = await Q<ChildBadge>()
                .CountAsync(x => x.ChildId == childId && x.UnlockedAt != null),
            learningSeconds = await Q<LessonProgress>()
                .Where(x => enrollments.Contains(x.EnrollmentId))
                .SumAsync(x => x.LearningSeconds),
            hasActiveSubscription = await Q<Subscription>()
                .AnyAsync(x =>
                    x.ParentId == child.ParentId
                    && x.Status == "active"
                    && x.StartsAt <= DateTime.UtcNow
                    && x.EndsAt > DateTime.UtcNow
                ),
        };
    }

    public async Task<object> Notifications(int page, int size)
    {
        return await Q<Notification>()
            .Where(x => x.UserId == Actor.Id)
            .OrderByDescending(x => x.CreatedAt)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();
    }

    public async Task ReadNotification(string id)
    {
        var n = await Get<Notification>(id);
        Require(n.UserId == Actor.Id, "Notification not found.", 404);
        n.ReadAt = DateTime.UtcNow;
        await Store.SaveAsync();
    }
}
