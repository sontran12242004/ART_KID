using System.Text.Json;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1/payments/vnpay")]
public sealed class VnpayController(VnpayService service, ILogger<VnpayController> logger)
    : ControllerBase
{
    [HttpGet("config"), Authorize(Roles = "parent")]
    public IActionResult Config() => Ok(new { isConfigured = service.IsConfigured });

    [HttpGet("orders/{id}"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Status(string id) => Ok(await service.Status(id));

    [HttpPost("orders/{id}/url"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Create(string id) =>
        Ok(
            await service.Create(
                id,
                HttpContext.Connection.RemoteIpAddress?.MapToIPv4().ToString() ?? "127.0.0.1"
            )
        );

    private Dictionary<string, string>? Parameters() =>
        Request.Query.Any(x => x.Value.Count != 1)
            ? null
            : Request.Query.ToDictionary(
                x => x.Key,
                x => x.Value.ToString(),
                StringComparer.Ordinal
            );

    [HttpGet("ipn"), AllowAnonymous]
    public async Task<IActionResult> Ipn()
    {
        (string Code, string Message) result;
        try
        {
            var data = Parameters();
            result = data is null ? ("97", "Invalid parameters") : await service.Ipn(data);
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "VNPay IPN processing failed; gateway should retry.");
            result = ("99", "Processing error; retry later");
        }
        return Content(
            JsonSerializer.Serialize(new { RspCode = result.Code, Message = result.Message }),
            "application/json"
        );
    }

    [HttpGet("return"), AllowAnonymous]
    public async Task<IActionResult> Return()
    {
        var data = Parameters() ?? new Dictionary<string, string>();
        return Redirect(await service.ReturnUrl(data));
    }
}
