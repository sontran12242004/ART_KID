using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

public sealed record CarrierUpdate(string ShipmentId, string Status);

[ApiController, Route("api/v1/fulfillment/webhook")]
public sealed class WebhookController(InventoryService service, IConfiguration config)
    : ControllerBase
{
    [HttpPost, RequestSizeLimit(65536)]
    public async Task<IActionResult> Update()
    {
        var key = config["Carriers:WebhookSecret"];
        if (string.IsNullOrWhiteSpace(key))
            return StatusCode(503, new { error = "Carrier webhook is not configured." });
        var timestamp = Request.Headers["X-ArtKids-Timestamp"].ToString();
        if (
            !long.TryParse(timestamp, out var seconds)
            || Math.Abs(DateTimeOffset.UtcNow.ToUnixTimeSeconds() - seconds) > 300
        )
            return Unauthorized();
        using var reader = new StreamReader(Request.Body);
        var body = await reader.ReadToEndAsync();
        var expected = HMACSHA256.HashData(
            Encoding.UTF8.GetBytes(key),
            Encoding.UTF8.GetBytes(timestamp + "." + body)
        );
        byte[] signature;
        try
        {
            signature = Convert.FromHexString(Request.Headers["X-ArtKids-Signature"].ToString());
        }
        catch (FormatException)
        {
            return Unauthorized();
        }

        if (!CryptographicOperations.FixedTimeEquals(expected, signature))
            return Unauthorized();
        CarrierUpdate? update;
        try
        {
            update = JsonSerializer.Deserialize<CarrierUpdate>(
                body,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
            );
        }
        catch (JsonException)
        {
            return BadRequest();
        }

        if (
            update is null
            || string.IsNullOrWhiteSpace(update.ShipmentId)
            || update.Status is not ("shipping" or "delivered" or "returned")
        )
            return BadRequest();
        return Ok(await service.ApplyWebhook(update.ShipmentId, update.Status));
    }
}
