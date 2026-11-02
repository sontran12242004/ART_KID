using System.Text;
using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1/live"), Authorize]
public sealed class LiveController(LiveService service) : ControllerBase
{
    [HttpGet("classes")]
    public async Task<IActionResult> Classes(
        int page = 1,
        int pageSize = 20,
        string? childId = null
    )
    {
        return Ok(await service.Classes(page, pageSize, childId));
    }

    [HttpGet("sessions")]
    public async Task<IActionResult> AccessibleSessions(
        string? status = null,
        string? childId = null,
        string? classId = null,
        int page = 1,
        int pageSize = 20
    )
    {
        return Ok(await service.AccessibleSessions(status, childId, classId, page, pageSize));
    }

    [HttpGet("sessions/{id}")]
    public async Task<IActionResult> SessionDetail(string id, string? childId = null)
    {
        return Ok(await service.SessionDetail(id, childId));
    }

    [HttpPost("sessions/{id}/room/token")]
    public async Task<IActionResult> IssueRoomToken(string id, LiveRoomTokenRequest? r = null)
    {
        return Ok(await service.IssueRoomToken(id, r));
    }

    [HttpPost("sessions/{id}/room/connect")]
    public async Task<IActionResult> ConnectRoom(string id, LiveRoomConnectRequest r)
    {
        return Ok(await service.ConnectRoom(id, r));
    }

    [HttpPost("sessions/{id}/room/state")]
    public async Task<IActionResult> SyncRoomState(string id, LiveRoomMediaStateRequest r)
    {
        return Ok(await service.SyncRoomState(id, r));
    }

    [HttpPost("sessions/{id}/room/moderate"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> ModerateRoomParticipant(string id, LiveRoomModerateRequest r)
    {
        return Ok(await service.ModerateRoomParticipant(id, r));
    }

    [HttpPost("sessions/{id}/room/screen-share/permission"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> SetScreenSharePermission(
        string id,
        LiveRoomScreenSharePermissionRequest r
    )
    {
        return Ok(await service.SetScreenSharePermission(id, r));
    }

    [HttpPost("sessions/{id}/room/screen-share/start")]
    public async Task<IActionResult> StartScreenShare(string id, LiveRoomScreenShareStartRequest r)
    {
        return Ok(await service.StartScreenShare(id, r));
    }

    [HttpPost("sessions/{id}/room/screen-share/frame")]
    public async Task<IActionResult> UpdateScreenShareFrame(
        string id,
        LiveRoomScreenShareFrameRequest r
    )
    {
        return Ok(await service.UpdateScreenShareFrame(id, r));
    }

    [HttpPost("sessions/{id}/room/screen-share/stop")]
    public async Task<IActionResult> StopScreenShare(string id, LiveRoomScreenShareStopRequest r)
    {
        return Ok(await service.StopScreenShare(id, r));
    }

    [HttpPost("sessions/{id}/room/disconnect")]
    public async Task<IActionResult> DisconnectRoom(string id, LiveRoomDisconnectRequest? r = null)
    {
        return Ok(await service.DisconnectRoom(id, r));
    }

    [HttpPost("sessions/{id}/room/end"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> EndRoomSession(string id, LiveRoomEndSessionRequest? r = null)
    {
        return Ok(await service.EndRoomSession(id, r));
    }

    [HttpPost("webhooks/livekit"), AllowAnonymous]
    public async Task<IActionResult> LiveKitWebhook()
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var rawBody = await reader.ReadToEndAsync();
        var authHeader = Request.Headers.Authorization.FirstOrDefault();
        return Ok(await service.HandleLiveKitWebhook(authHeader, rawBody));
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
