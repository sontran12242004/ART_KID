using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1/auth"), Authorize]
public sealed class AuthController(AuthService service) : ControllerBase
{
    [HttpPost("register"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Register(RegisterRequest r)
    {
        return Ok(await service.Register(r));
    }

    [HttpPost("login"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(LoginRequest r)
    {
        return Ok(await service.Login(r));
    }

    [HttpPost("refresh"), AllowAnonymous, EnableRateLimiting("auth")]
    public async Task<IActionResult> Refresh(RefreshRequest r)
    {
        return Ok(await service.Refresh(r));
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout(RefreshRequest r)
    {
        await service.Logout(r);
        return NoContent();
    }

    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        return Ok(await service.Me());
    }

    [HttpPut("me")]
    public async Task<IActionResult> Update(UserProfileRequest r)
    {
        return Ok(await service.UpdateProfile(r));
    }

    [HttpPost("kid-pin/update"), EnableRateLimiting("auth")]
    public async Task<IActionResult> SetPin(SetPinRequest r)
    {
        await service.SetPin(r);
        return NoContent();
    }

    [HttpPost("kid-pin/verify"), EnableRateLimiting("auth")]
    public async Task<IActionResult> VerifyPin(PinRequest r)
    {
        return Ok(await service.VerifyPin(r));
    }

    [HttpGet("staff"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Staff(int page = 1, int pageSize = 20)
    {
        return Ok(await service.Staff(page, pageSize));
    }

    [HttpPost("staff"), Authorize(Roles = "admin")]
    public async Task<IActionResult> CreateStaff(StaffRequest r)
    {
        return Ok(await service.CreateStaff(r));
    }
}
