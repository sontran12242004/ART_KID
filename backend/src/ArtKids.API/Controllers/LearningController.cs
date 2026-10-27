using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1"), Authorize]
public sealed class LearningController(LearningService service) : ControllerBase
{
    [HttpGet("grading/courses"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> GradingCourses() => Ok(await service.GradingCourses());

    [HttpGet("grading/courses/{id}/lessons"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> GradingLessons(string id) => Ok(await service.GradingLessons(id));

    [HttpGet("grading/lessons/{id}/submissions"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> GradingSubmissions(string id, bool pendingOnly = true, int page = 1)
        => Ok(await service.GradingSubmissions(id, pendingOnly, page));

    [HttpGet("courses"), AllowAnonymous]
    public async Task<IActionResult> Courses(int page = 1, int pageSize = 20, string? search = null)
    {
        return Ok(await service.Courses(page, pageSize, search));
    }

    [HttpGet("courses/{id}"), AllowAnonymous]
    public async Task<IActionResult> Course(string id)
    {
        return Ok(await service.Course(id));
    }

    [HttpPost("courses"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> CreateCourse(CourseRequest r)
    {
        return Ok(await service.SaveCourse(null, r));
    }

    [HttpPut("courses/{id}"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> UpdateCourse(string id, CourseRequest r)
    {
        return Ok(await service.SaveCourse(id, r));
    }

    [HttpGet("courses/{id}/lessons"), AllowAnonymous]
    public async Task<IActionResult> Lessons(string id, string? childId = null)
    {
        return Ok(await service.Lessons(id, childId));
    }

    [HttpDelete("courses/{id}"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> DeleteCourse(string id)
    {
        await service.DeleteCourse(id);
        return NoContent();
    }

    [HttpGet("lessons/{id}")]
    public async Task<IActionResult> Lesson(string id, string? childId = null)
    {
        return Ok(await service.Lesson(id, childId));
    }

    [HttpPost("courses/{id}/lessons"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> CreateLesson(string id, LessonRequest r)
    {
        return Ok(await service.SaveLesson(id, null, r));
    }

    [HttpPut("courses/{id}/lessons/{lessonId}"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> UpdateLesson(string id, string lessonId, LessonRequest r)
    {
        return Ok(await service.SaveLesson(id, lessonId, r));
    }

    [HttpPost("enrollments"), Authorize(Roles = "parent,admin")]
    public async Task<IActionResult> Enroll(EnrollmentRequest r)
    {
        return Ok(await service.Enroll(r));
    }

    [HttpGet("courses/progress")]
    public async Task<IActionResult> Progress(string childId)
    {
        return Ok(await service.Progress(childId));
    }

    [HttpPost("courses/progress")]
    public async Task<IActionResult> SaveProgress(ProgressRequest r)
    {
        return Ok(await service.SaveProgress(r));
    }

    [HttpGet("family/submission-browser"), Authorize(Roles = "parent")]
    public async Task<IActionResult> FamilySubmissionBrowser(string childId, string? courseId = null,
        string? lessonId = null, bool unassigned = false, string? status = null, int page = 1)
        => Ok(await service.FamilySubmissionBrowser(childId, courseId, lessonId, unassigned, status, page));

    [HttpGet("kid/submissions")]
    public async Task<IActionResult> Submissions(
        string? childId = null,
        int page = 1,
        int pageSize = 20
    )
    {
        return Ok(await service.Submissions(childId, page, pageSize));
    }

    [HttpPost("kid/submissions"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Submit(SubmissionRequest r)
    {
        return Ok(await service.Submit(r));
    }

    [HttpGet("kid/submissions/{id}")]
    public async Task<IActionResult> Submission(string id)
    {
        return Ok(await service.Submission(id));
    }

    [HttpPost("kid/submissions/{id}/reviews"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> Review(string id, ReviewRequest r)
    {
        return Ok(await service.Review(id, r));
    }

    [HttpGet("children/{id}/badges")]
    public async Task<IActionResult> Badges(string id)
    {
        return Ok(await service.Badges(id));
    }
}
