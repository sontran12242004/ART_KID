using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace ArtKids.BLL.Services;

public sealed class LiveService(
    IUnitOfWork store,
    ICurrentUser actor,
    IConfiguration? config = null
) : ServiceBase(store, actor)
{
    private static readonly ConcurrentDictionary<string, InAppRoomSessionState> Rooms = new();
    private static readonly ConcurrentDictionary<string, DateTime> ProcessedWebhookIds = new();

    private sealed class InAppParticipantConnection
    {
        public required string Identity { get; init; }
        public required string DisplayName { get; init; }
        public required string Role { get; init; }
        public string? ChildId { get; init; }
        public HashSet<string> ActiveDeviceIds { get; } = [];
        public bool MicEnabled { get; set; } = true;
        public bool CameraEnabled { get; set; } = true;
        public string CameraFacing { get; set; } = "front";
        public bool AudioOnly { get; set; }
        public bool IsReconnecting { get; set; }
        public bool MuteRequestedByInstructor { get; set; }
        public bool ScreenSharing { get; set; }
        public bool ScreenShareRevokedNotificationPending { get; set; }
        public DateTime FirstConnectedAt { get; set; } = DateTime.UtcNow;
        public DateTime LastSeenAt { get; set; } = DateTime.UtcNow;
        public long LastWebhookTimestamp { get; set; }
    }

    private sealed class InAppActiveScreenShare
    {
        public required string PresenterIdentity { get; init; }
        public required string PresenterName { get; init; }
        public required string PresenterRole { get; init; }
        public string Scope { get; set; } = "entire_screen";
        public string? ContentLabel { get; set; }
        public bool IncludeDeviceAudio { get; set; }
        public int Width { get; set; } = 1080;
        public int Height { get; set; } = 1920;
        public double AspectRatio => Height > 0 ? Math.Round((double)Width / Height, 4) : 0.5625;
        public string? FrameBase64 { get; set; }
        public long Sequence { get; set; }
        public DateTime StartedAt { get; init; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    private sealed class InAppRoomSessionState
    {
        public object SyncRoot { get; } = new();
        public required string SessionId { get; init; }
        public required string RoomName { get; init; }
        public int RoomVersion { get; set; } = 1;
        public bool IsClosed { get; set; }
        public DateTime? ClosedAt { get; set; }
        public Dictionary<string, InAppParticipantConnection> Participants { get; } = [];
        public HashSet<string> GrantedScreenShareIdentities { get; } = [];
        public InAppActiveScreenShare? ActiveScreenShare { get; set; }
        public long ScreenShareSequence { get; set; }
    }

    private static bool CanParticipantShareScreen(
        InAppRoomSessionState roomState,
        string identity,
        string role
    ) =>
        role is "instructor" or "admin"
        || roomState.GrantedScreenShareIdentities.Contains(identity);

    public static string ResolveRoomName(string sessionId) => $"artkids-session-{sessionId}";

    public static string ResolveInAppRoomUri(string sessionId) =>
        $"https://in-app.artkids.local/rooms/{ResolveRoomName(sessionId)}";

    private static InAppRoomSessionState GetOrCreateRoomState(string sessionId) =>
        Rooms.GetOrAdd(
            sessionId,
            id => new InAppRoomSessionState
            {
                SessionId = id,
                RoomName = ResolveRoomName(id),
            }
        );

    public static string ResolveEffectiveStatus(
        string sessionStatus,
        string classStatus,
        DateTime startsAt,
        DateTime endsAt,
        DateTime now
    )
    {
        if (sessionStatus == "cancelled" || classStatus == "cancelled")
            return "cancelled";
        if (sessionStatus == "completed" || classStatus == "completed" || endsAt <= now)
            return "completed";
        if (
            sessionStatus == "live"
            || (sessionStatus == "scheduled" && startsAt <= now && endsAt > now)
        )
            return "live";
        return "scheduled";
    }

    public static string ResolveFilterGroup(string effectiveStatus) =>
        effectiveStatus switch
        {
            "live" => "live",
            "scheduled" => "upcoming",
            _ => "ended",
        };

    public static string ResolveProviderLabel(string? provider, string? roomUrl)
    {
        var p = (provider ?? "").Trim().ToLowerInvariant();
        if (p is "livekit" or "in_app" or "webrtc" or "" or "external")
            return "Phòng học trực tiếp trong ứng dụng";
        if (p.Contains("zoom"))
            return "Phòng học trong ứng dụng (WebRTC)";
        if (p.Contains("meet") || p.Contains("google"))
            return "Phòng học trong ứng dụng (WebRTC)";
        if (p.Contains("teams") || p.Contains("microsoft"))
            return "Phòng học trong ứng dụng (WebRTC)";
        return "Phòng học trực tiếp trong ứng dụng";
    }

    public static (bool CanJoin, string? BlockedReason) EvaluateJoinEligibility(
        string sessionStatus,
        string classStatus,
        DateTime startsAt,
        DateTime endsAt,
        bool hasRoomUrl,
        bool isAuthorizedMember,
        DateTime now,
        bool isStaff = false
    )
    {
        if (!isAuthorizedMember)
            return (
                false,
                isStaff
                    ? "Bạn không được phân công phụ trách lớp học trực tuyến này."
                    : "Bé chưa đăng ký vào lớp học trực tuyến này."
            );
        if (sessionStatus == "cancelled" || classStatus == "cancelled")
            return (false, "Buổi học này đã bị hủy.");
        if (classStatus is not ("open" or "active"))
            return (false, "Lớp học đã kết thúc hoặc đóng cổng tham gia.");
        if (sessionStatus == "completed" || endsAt <= now)
            return (false, "Buổi học đã kết thúc.");
        var withinWindow =
            sessionStatus == "live"
            || (sessionStatus == "scheduled" && startsAt <= now.AddMinutes(15));
        if (!withinWindow)
            return (
                false,
                isStaff
                    ? "Chưa đến khung giờ mở phòng (15 phút trước giờ học). Bạn có thể bấm \"Bắt đầu buổi học\" khi sẵn sàng dạy."
                    : "Chưa đến giờ vào lớp. Phòng học trong ứng dụng sẽ mở trước giờ bắt đầu 15 phút."
            );
        if (!hasRoomUrl)
            return (
                false,
                isStaff
                    ? "Phòng học trực tuyến chưa được kích hoạt."
                    : "Phòng học trực tuyến đang chờ giáo viên kích hoạt."
            );
        return (true, null);
    }

    private (bool IsConfigured, string? Url, string? ApiKey, string? ApiSecret, List<string> MissingKeys) GetLiveKitConfig()
    {
        var url = config?["LiveKit:Url"]?.Trim();
        var apiKey = config?["LiveKit:ApiKey"]?.Trim();
        var apiSecret = config?["LiveKit:ApiSecret"]?.Trim();
        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(url))
            missing.Add("LiveKit:Url");
        if (string.IsNullOrWhiteSpace(apiKey))
            missing.Add("LiveKit:ApiKey");
        if (string.IsNullOrWhiteSpace(apiSecret) || Encoding.UTF8.GetByteCount(apiSecret) < 16)
            missing.Add("LiveKit:ApiSecret");
        return (missing.Count == 0, url, apiKey, apiSecret, missing);
    }

    private byte[] GetRoomSigningKeyBytes()
    {
        var raw = config?["Jwt:Key"] ?? "ArtKids-Default-Room-Signing-Key-2026-Secure-32B!";
        var bytes = Encoding.UTF8.GetBytes(raw);
        if (bytes.Length >= 32)
            return bytes;
        return SHA256.HashData(bytes);
    }

    private string CreateInternalRoomToken(
        string sessionId,
        string roomName,
        string participantIdentity,
        string participantName,
        string participantRole,
        string? childId,
        int roomVersion,
        DateTime expiresAt
    )
    {
        var now = DateTime.UtcNow;
        var utcExpires = DateTime.SpecifyKind(expiresAt, DateTimeKind.Utc);
        var key = new SymmetricSecurityKey(GetRoomSigningKeyBytes());
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, participantIdentity),
            new(JwtRegisteredClaimNames.Name, participantName),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new("sid", sessionId),
            new("room", roomName),
            new("role", participantRole),
            new("ver", roomVersion.ToString()),
        };
        if (!string.IsNullOrWhiteSpace(childId))
            claims.Add(new Claim("childId", childId));

        var token = new JwtSecurityToken(
            issuer: "artkids-live-room",
            audience: "artkids-in-app-classroom",
            claims: claims,
            notBefore: now.AddSeconds(-15),
            expires: utcExpires,
            signingCredentials: creds
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private ClaimsPrincipal ValidateInternalRoomToken(string roomToken, string expectedSessionId, int currentRoomVersion)
    {
        var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
        try
        {
            var principal = handler.ValidateToken(
                roomToken,
                new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = "artkids-live-room",
                    ValidateAudience = true,
                    ValidAudience = "artkids-in-app-classroom",
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(GetRoomSigningKeyBytes()),
                    ClockSkew = TimeSpan.FromSeconds(15),
                },
                out _
            );
            var sid = principal.FindFirstValue("sid");
            var ver = principal.FindFirstValue("ver");
            Require(sid == expectedSessionId, "Token phòng học không thuộc buổi học này.", 403);
            Require(
                ver == currentRoomVersion.ToString(),
                "Phiên phòng học đã kết thúc hoặc token đã bị thu hồi. Không thể sử dụng lại token cũ.",
                409
            );
            return principal;
        }
        catch (SecurityTokenExpiredException)
        {
            throw new BusinessException(403, "Token vào phòng học đã hết hạn. Vui lòng lấy lại quyền vào phòng.");
        }
        catch (BusinessException)
        {
            throw;
        }
        catch
        {
            throw new BusinessException(403, "Token vào phòng học không hợp lệ.");
        }
    }

    private static string CreateLiveKitJwtToken(
        string apiKey,
        string apiSecret,
        string roomName,
        string participantIdentity,
        string participantName,
        bool isInstructor,
        bool canShareScreen,
        DateTime expiresAt
    )
    {
        var nowOffset = DateTimeOffset.UtcNow;
        var expOffset = new DateTimeOffset(DateTime.SpecifyKind(expiresAt, DateTimeKind.Utc));
        var headerJson = JsonSerializer.Serialize(new { alg = "HS256", typ = "JWT" });
        var publishSources = canShareScreen
            ? new[] { "camera", "microphone", "screen_share", "screen_share_audio" }
            : new[] { "camera", "microphone" };
        var payloadObj = new Dictionary<string, object?>
        {
            ["iss"] = apiKey,
            ["sub"] = participantIdentity,
            ["name"] = participantName,
            ["jti"] = Guid.NewGuid().ToString("N"),
            ["nbf"] = nowOffset.ToUnixTimeSeconds(),
            ["exp"] = expOffset.ToUnixTimeSeconds(),
            ["metadata"] = JsonSerializer.Serialize(
                new
                {
                    role = isInstructor ? "instructor" : "student",
                    canShareScreen,
                }
            ),
            ["video"] = new Dictionary<string, object>
            {
                ["roomJoin"] = true,
                ["room"] = roomName,
                ["roomAdmin"] = isInstructor,
                ["canPublish"] = true,
                ["canPublishSources"] = publishSources,
                ["canSubscribe"] = true,
                ["canPublishData"] = true,
            },
        };
        var payloadJson = JsonSerializer.Serialize(payloadObj);
        var encodedHeader = Base64UrlEncoder.Encode(Encoding.UTF8.GetBytes(headerJson));
        var encodedPayload = Base64UrlEncoder.Encode(Encoding.UTF8.GetBytes(payloadJson));
        var unsignedToken = $"{encodedHeader}.{encodedPayload}";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(apiSecret));
        var signature = Base64UrlEncoder.Encode(
            hmac.ComputeHash(Encoding.UTF8.GetBytes(unsignedToken))
        );
        return $"{unsignedToken}.{signature}";
    }

    private async Task<HashSet<string>> GetValidCourseIdsForChildren(List<string> childIds)
    {
        if (childIds.Count == 0)
            return [];
        var enrollments = await (
            from e in Q<Enrollment>()
            join c in Q<Course>() on e.CourseId equals c.Id
            where childIds.Contains(e.ChildId)
            select new
            {
                e.ChildId,
                e.CourseId,
                e.OrderItemId,
                c.PriceVnd,
            }
        ).ToListAsync();
        if (enrollments.Count == 0)
            return [];
        var now = DateTime.UtcNow;
        var activeSubs = await Q<Subscription>()
            .Where(x =>
                x.ParentId == Actor.Id
                && x.Status == "active"
                && x.StartsAt <= now
                && x.EndsAt > now
            )
            .Select(x => x.ChildId)
            .ToListAsync();
        var hasFamilySub = activeSubs.Any(x => x == null);
        var subChildIds = activeSubs.Where(x => x != null).Select(x => x!).ToHashSet();
        var validPairs = new HashSet<string>();
        foreach (var e in enrollments)
        {
            if (
                e.PriceVnd <= 0
                || e.OrderItemId != null
                || hasFamilySub
                || subChildIds.Contains(e.ChildId)
            )
            {
                validPairs.Add($"{e.ChildId}:{e.CourseId}");
            }
        }
        return validPairs;
    }

    public async Task<object> Class(string id)
    {
        var cls = await Get<LiveClass>(id);
        Require(
            Actor.Role != "instructor" || cls.InstructorId == Actor.Id,
            "Class not found.",
            404
        );
        var course = await Q<Course>().SingleOrDefaultAsync(x => x.Id == cls.CourseId);
        var instructor = await Q<User>().SingleOrDefaultAsync(x => x.Id == cls.InstructorId);
        return new
        {
            liveClass = cls,
            courseTitle = course?.Title ?? "",
            courseDescription = course?.Description ?? "",
            instructorName = instructor?.FullName ?? "Giáo viên ArtKids",
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

    public async Task<object> Classes(int page, int size, string? childId = null)
    {
        string? verifiedChildId = null;
        if (Actor.Role == "parent" && !string.IsNullOrWhiteSpace(childId))
        {
            await OwnChild(childId);
            verifiedChildId = childId;
        }

        var rows = await (
            from x in Q<LiveClass>()
            join c in Q<Course>() on x.CourseId equals c.Id into courseJoin
            from course in courseJoin.DefaultIfEmpty()
            join u in Q<User>() on x.InstructorId equals u.Id into userJoin
            from instructor in userJoin.DefaultIfEmpty()
            where Actor.Role != "instructor" || x.InstructorId == Actor.Id
            orderby x.Name
            select new
            {
                x.Id,
                x.CourseId,
                courseTitle = course != null ? course.Title : "",
                courseDescription = course != null ? course.Description : "",
                x.InstructorId,
                instructorName = instructor != null ? instructor.FullName : "Giáo viên ArtKids",
                x.Name,
                x.Capacity,
                x.Status,
                enrolledCount = Q<LiveClassEnrollment>()
                    .Count(e => e.ClassId == x.Id && e.Status == "enrolled"),
                sessionCount = Q<LiveSession>().Count(s => s.ClassId == x.Id),
                isEnrolled = verifiedChildId != null
                    && Q<LiveClassEnrollment>()
                        .Any(e =>
                            e.ClassId == x.Id
                            && e.ChildId == verifiedChildId
                            && e.Status == "enrolled"
                        ),
                isCourseEnrolled = verifiedChildId != null
                    && Q<Enrollment>()
                        .Any(e => e.CourseId == x.CourseId && e.ChildId == verifiedChildId),
            }
        )
            .Skip((Page(page) - 1) * Size(size))
            .Take(Size(size))
            .ToListAsync();

        return rows;
    }

    public async Task<object> AccessibleSessions(
        string? status,
        string? childId,
        string? classId,
        int page,
        int size
    )
    {
        var normalizedFilter = string.IsNullOrWhiteSpace(status)
            ? null
            : status.Trim().ToLowerInvariant();
        Require(
            normalizedFilter is null or "all" or "upcoming" or "live" or "ended" or "cancelled",
            "Bộ lọc trạng thái buổi học không hợp lệ."
        );

        var now = DateTime.UtcNow;
        var isStaff = Actor.Role is "instructor" or "admin";
        var (sfuConfigured, _, _, _, _) = GetLiveKitConfig();
        HashSet<string>? accessibleClassIds = null;
        Dictionary<string, List<(string ChildId, string Nickname)>> classChildrenMap = [];

        if (Actor.Role == "parent")
        {
            List<ChildProfile> children;
            if (!string.IsNullOrWhiteSpace(childId))
            {
                var child = await OwnChild(childId);
                children = [child];
            }
            else
            {
                children = await Q<ChildProfile>()
                    .Where(c => c.ParentId == Actor.Id)
                    .OrderBy(c => c.CreatedAt)
                    .ToListAsync();
            }

            var childIds = children.Select(c => c.Id).ToList();
            var childNames = children.ToDictionary(c => c.Id, c => c.Nickname);
            var validCoursePairs = await GetValidCourseIdsForChildren(childIds);

            var classEnrollments = await (
                from ce in Q<LiveClassEnrollment>()
                join cls in Q<LiveClass>() on ce.ClassId equals cls.Id
                where childIds.Contains(ce.ChildId) && ce.Status == "enrolled"
                select new
                {
                    ce.ClassId,
                    ce.ChildId,
                    cls.CourseId,
                }
            ).ToListAsync();

            accessibleClassIds = [];
            foreach (var ce in classEnrollments)
            {
                if (validCoursePairs.Contains($"{ce.ChildId}:{ce.CourseId}"))
                {
                    accessibleClassIds.Add(ce.ClassId);
                    if (!classChildrenMap.TryGetValue(ce.ClassId, out var list))
                    {
                        list = [];
                        classChildrenMap[ce.ClassId] = list;
                    }
                    list.Add((ce.ChildId, childNames.GetValueOrDefault(ce.ChildId, "")));
                }
            }
        }
        else if (Actor.Role == "instructor")
        {
            if (!string.IsNullOrWhiteSpace(classId))
            {
                await TeachClass(classId);
            }
            accessibleClassIds = (
                await Q<LiveClass>()
                    .Where(c => c.InstructorId == Actor.Id)
                    .Select(c => c.Id)
                    .ToListAsync()
            ).ToHashSet();
        }

        var query =
            from s in Q<LiveSession>()
            join cls in Q<LiveClass>() on s.ClassId equals cls.Id
            join c in Q<Course>() on cls.CourseId equals c.Id into courseJoin
            from course in courseJoin.DefaultIfEmpty()
            join u in Q<User>() on cls.InstructorId equals u.Id into userJoin
            from instructor in userJoin.DefaultIfEmpty()
            join l in Q<Lesson>() on s.LessonId equals l.Id into lessonJoin
            from lesson in lessonJoin.DefaultIfEmpty()
            select new
            {
                Session = s,
                Class = cls,
                CourseTitle = course != null ? course.Title : "",
                CourseDescription = course != null ? course.Description : "",
                InstructorName = instructor != null ? instructor.FullName : "Giáo viên ArtKids",
                LessonTitle = lesson != null ? lesson.Title : null,
                LessonPracticeInstructions = lesson != null ? lesson.PracticeInstructions : null,
            };

        if (accessibleClassIds is not null)
        {
            query = query.Where(x => accessibleClassIds.Contains(x.Class.Id));
        }
        if (!string.IsNullOrWhiteSpace(classId))
        {
            query = query.Where(x => x.Class.Id == classId);
        }

        var rawItems = await query.ToListAsync();
        var rawClassIds = rawItems.Select(x => x.Class.Id).Distinct().ToList();

        Dictionary<string, List<string>> rosterNamesByClass = [];
        Dictionary<string, int> enrolledCountsByClass = [];
        if (rawClassIds.Count > 0)
        {
            var enrollmentsWithNames = await (
                from ce in Q<LiveClassEnrollment>()
                join ch in Q<ChildProfile>() on ce.ChildId equals ch.Id
                where rawClassIds.Contains(ce.ClassId) && ce.Status == "enrolled"
                orderby ce.EnrolledAt
                select new { ce.ClassId, ch.Nickname }
            ).ToListAsync();

            foreach (var group in enrollmentsWithNames.GroupBy(x => x.ClassId))
            {
                enrolledCountsByClass[group.Key] = group.Count();
                if (isStaff)
                {
                    rosterNamesByClass[group.Key] = group.Select(x => x.Nickname).ToList();
                }
            }
        }

        var projected = rawItems
            .Select(x =>
            {
                var effectiveStatus = ResolveEffectiveStatus(
                    x.Session.Status,
                    x.Class.Status,
                    x.Session.StartsAt,
                    x.Session.EndsAt,
                    now
                );
                var filterGroup = ResolveFilterGroup(effectiveStatus);
                var roomName = ResolveRoomName(x.Session.Id);
                var (canJoin, blockedReason) = EvaluateJoinEligibility(
                    x.Session.Status,
                    x.Class.Status,
                    x.Session.StartsAt,
                    x.Session.EndsAt,
                    hasRoomUrl: true,
                    isAuthorizedMember: true,
                    now,
                    isStaff: isStaff
                );
                var enrolledChildren = classChildrenMap.TryGetValue(x.Class.Id, out var kids)
                    ? kids
                    : [];
                var primaryChildId = enrolledChildren.FirstOrDefault().ChildId;
                var primaryChildName = enrolledChildren.FirstOrDefault().Nickname;
                var enrolledCount = enrolledCountsByClass.GetValueOrDefault(x.Class.Id, 0);
                var studentNames = isStaff
                    ? rosterNamesByClass.GetValueOrDefault(x.Class.Id, [])
                    : [];
                var isClassOpen = x.Class.Status is "open" or "active";

                return new
                {
                    id = x.Session.Id,
                    classId = x.Class.Id,
                    className = x.Class.Name,
                    classStatus = x.Class.Status,
                    capacity = x.Class.Capacity,
                    enrolledCount,
                    enrolledStudentNames = studentNames,
                    courseId = x.Class.CourseId,
                    courseTitle = x.CourseTitle,
                    courseDescription = x.CourseDescription,
                    instructorId = x.Class.InstructorId,
                    instructorName = x.InstructorName,
                    lessonId = x.Session.LessonId,
                    lessonTitle = x.LessonTitle,
                    practiceInstructions = x.LessonPracticeInstructions,
                    title = x.Session.Title,
                    startsAt = x.Session.StartsAt,
                    endsAt = x.Session.EndsAt,
                    opensAt = x.Session.StartsAt.AddMinutes(-15),
                    provider = "livekit",
                    providerLabel = ResolveProviderLabel(x.Session.Provider, x.Session.RoomUrl),
                    roomName,
                    inAppRoom = true,
                    sfuConfigured,
                    status = x.Session.Status,
                    effectiveStatus,
                    filterGroup,
                    hasRoomUrl = true,
                    canJoin,
                    joinBlockedReason = blockedReason,
                    canStartSession = isStaff
                        && isClassOpen
                        && x.Session.Status == "scheduled"
                        && x.Session.EndsAt > now,
                    canEndSession = isStaff && x.Session.Status == "live",
                    canCancelSession = isStaff && x.Session.Status is "scheduled" or "live",
                    canEditSession = isStaff && x.Session.Status == "scheduled",
                    recordingUrl = effectiveStatus == "completed" ? x.Session.RecordingUrl : null,
                    childId = primaryChildId,
                    childNickname = primaryChildName,
                };
            })
            .ToList();

        var counts = new
        {
            all = projected.Count,
            upcoming = projected.Count(x => x.filterGroup == "upcoming"),
            live = projected.Count(x => x.filterGroup == "live"),
            ended = projected.Count(x => x.filterGroup == "ended"),
            cancelled = projected.Count(x => x.effectiveStatus == "cancelled"),
        };

        var filtered = normalizedFilter switch
        {
            null or "all" => projected,
            "cancelled" => projected.Where(x => x.effectiveStatus == "cancelled").ToList(),
            _ => projected.Where(x => x.filterGroup == normalizedFilter).ToList(),
        };

        var ordered =
            normalizedFilter is "ended" or "cancelled"
                ? filtered.OrderByDescending(x => x.startsAt).ToList()
                : filtered
                    .OrderBy(x =>
                        x.effectiveStatus switch
                        {
                            "live" => 0,
                            "scheduled" => 1,
                            "completed" => 2,
                            _ => 3,
                        }
                    )
                    .ThenBy(x =>
                        x.effectiveStatus is "live" or "scheduled"
                            ? x.startsAt.Ticks
                            : -x.startsAt.Ticks
                    )
                    .ToList();

        var total = ordered.Count;
        var p = Page(page);
        var sSize = Size(size);
        var paged = ordered.Skip((p - 1) * sSize).Take(sSize).ToList();

        return new
        {
            items = paged,
            page = p,
            pageSize = sSize,
            total,
            counts,
        };
    }

    public async Task<object> SessionDetail(string id, string? childId = null)
    {
        var s = await Get<LiveSession>(id);
        var cls = await Get<LiveClass>(s.ClassId);
        var isStaff = Actor.Role is "instructor" or "admin";
        var (sfuConfigured, _, _, _, missingKeys) = GetLiveKitConfig();

        string? resolvedChildId = null;
        string? resolvedChildName = null;
        LiveClassEnrollment? enrollment = null;

        if (Actor.Role == "instructor")
        {
            Require(cls.InstructorId == Actor.Id, "Session not found.", 404);
        }
        else if (Actor.Role == "parent")
        {
            if (!string.IsNullOrWhiteSpace(childId))
            {
                var child = await OwnChild(childId);
                await RequireEnrollment(child.Id, cls.CourseId);
                enrollment =
                    await Q<LiveClassEnrollment>()
                        .SingleOrDefaultAsync(x =>
                            x.ClassId == cls.Id && x.ChildId == child.Id && x.Status == "enrolled"
                        )
                    ?? throw new BusinessException(
                        403,
                        "Bé chưa đăng ký tham gia lớp học trực tuyến này."
                    );
                resolvedChildId = child.Id;
                resolvedChildName = child.Nickname;
            }
            else
            {
                var parentChildren = await Q<ChildProfile>()
                    .Where(c => c.ParentId == Actor.Id)
                    .OrderBy(c => c.CreatedAt)
                    .ToListAsync();
                var parentChildIds = parentChildren.Select(c => c.Id).ToList();
                enrollment =
                    await Q<LiveClassEnrollment>()
                        .Where(x =>
                            x.ClassId == cls.Id
                            && parentChildIds.Contains(x.ChildId)
                            && x.Status == "enrolled"
                        )
                        .OrderBy(x => x.EnrolledAt)
                        .FirstOrDefaultAsync()
                    ?? throw new BusinessException(
                        403,
                        "Bé chưa đăng ký tham gia lớp học trực tuyến này."
                    );
                await RequireEnrollment(enrollment.ChildId, cls.CourseId);
                var matchedChild = parentChildren.First(c => c.Id == enrollment.ChildId);
                resolvedChildId = matchedChild.Id;
                resolvedChildName = matchedChild.Nickname;
            }
        }

        var now = DateTime.UtcNow;
        var course = await Q<Course>().SingleOrDefaultAsync(x => x.Id == cls.CourseId);
        var instructor = await Q<User>().SingleOrDefaultAsync(x => x.Id == cls.InstructorId);
        var lesson =
            s.LessonId is null
                ? null
                : await Q<Lesson>().SingleOrDefaultAsync(x => x.Id == s.LessonId);
        var enrolledCount = await Q<LiveClassEnrollment>()
            .CountAsync(x => x.ClassId == cls.Id && x.Status == "enrolled");

        var effectiveStatus = ResolveEffectiveStatus(
            s.Status,
            cls.Status,
            s.StartsAt,
            s.EndsAt,
            now
        );
        var filterGroup = ResolveFilterGroup(effectiveStatus);
        var roomName = ResolveRoomName(s.Id);
        var (canJoin, blockedReason) = EvaluateJoinEligibility(
            s.Status,
            cls.Status,
            s.StartsAt,
            s.EndsAt,
            hasRoomUrl: true,
            isAuthorizedMember: true,
            now,
            isStaff: isStaff
        );

        LiveSessionAttendance? attendance = null;
        if (enrollment is not null)
        {
            attendance = await Q<LiveSessionAttendance>()
                .SingleOrDefaultAsync(x =>
                    x.SessionId == s.Id && x.ClassEnrollmentId == enrollment.Id
                );
        }

        object? rosterWithAttendance = null;
        object? courseLessons = null;
        if (isStaff)
        {
            var rawRoster = await (
                from ce in Q<LiveClassEnrollment>()
                join ch in Q<ChildProfile>() on ce.ChildId equals ch.Id
                where ce.ClassId == cls.Id && ce.Status == "enrolled"
                orderby ce.EnrolledAt
                select new
                {
                    enrollmentId = ce.Id,
                    childId = ce.ChildId,
                    nickname = ch.Nickname,
                    status = ce.Status,
                    enrolledAt = ce.EnrolledAt,
                }
            ).ToListAsync();

            var sessionAttendances = await Q<LiveSessionAttendance>()
                .Where(a => a.SessionId == s.Id)
                .ToListAsync();
            var attendanceByEnrollment = sessionAttendances.ToDictionary(
                a => a.ClassEnrollmentId,
                a => a
            );

            rosterWithAttendance = rawRoster
                .Select(r =>
                {
                    attendanceByEnrollment.TryGetValue(r.enrollmentId, out var att);
                    return new
                    {
                        r.enrollmentId,
                        r.childId,
                        r.nickname,
                        r.status,
                        r.enrolledAt,
                        attended = att?.FirstJoinedAt != null,
                        isCurrentlyInRoom = att?.LastJoinedAt != null,
                        firstJoinedAt = att?.FirstJoinedAt,
                        lastJoinedAt = att?.LastJoinedAt,
                        lastLeftAt = att?.LastLeftAt,
                        totalDurationSeconds = att?.TotalDurationSeconds ?? 0,
                    };
                })
                .ToList();

            courseLessons = await Q<Lesson>()
                .Where(l => l.CourseId == cls.CourseId)
                .OrderBy(l => l.OrderIndex)
                .Select(l => new
                {
                    id = l.Id,
                    title = l.Title,
                    orderIndex = l.OrderIndex,
                })
                .ToListAsync();
        }

        var classScheduleRaw = await (
            from cs in Q<LiveSession>()
            join l in Q<Lesson>() on cs.LessonId equals l.Id into lessonJoin
            from csLesson in lessonJoin.DefaultIfEmpty()
            where cs.ClassId == cls.Id
            orderby cs.StartsAt
            select new
            {
                cs.Id,
                cs.Title,
                cs.StartsAt,
                cs.EndsAt,
                cs.Provider,
                cs.RoomUrl,
                cs.Status,
                cs.LessonId,
                lessonTitle = csLesson != null ? csLesson.Title : null,
            }
        ).ToListAsync();

        var classSessions = classScheduleRaw
            .Select(cs =>
            {
                var csEffective = ResolveEffectiveStatus(
                    cs.Status,
                    cls.Status,
                    cs.StartsAt,
                    cs.EndsAt,
                    now
                );
                return new
                {
                    id = cs.Id,
                    title = cs.Title,
                    startsAt = cs.StartsAt,
                    endsAt = cs.EndsAt,
                    provider = "livekit",
                    providerLabel = ResolveProviderLabel(cs.Provider, cs.RoomUrl),
                    roomName = ResolveRoomName(cs.Id),
                    status = cs.Status,
                    effectiveStatus = csEffective,
                    filterGroup = ResolveFilterGroup(csEffective),
                    hasRoomUrl = true,
                    lessonId = cs.LessonId,
                    lessonTitle = cs.lessonTitle,
                    isCurrent = cs.Id == s.Id,
                };
            })
            .ToList();

        var isClassOpen = cls.Status is "open" or "active";

        return new
        {
            id = s.Id,
            title = s.Title,
            startsAt = s.StartsAt,
            endsAt = s.EndsAt,
            opensAt = s.StartsAt.AddMinutes(-15),
            provider = "livekit",
            providerLabel = ResolveProviderLabel(s.Provider, s.RoomUrl),
            roomName,
            inAppRoom = true,
            sfuConfigured,
            sfuMissingConfigKeys = isStaff ? missingKeys : null,
            status = s.Status,
            effectiveStatus,
            filterGroup,
            hasRoomUrl = true,
            canJoin,
            joinBlockedReason = blockedReason,
            canStartSession = isStaff && isClassOpen && s.Status == "scheduled" && s.EndsAt > now,
            canEndSession = isStaff && s.Status == "live",
            canCancelSession = isStaff && s.Status is "scheduled" or "live",
            canEditSession = isStaff && s.Status == "scheduled",
            recordingUrl = effectiveStatus == "completed" ? s.RecordingUrl : null,
            childId = resolvedChildId,
            childNickname = resolvedChildName,
            liveClass = new
            {
                id = cls.Id,
                name = cls.Name,
                status = cls.Status,
                capacity = cls.Capacity,
                enrolledCount,
                courseId = cls.CourseId,
                courseTitle = course?.Title ?? "",
                courseDescription = course?.Description ?? "",
                ageRange = course?.AgeRange ?? "",
                instructorId = cls.InstructorId,
                instructorName = instructor?.FullName ?? "Giáo viên ArtKids",
            },
            lesson = lesson is null
                ? null
                : new
                {
                    id = lesson.Id,
                    title = lesson.Title,
                    orderIndex = lesson.OrderIndex,
                    practiceInstructions = lesson.PracticeInstructions,
                    hasVideo = !string.IsNullOrWhiteSpace(lesson.VideoUrl)
                        || !string.IsNullOrWhiteSpace(lesson.VideoAssetId),
                },
            attendance = attendance is null
                ? null
                : new
                {
                    id = attendance.Id,
                    firstJoinedAt = attendance.FirstJoinedAt,
                    lastJoinedAt = attendance.LastJoinedAt,
                    lastLeftAt = attendance.LastLeftAt,
                    totalDurationSeconds = attendance.TotalDurationSeconds,
                },
            roster = rosterWithAttendance,
            courseLessons,
            classSessions,
        };
    }

    public async Task<object> IssueRoomToken(string sessionId, LiveRoomTokenRequest? r)
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await Get<LiveClass>(s.ClassId);
        var now = DateTime.UtcNow;

        if (Actor.Role == "instructor")
        {
            Require(cls.InstructorId == Actor.Id, "Session not found.", 404);
        }

        Require(cls.Status is "open" or "active", "Lớp học đã đóng hoặc kết thúc.", 409);
        Require(
            s.Status is not ("completed" or "cancelled") && s.EndsAt > now,
            "Buổi học đã kết thúc hoặc đã bị hủy.",
            409
        );
        Require(
            s.Status == "live" || (s.Status == "scheduled" && s.StartsAt <= now.AddMinutes(15)),
            "Phòng học trực tuyến sẽ mở trước giờ bắt đầu 15 phút hoặc khi gia sư bắt đầu buổi học.",
            409
        );

        var isStaff = Actor.Role == "admin" || cls.InstructorId == Actor.Id;
        string participantIdentity;
        string participantName;
        string participantRole;
        string? resolvedChildId = null;

        if (isStaff)
        {
            var user = await Get<User>(Actor.Id);
            participantIdentity = $"instructor:{user.Id}";
            participantName = user.FullName;
            participantRole = "instructor";
        }
        else
        {
            var childId = r?.ChildId;
            ChildProfile child;
            if (!string.IsNullOrWhiteSpace(childId))
            {
                child = await OwnChild(childId);
                await RequireEnrollment(child.Id, cls.CourseId);
                var enr =
                    await Q<LiveClassEnrollment>()
                        .SingleOrDefaultAsync(x =>
                            x.ClassId == cls.Id && x.ChildId == child.Id && x.Status == "enrolled"
                        )
                    ?? throw new BusinessException(
                        403,
                        "Bé chưa đăng ký tham gia lớp học trực tuyến này."
                    );
                resolvedChildId = enr.ChildId;
            }
            else
            {
                var parentChildren = await Q<ChildProfile>()
                    .Where(c => c.ParentId == Actor.Id)
                    .OrderBy(c => c.CreatedAt)
                    .ToListAsync();
                var parentChildIds = parentChildren.Select(c => c.Id).ToList();
                var enr =
                    await Q<LiveClassEnrollment>()
                        .Where(x =>
                            x.ClassId == cls.Id
                            && parentChildIds.Contains(x.ChildId)
                            && x.Status == "enrolled"
                        )
                        .OrderBy(x => x.EnrolledAt)
                        .FirstOrDefaultAsync()
                    ?? throw new BusinessException(
                        403,
                        "Bé chưa đăng ký tham gia lớp học trực tuyến này."
                    );
                await RequireEnrollment(enr.ChildId, cls.CourseId);
                child = parentChildren.First(c => c.Id == enr.ChildId);
                resolvedChildId = child.Id;
            }

            participantIdentity = $"student:{child.Id}";
            participantName = child.Nickname;
            participantRole = "student";
        }

        var roomState = GetOrCreateRoomState(s.Id);
        int roomVersion;
        bool canShareScreen;
        lock (roomState.SyncRoot)
        {
            if (roomState.IsClosed && s.Status is "scheduled" or "live")
            {
                roomState.IsClosed = false;
                roomState.ClosedAt = null;
            }
            roomVersion = roomState.RoomVersion;
            canShareScreen = CanParticipantShareScreen(
                roomState,
                participantIdentity,
                participantRole
            );
        }

        var endsAtUtc = DateTime.SpecifyKind(s.EndsAt, DateTimeKind.Utc);
        var sessionEndExpiry = endsAtUtc.AddMinutes(15);
        var twoHoursExpiry = now.AddHours(2);
        var expiresAt = sessionEndExpiry < twoHoursExpiry ? sessionEndExpiry : twoHoursExpiry;
        if (expiresAt <= now.AddMinutes(5))
            expiresAt = now.AddMinutes(30);

        var roomToken = CreateInternalRoomToken(
            s.Id,
            roomState.RoomName,
            participantIdentity,
            participantName,
            participantRole,
            resolvedChildId,
            roomVersion,
            expiresAt
        );

        var (sfuConfigured, sfuUrl, apiKey, apiSecret, missingKeys) = GetLiveKitConfig();
        string? livekitAccessToken = null;
        if (sfuConfigured && apiKey is not null && apiSecret is not null)
        {
            livekitAccessToken = CreateLiveKitJwtToken(
                apiKey,
                apiSecret,
                roomState.RoomName,
                participantIdentity,
                participantName,
                isInstructor: isStaff,
                canShareScreen: canShareScreen,
                expiresAt: expiresAt
            );
        }

        var course = await Q<Course>().SingleOrDefaultAsync(x => x.Id == cls.CourseId);
        var instructorUser = await Q<User>().SingleOrDefaultAsync(x => x.Id == cls.InstructorId);
        var publishSources = canShareScreen
            ? new[] { "camera", "microphone", "screen_share", "screen_share_audio" }
            : new[] { "camera", "microphone" };

        // NOTE: Issuing a token does NOT record attendance (Requirement 5).
        // Attendance is only recorded when ConnectRoom or a verified SFU participant_joined event occurs.
        return new
        {
            sessionId = s.Id,
            classId = cls.Id,
            roomName = roomState.RoomName,
            roomVersion,
            sessionTitle = s.Title,
            className = cls.Name,
            courseTitle = course?.Title ?? "",
            instructorName = instructorUser?.FullName ?? "Giáo viên ArtKids",
            capacity = cls.Capacity,
            isOneOnOne = cls.Capacity == 1,
            participantIdentity,
            participantName,
            participantRole,
            childId = resolvedChildId,
            roomToken,
            expiresAt,
            permissions = new
            {
                canPublish = true,
                canPublishAudio = true,
                canPublishVideo = true,
                canPublishSources = publishSources,
                canSubscribe = true,
                canPublishData = true,
                roomAdmin = isStaff,
                canModerate = isStaff,
                canModerateAudio = isStaff,
                canShareScreen,
                canGrantScreenShare = isStaff,
                canEndSession = isStaff,
            },
            sfu = new
            {
                provider = "livekit",
                isConfigured = sfuConfigured,
                url = sfuUrl,
                serverUrl = sfuUrl,
                accessToken = livekitAccessToken,
                missingConfigKeys = missingKeys,
                missingConfigurationKeys = missingKeys,
            },
        };
    }

    public Task<object> ConnectRoom(string sessionId, LiveRoomConnectRequest r)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var s = await Get<LiveSession>(sessionId);
            var cls = await Get<LiveClass>(s.ClassId);
            var now = DateTime.UtcNow;

            if (Actor.Role == "instructor")
            {
                Require(cls.InstructorId == Actor.Id, "Session not found.", 404);
            }

            Require(cls.Status is "open" or "active", "Lớp học đã đóng.", 409);
            Require(
                s.Status is not ("completed" or "cancelled") && s.EndsAt > now,
                "Buổi học đã kết thúc hoặc đã bị hủy. Không thể kết nối vào phòng đã đóng.",
                409
            );

            var roomState = GetOrCreateRoomState(s.Id);
            int currentVersion;
            lock (roomState.SyncRoot)
            {
                Require(
                    !roomState.IsClosed,
                    "Phiên phòng học đã kết thúc. Không thể sử dụng lại token để vào phòng.",
                    409
                );
                currentVersion = roomState.RoomVersion;
            }

            var principal = ValidateInternalRoomToken(r.RoomToken, s.Id, currentVersion);
            var identity = principal.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? "";
            var displayName = principal.FindFirstValue(JwtRegisteredClaimNames.Name) ?? "Thành viên";
            var role = principal.FindFirstValue("role") ?? "student";
            var tokenChildId = principal.FindFirstValue("childId") ?? r.ChildId;
            var deviceId = string.IsNullOrWhiteSpace(r.DeviceId) ? "default-device" : r.DeviceId.Trim();

            if (role == "instructor")
            {
                Require(
                    Actor.Role == "admin" || cls.InstructorId == Actor.Id,
                    "Bạn không có quyền gia sư trong phòng học này.",
                    403
                );
            }
            else
            {
                Require(!string.IsNullOrWhiteSpace(tokenChildId), "Thiếu thông tin học viên.");
                await OwnChild(tokenChildId!);
                await RequireEnrollment(tokenChildId!, cls.CourseId);
                var enrollment =
                    await Q<LiveClassEnrollment>()
                        .SingleOrDefaultAsync(x =>
                            x.ClassId == cls.Id && x.ChildId == tokenChildId && x.Status == "enrolled"
                        )
                    ?? throw new BusinessException(403, "Bé chưa đăng ký vào lớp học này.");

                var attendance = await Q<LiveSessionAttendance>()
                    .SingleOrDefaultAsync(x =>
                        x.SessionId == s.Id && x.ClassEnrollmentId == enrollment.Id
                    );
                if (attendance is null)
                {
                    attendance = new LiveSessionAttendance
                    {
                        SessionId = s.Id,
                        ClassEnrollmentId = enrollment.Id,
                        FirstJoinedAt = now,
                        LastJoinedAt = now,
                    };
                    Add(attendance);
                }
                else
                {
                    attendance.FirstJoinedAt ??= now;
                    // Deduplicate overlapping reconnects / multi-device joins:
                    // Only set LastJoinedAt if not currently active in room.
                    attendance.LastJoinedAt ??= now;
                }
            }

            lock (roomState.SyncRoot)
            {
                if (!roomState.Participants.TryGetValue(identity, out var p))
                {
                    p = new InAppParticipantConnection
                    {
                        Identity = identity,
                        DisplayName = displayName,
                        Role = role,
                        ChildId = tokenChildId,
                        FirstConnectedAt = now,
                    };
                    roomState.Participants[identity] = p;
                }
                p.ActiveDeviceIds.Add(deviceId);
                p.MicEnabled = r.MicEnabled;
                p.CameraEnabled = r.CameraEnabled;
                p.CameraFacing = r.CameraFacing;
                p.IsReconnecting = false;
                p.LastSeenAt = now;
            }

            return BuildRoomSnapshot(s, cls, roomState, identity);
        });
    }

    public async Task<object> SyncRoomState(string sessionId, LiveRoomMediaStateRequest r)
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await Get<LiveClass>(s.ClassId);
        var now = DateTime.UtcNow;

        var roomState = GetOrCreateRoomState(s.Id);
        int currentVersion;
        lock (roomState.SyncRoot)
        {
            if (roomState.IsClosed || s.Status is "completed" or "cancelled")
            {
                throw new BusinessException(409, "Buổi học đã kết thúc và phòng học đã đóng.");
            }
            currentVersion = roomState.RoomVersion;
        }

        var principal = ValidateInternalRoomToken(r.RoomToken, s.Id, currentVersion);
        var identity = principal.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? "";
        var displayName = principal.FindFirstValue(JwtRegisteredClaimNames.Name) ?? "Thành viên";
        var role = principal.FindFirstValue("role") ?? "student";
        var tokenChildId = principal.FindFirstValue("childId") ?? r.ChildId;
        var deviceId = string.IsNullOrWhiteSpace(r.DeviceId) ? "default-device" : r.DeviceId.Trim();

        lock (roomState.SyncRoot)
        {
            if (!roomState.Participants.TryGetValue(identity, out var p))
            {
                p = new InAppParticipantConnection
                {
                    Identity = identity,
                    DisplayName = displayName,
                    Role = role,
                    ChildId = tokenChildId,
                    FirstConnectedAt = now,
                };
                roomState.Participants[identity] = p;
            }
            p.ActiveDeviceIds.Add(deviceId);
            if (p.MuteRequestedByInstructor)
            {
                p.MicEnabled = false;
                if (!r.MicEnabled)
                {
                    p.MuteRequestedByInstructor = false;
                }
            }
            else
            {
                p.MicEnabled = r.MicEnabled;
            }
            p.CameraEnabled = r.CameraEnabled;
            p.CameraFacing = r.CameraFacing;
            p.AudioOnly = r.AudioOnly;
            p.IsReconnecting = r.IsReconnecting;
            p.LastSeenAt = now;
        }

        return BuildRoomSnapshot(s, cls, roomState, identity);
    }

    public async Task<object> ModerateRoomParticipant(string sessionId, LiveRoomModerateRequest r)
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await TeachClass(s.ClassId);
        var action = r.Action.Trim().ToLowerInvariant();

        Require(
            action == "mute_mic",
            "Chỉ cho phép yêu cầu tắt mic (mute_mic). Hệ thống nghiêm cấm bật camera hoặc microphone từ xa mà không có sự đồng ý của người dùng.",
            400
        );

        var roomState = GetOrCreateRoomState(s.Id);
        lock (roomState.SyncRoot)
        {
            Require(
                roomState.Participants.TryGetValue(r.TargetIdentity, out var target),
                "Không tìm thấy người tham gia này trong phòng học.",
                404
            );
            target!.MicEnabled = false;
            target.MuteRequestedByInstructor = true;
            target.LastSeenAt = DateTime.UtcNow;
        }

        return BuildRoomSnapshot(
            s,
            cls,
            roomState,
            $"instructor:{Actor.Id}",
            moderated: true,
            targetIdentity: r.TargetIdentity,
            action: action
        );
    }

    public async Task<object> SetScreenSharePermission(
        string sessionId,
        LiveRoomScreenSharePermissionRequest r
    )
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await TeachClass(s.ClassId);
        var now = DateTime.UtcNow;
        var roomState = GetOrCreateRoomState(s.Id);
        var targetIdentity = r.TargetIdentity.Trim();

        Require(
            targetIdentity.StartsWith("student:", StringComparison.Ordinal),
            "Chỉ áp dụng cấp hoặc thu hồi quyền chia sẻ màn hình đối với học viên.",
            400
        );

        lock (roomState.SyncRoot)
        {
            if (r.CanShareScreen)
            {
                roomState.GrantedScreenShareIdentities.Add(targetIdentity);
                if (roomState.Participants.TryGetValue(targetIdentity, out var target))
                {
                    target.ScreenShareRevokedNotificationPending = false;
                    target.LastSeenAt = now;
                }
            }
            else
            {
                roomState.GrantedScreenShareIdentities.Remove(targetIdentity);
                if (roomState.ActiveScreenShare?.PresenterIdentity == targetIdentity)
                {
                    roomState.ActiveScreenShare = null;
                    roomState.ScreenShareSequence++;
                }
                if (roomState.Participants.TryGetValue(targetIdentity, out var target))
                {
                    target.ScreenSharing = false;
                    target.ScreenShareRevokedNotificationPending = true;
                    target.LastSeenAt = now;
                }
            }
        }

        return BuildRoomSnapshot(
            s,
            cls,
            roomState,
            $"instructor:{Actor.Id}",
            moderated: true,
            targetIdentity: targetIdentity,
            action: r.CanShareScreen ? "grant_screen_share" : "revoke_screen_share"
        );
    }

    public async Task<object> StartScreenShare(
        string sessionId,
        LiveRoomScreenShareStartRequest r
    )
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await Get<LiveClass>(s.ClassId);
        var now = DateTime.UtcNow;

        var roomState = GetOrCreateRoomState(s.Id);
        int currentVersion;
        lock (roomState.SyncRoot)
        {
            Require(
                !roomState.IsClosed && s.Status is not ("completed" or "cancelled"),
                "Phòng học đã đóng hoặc buổi học đã kết thúc.",
                409
            );
            currentVersion = roomState.RoomVersion;
        }

        var principal = ValidateInternalRoomToken(r.RoomToken, s.Id, currentVersion);
        var identity = principal.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? "";
        var displayName = principal.FindFirstValue(JwtRegisteredClaimNames.Name) ?? "Thành viên";
        var role = principal.FindFirstValue("role") ?? "student";
        var tokenChildId = principal.FindFirstValue("childId") ?? r.ChildId;
        var deviceId = string.IsNullOrWhiteSpace(r.DeviceId) ? "default-device" : r.DeviceId.Trim();

        lock (roomState.SyncRoot)
        {
            Require(
                CanParticipantShareScreen(roomState, identity, role),
                "Bạn chưa được gia sư cấp quyền chia sẻ màn hình trong buổi học này.",
                403
            );

            if (
                roomState.ActiveScreenShare is not null
                && roomState.ActiveScreenShare.PresenterIdentity != identity
            )
            {
                throw new BusinessException(
                    409,
                    $"Hiện tại {roomState.ActiveScreenShare.PresenterName} đang chia sẻ màn hình. Chỉ cho phép một người chia sẻ tại một thời điểm."
                );
            }

            if (!roomState.Participants.TryGetValue(identity, out var p))
            {
                p = new InAppParticipantConnection
                {
                    Identity = identity,
                    DisplayName = displayName,
                    Role = role,
                    ChildId = tokenChildId,
                    FirstConnectedAt = now,
                };
                roomState.Participants[identity] = p;
            }
            p.ActiveDeviceIds.Add(deviceId);
            p.ScreenSharing = true;
            p.ScreenShareRevokedNotificationPending = false;
            p.LastSeenAt = now;

            roomState.ScreenShareSequence++;
            var seq = roomState.ScreenShareSequence;
            roomState.ActiveScreenShare = new InAppActiveScreenShare
            {
                PresenterIdentity = identity,
                PresenterName = displayName,
                PresenterRole = role,
                Scope = string.IsNullOrWhiteSpace(r.Scope) ? "entire_screen" : r.Scope.Trim(),
                ContentLabel = string.IsNullOrWhiteSpace(r.ContentLabel)
                    ? $"Màn hình của {displayName}"
                    : r.ContentLabel.Trim(),
                IncludeDeviceAudio = r.IncludeDeviceAudio,
                Width = r.Width > 0 ? r.Width : 1080,
                Height = r.Height > 0 ? r.Height : 1920,
                FrameBase64 = r.FrameBase64,
                Sequence = seq,
                StartedAt = now,
                UpdatedAt = now,
            };
        }

        return BuildRoomSnapshot(s, cls, roomState, identity);
    }

    public async Task<object> UpdateScreenShareFrame(
        string sessionId,
        LiveRoomScreenShareFrameRequest r
    )
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await Get<LiveClass>(s.ClassId);
        var now = DateTime.UtcNow;

        var roomState = GetOrCreateRoomState(s.Id);
        int currentVersion;
        lock (roomState.SyncRoot)
        {
            Require(
                !roomState.IsClosed && s.Status is not ("completed" or "cancelled"),
                "Phòng học đã đóng hoặc buổi học đã kết thúc.",
                409
            );
            currentVersion = roomState.RoomVersion;
        }

        var principal = ValidateInternalRoomToken(r.RoomToken, s.Id, currentVersion);
        var identity = principal.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? "";
        var role = principal.FindFirstValue("role") ?? "student";

        lock (roomState.SyncRoot)
        {
            Require(
                CanParticipantShareScreen(roomState, identity, role),
                "Quyền chia sẻ màn hình của bạn đã bị thu hồi hoặc chưa được cấp.",
                403
            );
            Require(
                roomState.ActiveScreenShare is not null
                    && roomState.ActiveScreenShare.PresenterIdentity == identity,
                "Phiên chia sẻ màn hình hiện không còn hiệu lực.",
                409
            );

            roomState.ScreenShareSequence++;
            roomState.ActiveScreenShare!.Width = r.Width > 0 ? r.Width : roomState.ActiveScreenShare.Width;
            roomState.ActiveScreenShare.Height = r.Height > 0 ? r.Height : roomState.ActiveScreenShare.Height;
            if (!string.IsNullOrWhiteSpace(r.FrameBase64))
            {
                roomState.ActiveScreenShare.FrameBase64 = r.FrameBase64;
            }
            if (!string.IsNullOrWhiteSpace(r.ContentLabel))
            {
                roomState.ActiveScreenShare.ContentLabel = r.ContentLabel.Trim();
            }
            roomState.ActiveScreenShare.Sequence = roomState.ScreenShareSequence;
            roomState.ActiveScreenShare.UpdatedAt = now;

            if (roomState.Participants.TryGetValue(identity, out var p))
            {
                p.LastSeenAt = now;
            }
        }

        return BuildRoomSnapshot(s, cls, roomState, identity);
    }

    public async Task<object> StopScreenShare(
        string sessionId,
        LiveRoomScreenShareStopRequest r
    )
    {
        var s = await Get<LiveSession>(sessionId);
        var cls = await Get<LiveClass>(s.ClassId);
        var now = DateTime.UtcNow;

        var roomState = GetOrCreateRoomState(s.Id);
        int currentVersion;
        lock (roomState.SyncRoot)
        {
            currentVersion = roomState.RoomVersion;
        }

        var principal = ValidateInternalRoomToken(r.RoomToken, s.Id, currentVersion);
        var identity = principal.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? "";
        var role = principal.FindFirstValue("role") ?? "student";

        lock (roomState.SyncRoot)
        {
            if (roomState.Participants.TryGetValue(identity, out var p))
            {
                p.ScreenSharing = false;
                p.LastSeenAt = now;
            }

            if (
                roomState.ActiveScreenShare is not null
                && (
                    roomState.ActiveScreenShare.PresenterIdentity == identity
                    || role is "instructor" or "admin"
                )
            )
            {
                var prevIdentity = roomState.ActiveScreenShare.PresenterIdentity;
                if (roomState.Participants.TryGetValue(prevIdentity, out var prevP))
                {
                    prevP.ScreenSharing = false;
                }
                roomState.ActiveScreenShare = null;
                roomState.ScreenShareSequence++;
            }
        }

        return BuildRoomSnapshot(s, cls, roomState, identity);
    }

    public Task<object> DisconnectRoom(string sessionId, LiveRoomDisconnectRequest? r)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var s = await Get<LiveSession>(sessionId);
            var cls = await Get<LiveClass>(s.ClassId);
            var now = DateTime.UtcNow;
            var roomState = GetOrCreateRoomState(s.Id);
            var deviceId = string.IsNullOrWhiteSpace(r?.DeviceId)
                ? "default-device"
                : r!.DeviceId!.Trim();

            string identity;
            string? resolvedChildId = r?.ChildId;
            if (Actor.Role == "admin" || cls.InstructorId == Actor.Id)
            {
                identity = $"instructor:{Actor.Id}";
            }
            else
            {
                if (string.IsNullOrWhiteSpace(resolvedChildId) && !string.IsNullOrWhiteSpace(r?.RoomToken))
                {
                    var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
                    if (handler.CanReadToken(r!.RoomToken))
                    {
                        var jwt = handler.ReadJwtToken(r.RoomToken);
                        resolvedChildId = jwt.Claims.FirstOrDefault(c => c.Type == "childId")?.Value;
                    }
                }
                if (!string.IsNullOrWhiteSpace(resolvedChildId))
                {
                    await OwnChild(resolvedChildId!);
                }
                identity = $"student:{resolvedChildId}";
            }

            var hasRemainingDevices = false;
            lock (roomState.SyncRoot)
            {
                if (roomState.Participants.TryGetValue(identity, out var p))
                {
                    p.ActiveDeviceIds.Remove(deviceId);
                    if (string.IsNullOrWhiteSpace(r?.DeviceId) || p.ActiveDeviceIds.Count == 0)
                    {
                        roomState.Participants.Remove(identity);
                        if (roomState.ActiveScreenShare?.PresenterIdentity == identity)
                        {
                            roomState.ActiveScreenShare = null;
                            roomState.ScreenShareSequence++;
                        }
                        hasRemainingDevices = false;
                    }
                    else
                    {
                        hasRemainingDevices = true;
                    }
                }
            }

            // Only finalize student attendance segment when their last active device leaves the room.
            // Note: Instructor leaving the room does NOT end the session for everyone (Requirement 3).
            if (Actor.Role == "parent" && !string.IsNullOrWhiteSpace(resolvedChildId) && !hasRemainingDevices)
            {
                var enrollment = await Q<LiveClassEnrollment>()
                    .SingleOrDefaultAsync(x =>
                        x.ClassId == s.ClassId && x.ChildId == resolvedChildId
                    );
                if (enrollment is not null)
                {
                    var attendance = await Q<LiveSessionAttendance>()
                        .SingleOrDefaultAsync(x =>
                            x.SessionId == s.Id && x.ClassEnrollmentId == enrollment.Id
                        );
                    if (attendance?.LastJoinedAt is not null)
                    {
                        var end = now < s.EndsAt ? now : s.EndsAt;
                        attendance.TotalDurationSeconds += Math.Max(
                            0,
                            (int)(end - attendance.LastJoinedAt.Value).TotalSeconds
                        );
                        attendance.LastLeftAt = end;
                        attendance.LastJoinedAt = null;
                    }
                }
            }

            return new
            {
                sessionId = s.Id,
                disconnected = true,
                sessionStatus = s.Status,
            };
        });
    }

    public Task<object> EndRoomSession(string sessionId, LiveRoomEndSessionRequest? r)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var s = await Get<LiveSession>(sessionId);
            await TeachClass(s.ClassId);
            Require(
                s.Status is "scheduled" or "live" or "completed",
                "Không thể kết thúc buổi học đã bị hủy.",
                409
            );
            if (!string.IsNullOrWhiteSpace(r?.RecordingUrl))
            {
                Require(
                    Uri.TryCreate(r!.RecordingUrl, UriKind.Absolute, out var uri)
                        && uri.Scheme == "https",
                    "Recording URL must use HTTPS."
                );
                s.RecordingUrl = r.RecordingUrl;
            }

            var now = DateTime.UtcNow;
            var activeAttendances = await Q<LiveSessionAttendance>()
                .Where(a => a.SessionId == s.Id && a.LastJoinedAt != null)
                .ToListAsync();
            foreach (var a in activeAttendances)
            {
                var end = now < s.EndsAt ? now : s.EndsAt;
                a.TotalDurationSeconds += Math.Max(
                    0,
                    (int)(end - a.LastJoinedAt!.Value).TotalSeconds
                );
                a.LastLeftAt = end;
                a.LastJoinedAt = null;
            }

            s.Status = "completed";

            var roomState = GetOrCreateRoomState(s.Id);
            lock (roomState.SyncRoot)
            {
                roomState.IsClosed = true;
                roomState.ClosedAt = now;
                roomState.RoomVersion++;
                roomState.ActiveScreenShare = null;
                roomState.GrantedScreenShareIdentities.Clear();
                roomState.Participants.Clear();
            }

            return new
            {
                sessionId = s.Id,
                status = s.Status,
                roomClosed = true,
                closedAt = now,
            };
        });
    }

    public Task<object> HandleLiveKitWebhook(string? authHeader, string rawBody)
    {
        return Store.TransactionAsync<object>(async () =>
        {
            var (sfuConfigured, _, apiKey, apiSecret, _) = GetLiveKitConfig();
            Require(
                sfuConfigured && apiKey is not null && apiSecret is not null,
                "LiveKit webhook secret is not configured.",
                503
            );
            Require(!string.IsNullOrWhiteSpace(authHeader), "Missing Authorization header.", 401);

            var token = authHeader!.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? authHeader["Bearer ".Length..].Trim()
                : authHeader.Trim();

            var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
            ClaimsPrincipal principal;
            try
            {
                principal = handler.ValidateToken(
                    token,
                    new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidIssuer = apiKey,
                        ValidateAudience = false,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(apiSecret!)
                        ),
                        ClockSkew = TimeSpan.FromMinutes(2),
                    },
                    out _
                );
            }
            catch
            {
                throw new BusinessException(401, "Invalid LiveKit webhook signature.");
            }

            var claimHash = principal.FindFirstValue("sha256");
            if (!string.IsNullOrWhiteSpace(claimHash))
            {
                var bodyBytes = Encoding.UTF8.GetBytes(rawBody);
                var computedHex = Convert.ToHexString(SHA256.HashData(bodyBytes)).ToLowerInvariant();
                var computedB64 = Convert.ToBase64String(SHA256.HashData(bodyBytes));
                Require(
                    string.Equals(claimHash, computedHex, StringComparison.OrdinalIgnoreCase)
                        || string.Equals(claimHash, computedB64, StringComparison.Ordinal),
                    "Webhook payload sha256 mismatch.",
                    401
                );
            }

            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;
            var eventId = root.TryGetProperty("id", out var idProp) ? idProp.GetString() : null;
            var eventType = root.TryGetProperty("event", out var evProp) ? evProp.GetString() : null;
            var createdAt = root.TryGetProperty("createdAt", out var tsProp)
                && tsProp.TryGetInt64(out var tsVal)
                ? tsVal
                : DateTimeOffset.UtcNow.ToUnixTimeSeconds();

            if (!string.IsNullOrWhiteSpace(eventId) && !ProcessedWebhookIds.TryAdd(eventId, DateTime.UtcNow))
            {
                return new { deduplicated = true, eventId };
            }

            var roomName = root.TryGetProperty("room", out var roomProp)
                && roomProp.TryGetProperty("name", out var rnProp)
                ? rnProp.GetString()
                : null;
            if (
                string.IsNullOrWhiteSpace(roomName)
                || !roomName.StartsWith("artkids-session-", StringComparison.Ordinal)
            )
            {
                return new { ignored = true };
            }

            var sessionId = roomName["artkids-session-".Length..];
            var session = await Q<LiveSession>().SingleOrDefaultAsync(x => x.Id == sessionId);
            if (session is null)
                return new { ignored = true };

            var participantIdentity = root.TryGetProperty("participant", out var partProp)
                && partProp.TryGetProperty("identity", out var identProp)
                ? identProp.GetString()
                : null;

            var roomState = GetOrCreateRoomState(sessionId);
            var now = DateTime.UtcNow;

            if (eventType == "participant_joined" && participantIdentity is not null)
            {
                lock (roomState.SyncRoot)
                {
                    if (
                        roomState.Participants.TryGetValue(participantIdentity, out var existing)
                        && existing.LastWebhookTimestamp > createdAt
                    )
                    {
                        return new { outOfOrderIgnored = true };
                    }
                }

                if (participantIdentity.StartsWith("student:", StringComparison.Ordinal))
                {
                    var childId = participantIdentity["student:".Length..];
                    var enrollment = await Q<LiveClassEnrollment>()
                        .SingleOrDefaultAsync(x =>
                            x.ClassId == session.ClassId
                            && x.ChildId == childId
                            && x.Status == "enrolled"
                        );
                    if (enrollment is not null)
                    {
                        var attendance = await Q<LiveSessionAttendance>()
                            .SingleOrDefaultAsync(x =>
                                x.SessionId == session.Id && x.ClassEnrollmentId == enrollment.Id
                            );
                        if (attendance is null)
                        {
                            attendance = new LiveSessionAttendance
                            {
                                SessionId = session.Id,
                                ClassEnrollmentId = enrollment.Id,
                                FirstJoinedAt = now,
                                LastJoinedAt = now,
                            };
                            Add(attendance);
                        }
                        else
                        {
                            attendance.FirstJoinedAt ??= now;
                            attendance.LastJoinedAt ??= now;
                        }
                    }
                }
            }
            else if (eventType == "participant_left" && participantIdentity is not null)
            {
                if (participantIdentity.StartsWith("student:", StringComparison.Ordinal))
                {
                    var childId = participantIdentity["student:".Length..];
                    var enrollment = await Q<LiveClassEnrollment>()
                        .SingleOrDefaultAsync(x =>
                            x.ClassId == session.ClassId && x.ChildId == childId
                        );
                    if (enrollment is not null)
                    {
                        var attendance = await Q<LiveSessionAttendance>()
                            .SingleOrDefaultAsync(x =>
                                x.SessionId == session.Id && x.ClassEnrollmentId == enrollment.Id
                            );
                        if (attendance?.LastJoinedAt is not null)
                        {
                            var end = now < session.EndsAt ? now : session.EndsAt;
                            attendance.TotalDurationSeconds += Math.Max(
                                0,
                                (int)(end - attendance.LastJoinedAt.Value).TotalSeconds
                            );
                            attendance.LastLeftAt = end;
                            attendance.LastJoinedAt = null;
                        }
                    }
                }
            }

            return new { processed = true, eventType, sessionId };
        });
    }

    private object BuildRoomSnapshot(
        LiveSession s,
        LiveClass cls,
        InAppRoomSessionState roomState,
        string callerIdentity,
        bool? moderated = null,
        string? targetIdentity = null,
        string? action = null
    )
    {
        var now = DateTime.UtcNow;
        var (sfuConfigured, sfuUrl, _, _, missingKeys) = GetLiveKitConfig();
        List<object> participants;
        bool callerMuteRequested = false;
        bool callerScreenShareRevoked = false;
        bool callerCanShareScreen;
        object? screenSharePayload = null;

        lock (roomState.SyncRoot)
        {
            var callerRole = callerIdentity.StartsWith("instructor:", StringComparison.Ordinal)
                ? "instructor"
                : "student";
            if (roomState.Participants.TryGetValue(callerIdentity, out var caller))
            {
                callerRole = caller.Role;
                callerMuteRequested = caller.MuteRequestedByInstructor;
                if (caller.ScreenShareRevokedNotificationPending)
                {
                    callerScreenShareRevoked = true;
                    caller.ScreenShareRevokedNotificationPending = false;
                }
            }

            callerCanShareScreen = CanParticipantShareScreen(
                roomState,
                callerIdentity,
                callerRole
            );

            var activeShare = roomState.ActiveScreenShare;
            if (activeShare is not null)
            {
                screenSharePayload = new
                {
                    isActive = true,
                    presenterIdentity = activeShare.PresenterIdentity,
                    presenterName = activeShare.PresenterName,
                    presenterRole = activeShare.PresenterRole,
                    scope = activeShare.Scope,
                    contentLabel = activeShare.ContentLabel,
                    includeDeviceAudio = activeShare.IncludeDeviceAudio,
                    width = activeShare.Width,
                    height = activeShare.Height,
                    aspectRatio = activeShare.AspectRatio,
                    frameBase64 = activeShare.FrameBase64,
                    sequence = activeShare.Sequence,
                    startedAt = activeShare.StartedAt,
                    updatedAt = activeShare.UpdatedAt,
                };
            }

            participants = roomState
                .Participants.Values.OrderBy(p => p.Role == "instructor" ? 0 : 1)
                .ThenBy(p => p.FirstConnectedAt)
                .Select(p =>
                {
                    var isStale = (now - p.LastSeenAt).TotalSeconds > 45;
                    var connectionState = isStale || p.IsReconnecting
                        ? "reconnecting"
                        : p.AudioOnly
                            ? "audio_only"
                            : "connected";
                    var pCanShare = CanParticipantShareScreen(roomState, p.Identity, p.Role);
                    var isPresenting = activeShare?.PresenterIdentity == p.Identity;
                    return (object)
                        new
                        {
                            identity = p.Identity,
                            displayName = p.DisplayName,
                            role = p.Role,
                            childId = p.ChildId,
                            micEnabled = p.MicEnabled,
                            cameraEnabled = p.CameraEnabled && !p.AudioOnly,
                            cameraFacing = p.CameraFacing,
                            audioOnly = p.AudioOnly,
                            isReconnecting = isStale || p.IsReconnecting,
                            connectionState,
                            activeDeviceCount = p.ActiveDeviceIds.Count,
                            muteRequestedByInstructor = p.MuteRequestedByInstructor,
                            canShareScreen = pCanShare,
                            screenSharing = isPresenting,
                            isSelf = p.Identity == callerIdentity,
                            joinedAt = p.FirstConnectedAt,
                            lastSeenAt = p.LastSeenAt,
                        };
                })
                .ToList();
        }

        return new
        {
            connected = true,
            moderated,
            targetIdentity,
            action,
            sessionId = s.Id,
            classId = cls.Id,
            roomName = roomState.RoomName,
            sessionTitle = s.Title,
            className = cls.Name,
            capacity = cls.Capacity,
            isOneOnOne = cls.Capacity == 1,
            sessionStatus = s.Status,
            effectiveStatus = ResolveEffectiveStatus(
                s.Status,
                cls.Status,
                s.StartsAt,
                s.EndsAt,
                now
            ),
            roomClosed = roomState.IsClosed || s.Status is "completed" or "cancelled",
            sfuConfigured,
            sfuUrl,
            sfuMissingConfigKeys = missingKeys,
            muteRequestedByInstructor = callerMuteRequested,
            screenShareRevokedByInstructor = callerScreenShareRevoked,
            canShareScreen = callerCanShareScreen,
            screenShare = screenSharePayload,
            participants,
            serverTime = now,
        };
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
        var cls = await Get<LiveClass>(classId);
        Require(
            Actor.Role != "instructor" || cls.InstructorId == Actor.Id,
            "Class not found.",
            404
        );
        var now = DateTime.UtcNow;
        var list = await (
            from x in Q<LiveSession>()
            join l in Q<Lesson>() on x.LessonId equals l.Id into lessonJoin
            from lesson in lessonJoin.DefaultIfEmpty()
            where x.ClassId == classId
            orderby x.StartsAt
            select new
            {
                x.Id,
                x.ClassId,
                x.LessonId,
                lessonTitle = lesson != null ? lesson.Title : null,
                x.Title,
                x.StartsAt,
                x.EndsAt,
                x.Provider,
                x.RoomUrl,
                x.Status,
                x.RecordingUrl,
            }
        ).ToListAsync();

        return list.Select(x =>
            {
                var effectiveStatus = ResolveEffectiveStatus(
                    x.Status,
                    cls.Status,
                    x.StartsAt,
                    x.EndsAt,
                    now
                );
                return new
                {
                    x.Id,
                    x.ClassId,
                    x.LessonId,
                    x.lessonTitle,
                    x.Title,
                    x.StartsAt,
                    x.EndsAt,
                    provider = "livekit",
                    providerLabel = ResolveProviderLabel(x.Provider, x.RoomUrl),
                    roomName = ResolveRoomName(x.Id),
                    inAppRoom = true,
                    x.Status,
                    effectiveStatus,
                    filterGroup = ResolveFilterGroup(effectiveStatus),
                    hasRoomUrl = true,
                };
            })
            .ToList();
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
            if (!string.IsNullOrWhiteSpace(r.RoomUrl))
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
            s.RoomUrl = string.IsNullOrWhiteSpace(r.RoomUrl)
                ? ResolveInAppRoomUri(s.Id)
                : r.RoomUrl;
            s.Provider = string.IsNullOrWhiteSpace(r.Provider) || r.Provider == "external"
                ? "livekit"
                : r.Provider;
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

        var now = DateTime.UtcNow;
        if (r.Status is "completed" or "cancelled")
        {
            var activeAttendances = await Q<LiveSessionAttendance>()
                .Where(a => a.SessionId == s.Id && a.LastJoinedAt != null)
                .ToListAsync();
            foreach (var a in activeAttendances)
            {
                var end = now < s.EndsAt ? now : s.EndsAt;
                a.TotalDurationSeconds += Math.Max(
                    0,
                    (int)(end - a.LastJoinedAt!.Value).TotalSeconds
                );
                a.LastLeftAt = end;
                a.LastJoinedAt = null;
            }

            var roomState = GetOrCreateRoomState(s.Id);
            lock (roomState.SyncRoot)
            {
                roomState.IsClosed = true;
                roomState.ClosedAt = now;
                roomState.RoomVersion++;
                roomState.ActiveScreenShare = null;
                roomState.GrantedScreenShareIdentities.Clear();
                roomState.Participants.Clear();
            }
        }
        else if (r.Status == "live")
        {
            var roomState = GetOrCreateRoomState(s.Id);
            lock (roomState.SyncRoot)
            {
                roomState.IsClosed = false;
                roomState.ClosedAt = null;
            }
        }

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
            if (Actor.Role == "instructor")
            {
                Require(cls.InstructorId == Actor.Id, "Session not found.", 404);
            }
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
            var effectiveRoomUrl = string.IsNullOrWhiteSpace(s.RoomUrl)
                ? ResolveInAppRoomUri(s.Id)
                : s.RoomUrl!;
            if (Actor.Role == "admin" || cls.InstructorId == Actor.Id)
                return new
                {
                    sessionId = id,
                    roomName = ResolveRoomName(id),
                    inAppRoom = true,
                    joinUrl = effectiveRoomUrl,
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
                roomName = ResolveRoomName(id),
                inAppRoom = true,
                joinUrl = effectiveRoomUrl,
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

            var roomState = GetOrCreateRoomState(id);
            lock (roomState.SyncRoot)
            {
                roomState.Participants.Remove($"student:{childId}");
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
