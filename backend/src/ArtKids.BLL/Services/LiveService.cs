using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class LiveService(IUnitOfWork store, ICurrentUser actor) : ServiceBase(store, actor)
{
    public async Task<object> Class(string id)
    {
        var cls = await Get<LiveClass>(id);
        return new
        {
            liveClass = cls,
            enrolledCount = await Q<LiveClassEnrollment>()
                .CountAsync(x => x.ClassId == id && x.Status == "enrolled"),
        };
    }

    public Task<LiveClass> UpdateClass(string id, LiveClassUpdateRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var cls = await TeachClass(id);
            Require(
                r.Capacity
                    >= await Q<LiveClassEnrollment>()
                        .CountAsync(x => x.ClassId == id && x.Status == "enrolled"),
                "Capacity cannot be lower than the current roster.",
                409
            );
            Require(
                cls.Status is not ("completed" or "cancelled") || cls.Status == r.Status,
                "A closed class cannot be reopened.",
                409
            );
            cls.Name = r.Name;
            cls.Capacity = r.Capacity;
            cls.Status = r.Status;
            return cls;
        });
    }

    public async Task<object> Classes(int page, int size)
    {
        return await Q<LiveClass>()
            .OrderBy(x => x.Name)
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .Select(x => new
            {
                x.Id,
                x.CourseId,
                x.InstructorId,
                x.Name,
                x.Capacity,
                x.Status,
                enrolledCount = Q<LiveClassEnrollment>()
                    .Count(e => e.ClassId == x.Id && e.Status == "enrolled"),
            })
            .ToListAsync();
    }

    public async Task<LiveClass> CreateClass(LiveClassRequest r)
    {
        await TeachCourse(r.CourseId);
        var teacher = Actor.Role == "admin" ? r.InstructorId ?? Actor.Id : Actor.Id;
        Require((await Get<User>(teacher)).Role is "instructor" or "admin", "Invalid teacher.");
        var c = new LiveClass
        {
            CourseId = r.CourseId,
            InstructorId = teacher,
            Name = r.Name,
            Capacity = r.Capacity,
        };
        Add(c);
        await Store.SaveAsync();
        return c;
    }

    private async Task<LiveClass> TeachClass(string id)
    {
        Roles("admin", "instructor");
        var c = await Get<LiveClass>(id);
        Require(Actor.Role == "admin" || c.InstructorId == Actor.Id, "Class not found.", 404);
        return c;
    }

    public Task<LiveClassEnrollment> Enroll(string id, ClassEnrollmentRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var cls = await Get<LiveClass>(id);
            await RequireEnrollment(r.ChildId, cls.CourseId);
            Require(cls.Status == "open", "Class is not open for enrollment.", 409);
            var old = await Q<LiveClassEnrollment>()
                .SingleOrDefaultAsync(x => x.ClassId == id && x.ChildId == r.ChildId);
            if (old?.Status == "enrolled")
                return old;
            Require(
                await Q<LiveClassEnrollment>()
                    .CountAsync(x => x.ClassId == id && x.Status == "enrolled") < cls.Capacity,
                "Class is full.",
                409
            );
            var e = old ?? new LiveClassEnrollment { ClassId = id, ChildId = r.ChildId };
            e.Status = "enrolled";
            if (old is null)
                Add(e);
            return e;
        });
    }

    public Task<bool> CancelEnrollment(string id, string childId)
    {
        return Store.TransactionAsync(async () =>
        {
            await OwnChild(childId);
            var e =
                await Q<LiveClassEnrollment>()
                    .SingleOrDefaultAsync(x => x.ClassId == id && x.ChildId == childId)
                ?? throw new BusinessException(404, "Class enrollment not found.");
            Require(
                !await Q<LiveSession>()
                    .AnyAsync(x =>
                        x.ClassId == id && (x.Status == "live" || x.Status == "completed")
                    ),
                "Cannot cancel after teaching has started.",
                409
            );
            e.Status = "cancelled";
            return true;
        });
    }

    public async Task<object> Roster(string id)
    {
        await TeachClass(id);
        return await (
            from e in Q<LiveClassEnrollment>()
            join c in Q<ChildProfile>() on e.ChildId equals c.Id
            where e.ClassId == id
            select new
            {
                enrollmentId = e.Id,
                e.ChildId,
                c.Nickname,
                e.Status,
                e.EnrolledAt,
            }
        ).ToListAsync();
    }

    public async Task<object> Sessions(string classId)
    {
        await Get<LiveClass>(classId);
        return await Q<LiveSession>()
            .Where(x => x.ClassId == classId)
            .OrderBy(x => x.StartsAt)
            .Select(x => new
            {
                x.Id,
                x.ClassId,
                x.LessonId,
                x.Title,
                x.StartsAt,
                x.EndsAt,
                x.Provider,
                x.Status,
            })
            .ToListAsync();
    }

    public Task<LiveSession> SaveSession(string classId, string? id, LiveSessionRequest r)
    {
        return Store.TransactionAsync(async () =>
        {
            var cls = await TeachClass(classId);
            Require(
                r.StartsAt.Kind == DateTimeKind.Utc
                    && r.EndsAt.Kind == DateTimeKind.Utc
                    && r.EndsAt > r.StartsAt,
                "Use UTC timestamps (Z); end must be after start."
            );
            if (r.LessonId is not null)
                Require(
                    (await Get<Lesson>(r.LessonId)).CourseId == cls.CourseId,
                    "Lesson belongs to a different course."
                );
            if (r.RoomUrl is not null)
                Require(
                    Uri.TryCreate(r.RoomUrl, UriKind.Absolute, out var uri)
                        && uri.Scheme == "https",
                    "Room URL must use HTTPS."
                );
            var conflictingClassIds = Q<LiveClass>()
                .Where(c => c.InstructorId == cls.InstructorId)
                .Select(c => c.Id);
            Require(
                !await Q<LiveSession>()
                    .AnyAsync(x =>
                        conflictingClassIds.Contains(x.ClassId)
                        && x.Id != id
                        && x.Status != "cancelled"
                        && x.StartsAt < r.EndsAt
                        && x.EndsAt > r.StartsAt
                    ),
                "Instructor already has a session at this time.",
                409
            );
            var s = id is null ? new LiveSession { ClassId = classId } : await Get<LiveSession>(id);
            Require(
                s.ClassId == classId && s.Status == "scheduled",
                "Only scheduled sessions can be edited.",
                409
            );
            s.Title = r.Title;
            s.StartsAt = r.StartsAt;
            s.EndsAt = r.EndsAt;
            s.LessonId = r.LessonId;
            s.RoomUrl = r.RoomUrl;
            s.Provider = r.Provider;
            if (id is null)
                Add(s);
            return s;
        });
    }

    public async Task<LiveSession> SetState(string id, SessionStateRequest r)
    {
        var s = await Get<LiveSession>(id);
        await TeachClass(s.ClassId);
        Require(
            (s.Status == "scheduled" && (r.Status is "live" or "cancelled"))
                || (s.Status == "live" && (r.Status is "completed" or "cancelled"))
                || s.Status == r.Status,
            "Invalid session state transition.",
            409
        );
        if (r.RecordingUrl is not null)
            Require(
                Uri.TryCreate(r.RecordingUrl, UriKind.Absolute, out var uri)
                    && uri.Scheme == "https",
                "Recording URL must use HTTPS."
            );
        s.Status = r.Status;
        s.RecordingUrl = r.RecordingUrl;
        await Store.SaveAsync();
        return s;
    }

    public Task<object> Join(string id, string? childId)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var s = await Get<LiveSession>(id);
            var cls = await Get<LiveClass>(s.ClassId);
            Require(cls.Status is "open" or "active", "This class is closed.", 409);
            Require(
                s.EndsAt > DateTime.UtcNow
                    && (
                        s.Status == "live"
                        || (s.Status == "scheduled" && s.StartsAt <= DateTime.UtcNow.AddMinutes(15))
                    ),
                "This session is not open.",
                409
            );
            Require(
                !string.IsNullOrWhiteSpace(s.RoomUrl),
                "The instructor has not configured the external live room.",
                503
            );
            if (Actor.Role == "admin" || cls.InstructorId == Actor.Id)
                return new
                {
                    sessionId = id,
                    joinUrl = s.RoomUrl,
                    role = "instructor",
                };
            Require(childId is not null, "childId is required.");
            await RequireEnrollment(childId!, cls.CourseId);
            var e =
                await Q<LiveClassEnrollment>()
                    .SingleOrDefaultAsync(x =>
                        x.ClassId == s.ClassId && x.ChildId == childId && x.Status == "enrolled"
                    )
                ?? throw new BusinessException(403, "Child is not enrolled.");
            var a = await Q<LiveSessionAttendance>()
                .SingleOrDefaultAsync(x => x.SessionId == id && x.ClassEnrollmentId == e.Id);
            if (a is null)
            {
                a = new LiveSessionAttendance
                {
                    SessionId = id,
                    ClassEnrollmentId = e.Id,
                    FirstJoinedAt = DateTime.UtcNow,
                };
                Add(a);
            }

            a.LastJoinedAt ??= DateTime.UtcNow;
            return new
            {
                sessionId = id,
                joinUrl = s.RoomUrl,
                attendanceId = a.Id,
                role = "student",
            };
        });
    }

    public Task<bool> Leave(string id, string childId)
    {
        return Store.TransactionAsync(async () =>
        {
            await OwnChild(childId);
            var s = await Get<LiveSession>(id);
            var e =
                await Q<LiveClassEnrollment>()
                    .SingleOrDefaultAsync(x => x.ClassId == s.ClassId && x.ChildId == childId)
                ?? throw new BusinessException(404, "Enrollment not found.");
            var a =
                await Q<LiveSessionAttendance>()
                    .SingleOrDefaultAsync(x => x.SessionId == id && x.ClassEnrollmentId == e.Id)
                ?? throw new BusinessException(404, "Attendance not found.");
            if (a.LastJoinedAt is not null)
            {
                var end = DateTime.UtcNow < s.EndsAt ? DateTime.UtcNow : s.EndsAt;
                a.TotalDurationSeconds += Math.Max(
                    0,
                    (int)(end - a.LastJoinedAt.Value).TotalSeconds
                );
                a.LastLeftAt = end;
                a.LastJoinedAt = null;
            }

            return true;
        });
    }

    public async Task<object> Attendance(string id)
    {
        var s = await Get<LiveSession>(id);
        await TeachClass(s.ClassId);
        return await Q<LiveSessionAttendance>().Where(x => x.SessionId == id).ToListAsync();
    }
}
