using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Common;

public sealed class BusinessException(int status, string message) : Exception(message)
{
    public int Status { get; } = status;
}

public interface ICurrentUser
{
    string Id { get; }

    string Role { get; }
}

public abstract class ServiceBase(IUnitOfWork store, ICurrentUser actor)
{
    protected readonly IUnitOfWork Store = store;
    protected readonly ICurrentUser Actor = actor;

    protected IQueryable<T> Q<T>()
        where T : Entity
    {
        return Store.Repository<T>().Query;
    }

    protected void Add<T>(T value)
        where T : Entity
    {
        Store.Repository<T>().Add(value);
    }

    protected void Remove<T>(T value)
        where T : Entity
    {
        Store.Repository<T>().Remove(value);
    }

    protected async Task<T> Get<T>(string id)
        where T : Entity
    {
        return await Store.Repository<T>().FindAsync(id)
            ?? throw new BusinessException(404, $"{typeof(T).Name} not found.");
    }

    protected static void Require(bool test, string message, int status = 400)
    {
        if (!test)
            throw new BusinessException(status, message);
    }

    protected void Roles(params string[] roles)
    {
        Require(roles.Contains(Actor.Role), "You do not have permission for this operation.", 403);
    }

    protected async Task<ChildProfile> OwnChild(string id)
    {
        var child = await Get<ChildProfile>(id);
        Require(Actor.Role == "admin" || child.ParentId == Actor.Id, "Child not found.", 404);
        return child;
    }

    protected async Task<Course> TeachCourse(string id)
    {
        Roles("admin", "instructor");
        var course = await Get<Course>(id);
        Require(
            !course.IsDeleted && (Actor.Role == "admin" || course.InstructorId == Actor.Id),
            "Course not found.",
            404
        );
        return course;
    }

    protected async Task RequireEnrollment(string childId, string courseId)
    {
        await OwnChild(childId);
        Require(
            await Q<Enrollment>().AnyAsync(x => x.ChildId == childId && x.CourseId == courseId),
            "The child is not enrolled in this course.",
            403
        );
        var enrollment = await Q<Enrollment>()
            .SingleAsync(x => x.ChildId == childId && x.CourseId == courseId);
        var course = await Get<Course>(courseId);
        if (course.PriceVnd > 0 && enrollment.OrderItemId is null && Actor.Role != "admin")
        {
            var child = await Get<ChildProfile>(childId);
            var now = DateTime.UtcNow;
            Require(
                await Q<Subscription>()
                    .AnyAsync(x =>
                        x.ParentId == child.ParentId
                        && (x.ChildId == null || x.ChildId == childId)
                        && x.Status == "active"
                        && x.StartsAt <= now
                        && x.EndsAt > now
                    ),
                "Subscription access has expired. Purchase the course or renew the subscription.",
                403
            );
        }
    }

    protected static int Page(int value)
    {
        return Math.Max(1, value);
    }

    protected static int Size(int value)
    {
        return Math.Clamp(value, 1, 100);
    }

    protected void Notify(string userId, string title, string message, string? reference = null)
    {
        Add(
            new Notification
            {
                UserId = userId,
                Title = title,
                Message = message,
                ReferenceId = reference,
            }
        );
    }
}
