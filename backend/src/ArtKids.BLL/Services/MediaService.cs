using ArtKids.BLL.Common;
using ArtKids.DAL.Entities;
using ArtKids.DAL.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ArtKids.BLL.Services;

public interface IFileStorage
{
    Task Write(string key, Stream content, CancellationToken ct = default);
    Stream Read(string key);
    void Delete(string key);
}

public sealed class LocalFileStorage : IFileStorage
{
    private readonly string root;

    public LocalFileStorage(IConfiguration config)
    {
        root = Path.GetFullPath(config["Storage:Root"] ?? "App_Data/uploads");
        Directory.CreateDirectory(root);
    }

    private string PathFor(string key)
    {
        if (key != Path.GetFileName(key))
            throw new InvalidOperationException("Invalid storage key.");
        return Path.Combine(root, key);
    }

    public async Task Write(string key, Stream content, CancellationToken ct = default)
    {
        await using var file = new FileStream(PathFor(key), FileMode.CreateNew);
        await content.CopyToAsync(file, ct);
    }

    public Stream Read(string key)
    {
        return new FileStream(PathFor(key), FileMode.Open, FileAccess.Read, FileShare.Read);
    }

    public void Delete(string key)
    {
        File.Delete(PathFor(key));
    }
}

public sealed record MediaDownload(Stream Stream, string ContentType, string Name);

public sealed class MediaService(
    IUnitOfWork store,
    ICurrentUser actor,
    IFileStorage files,
    LearningService learning
) : ServiceBase(store, actor)
{
    public async Task<MediaAsset> Upload(
        Stream stream,
        long length,
        string filename,
        string kind,
        string? childId,
        CancellationToken ct
    )
    {
        Require(
            kind is "drawing" or "video" or "product_image",
            "Kind must be drawing, video or product_image."
        );
        if (kind is "video" or "product_image")
        {
            Roles("admin", "instructor");
            Require(childId is null, "Staff media uploads must not specify a childId.");
        }
        else
        {
            Roles("parent");
            Require(childId is not null, "childId is required.");
            await OwnChild(childId!);
            Require(
                await Q<ParentalConsent>()
                    .AnyAsync(x =>
                        x.ChildId == childId
                        && x.Purpose == "data_processing"
                        && x.RevokedAt == null
                    ),
                "Parental consent is required before upload.",
                403
            );
        }

        Require(
            length > 0 && length <= (kind == "video" ? 300L * 1024 * 1024 : 20L * 1024 * 1024),
            "File exceeds allowed size.",
            413
        );
        // Stage in a seekable temporary file: bounded memory even for lesson videos.
        var temp = Path.GetTempFileName();
        try
        {
            await using var staged = new FileStream(
                temp,
                FileMode.Open,
                FileAccess.ReadWrite,
                FileShare.None,
                81920,
                FileOptions.DeleteOnClose
            );
            await stream.CopyToAsync(staged, ct);
            Require(staged.Length == length, "File length mismatch.");
            staged.Position = 0;
            var header = new byte[12];
            var read = await staged.ReadAsync(header, ct);
            staged.Position = 0;
            var png =
                read >= 8
                && header
                    .AsSpan(0, 8)
                    .SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 });
            var jpeg = read >= 3 && header[0] == 255 && header[1] == 216 && header[2] == 255;
            var mp4 = read >= 12 && System.Text.Encoding.ASCII.GetString(header, 4, 4) == "ftyp";
            Require(
                kind == "video" ? mp4 : png || jpeg,
                "Only PNG/JPEG drawings or MP4 videos are accepted.",
                415
            );
            var ext =
                mp4 ? ".mp4"
                : png ? ".png"
                : ".jpg";
            var key = Guid.NewGuid().ToString("N") + ext;
            var asset = new MediaAsset
            {
                OwnerId = Actor.Id,
                ChildId = childId,
                Kind = kind,
                StorageKey = key,
                ContentType =
                    mp4 ? "video/mp4"
                    : png ? "image/png"
                    : "image/jpeg",
                SizeBytes = length,
                OriginalName = Path.GetFileName(filename),
            };
            try
            {
                await files.Write(key, staged, ct);
                Add(asset);
                await Store.SaveAsync();
            }
            catch
            {
                files.Delete(key);
                throw;
            }

            return asset;
        }
        finally
        {
            File.Delete(temp);
        }
    }

    public async Task<MediaDownload> Download(string id, string? childId)
    {
        var a = await Get<MediaAsset>(id);
        if (a.Kind == "product_image" && Actor.Role != "admin" && a.OwnerId != Actor.Id)
            return await ProductImage(id);
        if (Actor.Role != "admin" && a.OwnerId != Actor.Id)
        {
            if (a.Kind == "drawing")
            {
                var sub =
                    await Q<DrawingSubmission>().FirstOrDefaultAsync(x => x.ImageAssetId == id)
                    ?? throw new BusinessException(404, "Media not found.");
                await learning.EnsureSubmissionAccess(sub);
            }
            else
            {
                var lesson =
                    await Q<Lesson>().FirstOrDefaultAsync(x => x.VideoAssetId == id)
                    ?? throw new BusinessException(404, "Media not found.");
                var c = await Get<Course>(lesson.CourseId);
                if (c.InstructorId != Actor.Id)
                {
                    Require(childId is not null, "childId is required.");
                    await RequireEnrollment(childId!, c.Id);
                }
            }
        }

        return ReadAsset(a);
    }

    public async Task<MediaDownload> ProductImage(string id)
    {
        var asset = await Get<MediaAsset>(id);
        var url = $"/api/v1/media/products/{id}";
        Require(
            asset.Kind == "product_image"
                && (
                    Actor.Role == "admin"
                    || asset.OwnerId == Actor.Id
                    || await Q<Product>()
                        .AnyAsync(x =>
                            x.IsActive && x.ApprovalStatus == "approved" && x.ThumbnailUrl == url
                        )
                ),
            "Product image not found.",
            404
        );
        return ReadAsset(asset);
    }

    private MediaDownload ReadAsset(MediaAsset a)
    {
        try
        {
            return new(files.Read(a.StorageKey), a.ContentType, a.OriginalName);
        }
        catch (FileNotFoundException)
        {
            throw new BusinessException(404, "File is not present in storage.");
        }
    }
}
