using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1/admin"), Authorize(Roles = "admin")]
public sealed class AdminController(CommerceService service) : ControllerBase
{
    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard() => Ok(await service.AdminDashboard());
}
