using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1"), Authorize(Roles = "admin,instructor")]
public sealed class LectureVideosController(CloudinaryVideoService service) : ControllerBase
{
    [HttpGet("media/video-storage")]
    public IActionResult Status() => Ok(service.Status());

    [HttpPost("courses/{courseId}/lessons/video-upload")]
    public async Task<IActionResult> Prepare(string courseId, VideoUploadRequest request) =>
        Ok(await service.Prepare(courseId, request));

    [HttpPost("courses/{courseId}/lessons/video-upload/complete")]
    public async Task<IActionResult> Complete(
        string courseId,
        VideoCompleteRequest request,
        CancellationToken ct
    ) => Ok(await service.Complete(courseId, request, ct));
}
