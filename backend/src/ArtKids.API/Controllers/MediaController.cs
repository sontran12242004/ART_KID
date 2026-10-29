using System.ComponentModel.DataAnnotations;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

public sealed class UploadRequest
{
    [Required]
    public required IFormFile File { get; set; }

    [Required]
    public required string Kind { get; set; }
    public string? ChildId { get; set; }
}

[ApiController, Route("api/v1/media"), Authorize]
public sealed class MediaController(MediaService service) : ControllerBase
{
    [HttpPost("upload"), RequestSizeLimit(315_000_000)]
    public async Task<IActionResult> Upload([FromForm] UploadRequest r, CancellationToken ct)
    {
        await using var stream = r.File.OpenReadStream();
        var asset = await service.Upload(
            stream,
            r.File.Length,
            r.File.FileName,
            r.Kind,
            r.ChildId,
            ct
        );
        return Ok(
            new
            {
                asset.Id,
                asset.Kind,
                asset.ContentType,
                asset.SizeBytes,
                url = asset.Kind == "product_image"
                    ? $"/api/v1/media/products/{asset.Id}"
                    : $"/api/v1/media/{asset.Id}",
            }
        );
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Download(string id, string? childId = null)
    {
        Response.Headers.CacheControl = "private, no-store";
        var file = await service.Download(id, childId);
        return File(file.Stream, file.ContentType, enableRangeProcessing: true);
    }

    [HttpGet("products/{id}"), AllowAnonymous]
    public async Task<IActionResult> ProductImage(string id)
    {
        Response.Headers.CacheControl = "private, no-store";
        var file = await service.ProductImage(id);
        return File(file.Stream, file.ContentType);
    }
}
