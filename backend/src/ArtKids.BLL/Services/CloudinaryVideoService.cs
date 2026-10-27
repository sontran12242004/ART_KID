using System.Security.Cryptography;
using System.Text.Json;
using ArtKids.BLL.Common;
using ArtKids.BLL.Contracts;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;

namespace ArtKids.BLL.Services;

public sealed class CloudinaryVideoService(
    IUnitOfWork store,
    ICurrentUser actor,
    CloudinaryVideoClient cloud,
    IDataProtectionProvider protection
) : ServiceBase(store, actor)
{
    private sealed record Ticket(
        string ActorId,
        string CourseId,
        string LessonId,
        bool Existing,
        long Bytes,
        string PublicId,
        DateTimeOffset Expires
    );

    private IDataProtector Protector => protection.CreateProtector("ArtKids.Cloudinary.Upload.v1");

    public object Status()
    {
        Roles("admin", "instructor");
        return new
        {
            provider = "Cloudinary",
            isConfigured = cloud.IsConfigured,
            maxUploadBytes = cloud.MaxBytes,
        };
    }

    public async Task<object> Prepare(string courseId, VideoUploadRequest request)
    {
        await TeachCourse(courseId);
        cloud.EnsureConfigured();
        Require(
            request.SizeBytes > 0 && request.SizeBytes <= cloud.MaxBytes,
            "Video vượt quá dung lượng cho phép.",
            413
        );
        Require(
            Path.GetExtension(request.FileName).Equals(".mp4", StringComparison.OrdinalIgnoreCase),
            "Chỉ nhận video MP4.",
            415
        );
        if (request.LessonId is not null)
            Require(
                (await Get<Lesson>(request.LessonId)).CourseId == courseId,
                "Lesson not found.",
                404
            );
        var lessonId = request.LessonId ?? Guid.NewGuid().ToString("N");
        var publicId = "artkid/lectures/" + Guid.NewGuid().ToString("N");
        var ticket = new Ticket(
            Actor.Id,
            courseId,
            lessonId,
            request.LessonId is not null,
            request.SizeBytes,
            publicId,
            DateTimeOffset.UtcNow.AddHours(1)
        );
        return new
        {
            uploadToken = Protector.Protect(JsonSerializer.Serialize(ticket)),
            upload = cloud.UploadParameters(publicId),
            chunkBytes = 6 * 1024 * 1024,
        };
    }

    public async Task<Lesson> Complete(
        string courseId,
        VideoCompleteRequest request,
        CancellationToken ct
    )
    {
        await TeachCourse(courseId);
        Ticket ticket;
        try
        {
            ticket =
                JsonSerializer.Deserialize<Ticket>(Protector.Unprotect(request.UploadToken))
                ?? throw new CryptographicException();
        }
        catch (Exception error) when (error is CryptographicException or JsonException)
        {
            throw new BusinessException(400, "Phiên tải video không hợp lệ.");
        }
        Require(
            ticket.ActorId == Actor.Id && ticket.CourseId == courseId,
            "Upload session not found.",
            404
        );
        Require(
            ticket.Expires > DateTimeOffset.UtcNow,
            "Phiên tải video đã hết hạn. Hãy chọn và tải lại video."
        );
        var lesson = await Q<Lesson>().FirstOrDefaultAsync(item => item.Id == ticket.LessonId);
        if (lesson is not null)
        {
            Require(lesson.CourseId == courseId, "Lesson not found.", 404);
            if (
                lesson.VideoUrl?.EndsWith("/" + ticket.PublicId + ".mp4", StringComparison.Ordinal)
                == true
            )
                return lesson;
            Require(ticket.Existing, "Upload session has already been used.", 409);
        }
        Require(
            !await Q<Lesson>()
                .AnyAsync(item =>
                    item.CourseId == courseId
                    && item.OrderIndex == request.OrderIndex
                    && item.Id != ticket.LessonId
                ),
            "Thứ tự bài giảng đã tồn tại. Hãy chọn thứ tự khác rồi lưu lại.",
            409
        );
        var url = await cloud.VerifyUpload(ticket.PublicId, ticket.Bytes, ct);
        if (ticket.Existing)
            Require(lesson is not null, "Lesson not found.", 404);
        if (lesson is null)
        {
            lesson = new Lesson { Id = ticket.LessonId, CourseId = courseId };
            Add(lesson);
        }
        lesson.Title = request.Title;
        lesson.OrderIndex = request.OrderIndex;
        lesson.PracticeInstructions = request.PracticeInstructions;
        lesson.VideoUrl = url;
        lesson.VideoAssetId = null;
        await Store.SaveAsync();
        return lesson;
    }
}
