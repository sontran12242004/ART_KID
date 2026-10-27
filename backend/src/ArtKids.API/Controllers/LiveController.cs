using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1/live"), Authorize]
public sealed class LiveController(LiveService service) : ControllerBase
{
    [HttpGet("classes")]
    public async Task<IActionResult> Classes(int page = 1, int pageSize = 20)
    {
        return Ok(await service.Classes(page, pageSize));
    }

    [HttpGet("classes/{id}")]
    public async Task<IActionResult> Class(string id)
    {
        return Ok(await service.Class(id));
    }

    [HttpPut("classes/{id}"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> UpdateClass(string id, LiveClassUpdateRequest r)
    {
        return Ok(await service.UpdateClass(id, r));
    }

    [HttpPost("classes"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> CreateClass(LiveClassRequest r)
    {
        return Ok(await service.CreateClass(r));
    }

    [HttpPost("classes/{id}/enrollments"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Enroll(string id, ClassEnrollmentRequest r)
    {
        return Ok(await service.Enroll(id, r));
    }

    [HttpDelete("classes/{id}/enrollments/{childId}"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Cancel(string id, string childId)
    {
        return Ok(await service.CancelEnrollment(id, childId));
    }

    [HttpGet("classes/{id}/roster"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> Roster(string id)
    {
        return Ok(await service.Roster(id));
    }

    [HttpGet("classes/{id}/sessions")]
    public async Task<IActionResult> Sessions(string id)
    {
        return Ok(await service.Sessions(id));
    }

    [HttpPost("classes/{id}/sessions"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> CreateSession(string id, LiveSessionRequest r)
    {
        return Ok(await service.SaveSession(id, null, r));
    }

    [HttpPut("classes/{id}/sessions/{sessionId}"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> UpdateSession(
        string id,
        string sessionId,
        LiveSessionRequest r
    )
    {
        return Ok(await service.SaveSession(id, sessionId, r));
    }

    [HttpPost("sessions/{id}/state"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> State(string id, SessionStateRequest r)
    {
        return Ok(await service.SetState(id, r));
    }

    [HttpPost("sessions/{id}/join")]
    public async Task<IActionResult> Join(string id, ClassEnrollmentRequest? r)
    {
        return Ok(await service.Join(id, r?.ChildId));
    }

    [HttpPost("sessions/{id}/leave"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Leave(string id, ClassEnrollmentRequest r)
    {
        return Ok(await service.Leave(id, r.ChildId));
    }

    [HttpGet("sessions/{id}/attendance"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> Attendance(string id)
    {
        return Ok(await service.Attendance(id));
    }
}
