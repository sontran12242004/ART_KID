using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1"), Authorize]
public sealed class InventoryController(InventoryService service) : ControllerBase
{
    [HttpGet("inventory/stock"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Stock(int page = 1, int pageSize = 20)
    {
        return Ok(await service.Stock(page, pageSize));
    }

    [HttpGet("inventory/stock/{sku}"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Sku(string sku)
    {
        return Ok(await service.BySku(sku));
    }

    [HttpPost("inventory/stock"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Create(InventoryRequest r)
    {
        return Ok(await service.Create(r));
    }

    [HttpPost("inventory/stock/{id}/adjust"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Adjust(string id, StockAdjustmentRequest r)
    {
        return Ok(await service.Adjust(id, r));
    }

    [HttpGet("fulfillment/shipments")]
    public async Task<IActionResult> Shipments(int page = 1, int pageSize = 20)
    {
        return Ok(await service.Shipments(page, pageSize));
    }

    [HttpPost("fulfillment/shipments"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Shipment(ShipmentRequest r)
    {
        return Ok(await service.CreateShipment(r));
    }

    [HttpGet("fulfillment/tracking/{trackingNumber}")]
    public async Task<IActionResult> Track(string trackingNumber)
    {
        return Ok(await service.Track(trackingNumber));
    }

    [HttpPost("fulfillment/shipments/{id}/status"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Status(string id, ShipmentStatusRequest r)
    {
        return Ok(await service.UpdateStatus(id, r.Status));
    }
}
