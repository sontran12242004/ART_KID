using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1"), Authorize]
public sealed class FamilyController(FamilyService service) : ControllerBase
{
    [HttpGet("children")]
    public async Task<IActionResult> Children()
    {
        return Ok(await service.Children());
    }

    [HttpGet("children/{id}")]
    public async Task<IActionResult> Child(string id)
    {
        return Ok(await service.Child(id));
    }

    [HttpPost("children"), Authorize(Roles = "parent")]
    public async Task<IActionResult> CreateChild(ChildRequest r)
    {
        return Ok(await service.SaveChild(null, r));
    }

    [HttpPut("children/{id}"), Authorize(Roles = "parent")]
    public async Task<IActionResult> UpdateChild(string id, ChildRequest r)
    {
        return Ok(await service.SaveChild(id, r));
    }

    [HttpGet("avatars"), AllowAnonymous]
    public async Task<IActionResult> Avatars()
    {
        return Ok(await service.Avatars());
    }

    [HttpPost("auth/consent"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Consent(ConsentRequest r)
    {
        return Ok(await service.Consent(r));
    }

    [HttpGet("children/{id}/consents")]
    public async Task<IActionResult> Consents(string id)
    {
        return Ok(await service.Consents(id));
    }

    [HttpDelete("consents/{id}")]
    public async Task<IActionResult> RevokeConsent(string id)
    {
        await service.RevokeConsent(id);
        return NoContent();
    }

    [HttpGet("children/{id}/dashboard")]
    public async Task<IActionResult> Dashboard(string id)
    {
        return Ok(await service.Dashboard(id));
    }

    [HttpGet("notifications")]
    public async Task<IActionResult> Notifications(int page = 1, int pageSize = 20)
    {
        return Ok(await service.Notifications(page, pageSize));
    }

    [HttpPost("notifications/{id}/read")]
    public async Task<IActionResult> Read(string id)
    {
        await service.ReadNotification(id);
        return NoContent();
    }
}
