using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1/marketplace"), Authorize]
public sealed class MarketplaceController(MarketplaceService service) : ControllerBase
{
    [HttpGet("listings"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Listings(
        int page = 1,
        int pageSize = 20,
        string? courseId = null
    ) => Ok(await service.Listings(page, pageSize, courseId));

    [HttpGet("listings/{id}"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Listing(string id) => Ok(await service.Listing(id));

    [HttpPost("listings"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Create(SellerListingRequest r) =>
        Ok(await service.Save(null, r));

    [HttpPut("listings/{id}"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Update(string id, SellerListingRequest r) =>
        Ok(await service.Save(id, r));

    [HttpPut("listings/{id}/availability"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Availability(string id, ListingAvailabilityRequest r) =>
        Ok(await service.Availability(id, r));

    [HttpDelete("listings/{id}"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Delete(string id)
    {
        await service.Delete(id);
        return NoContent();
    }

    [HttpGet("reviews"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Reviews(int page = 1, int pageSize = 20) =>
        Ok(await service.Reviews(page, pageSize));

    [HttpGet("reviews/{id}"), Authorize(Roles = "admin")]
    public async Task<IActionResult> ReviewDetail(string id) => Ok(await service.ReviewDetail(id));

    [HttpPost("reviews/{id}"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Review(string id, ListingReviewRequest r) =>
        Ok(await service.Review(id, r));

    [HttpGet("orders"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Orders(int page = 1, int pageSize = 20) =>
        Ok(await service.Orders(page, pageSize));

    [HttpGet("orders/{id}"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Order(string id) => Ok(await service.OrderDetail(id));

    [HttpPut("orders/{id}/fulfillment"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> Fulfillment(string id, SellerFulfillmentRequest r) =>
        Ok(await service.Fulfill(id, r));
}
