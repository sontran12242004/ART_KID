using System.ComponentModel.DataAnnotations;
using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

public sealed record GenerateRequest([Required] string SubmissionId);

[ApiController, Route("api/v1"), Authorize]
public sealed class CreativeController(AiService ai, GameService games) : ControllerBase
{
    [HttpPost("ai/generate"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Generate(GenerateRequest r)
    {
        return Accepted(await ai.Create(r.SubmissionId));
    }

    [HttpGet("ai/jobs/{id}")]
    public async Task<IActionResult> Job(string id)
    {
        return Ok(await ai.Job(id));
    }

    [HttpGet("ai/creatures")]
    public async Task<IActionResult> Creatures(string childId, int page = 1, int pageSize = 20)
    {
        return Ok(await ai.Creatures(childId, page, pageSize));
    }

    [HttpGet("game/picture-sets"), AllowAnonymous]
    public async Task<IActionResult> PictureSets()
    {
        return Ok(await games.PictureSets());
    }

    [HttpGet("game/picture-sets/{id}"), AllowAnonymous]
    public async Task<IActionResult> PictureSet(string id)
    {
        return Ok(await games.PictureSet(id));
    }

    [HttpPost("game/picture-sets"), Authorize(Roles = "admin")]
    public async Task<IActionResult> CreatePictureSet(PictureSetRequest r)
    {
        return Ok(await games.CreatePictureSet(r));
    }

    [HttpGet("children/{childId}/game/{setId}")]
    public async Task<IActionResult> Progress(string childId, string setId)
    {
        return Ok(await games.Progress(childId, setId));
    }

    [HttpPut("children/{childId}/game/{setId}")]
    public async Task<IActionResult> SaveProgress(
        string childId,
        string setId,
        GameProgressRequest r
    )
    {
        return Ok(await games.SaveProgress(childId, setId, r));
    }

    [HttpPost("children/{childId}/game/{setId}/complete")]
    public async Task<IActionResult> Complete(string childId, string setId)
    {
        return Ok(await games.Complete(childId, setId));
    }

    [HttpGet("children/{childId}/gallery")]
    public async Task<IActionResult> Gallery(string childId, int page = 1, int pageSize = 20)
    {
        return Ok(await games.Gallery(childId, page, pageSize));
    }

    [HttpGet("children/{childId}/rewards")]
    public async Task<IActionResult> Rewards(string childId)
    {
        return Ok(await games.Rewards(childId));
    }
}
