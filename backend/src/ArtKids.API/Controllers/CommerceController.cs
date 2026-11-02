using ArtKids.BLL.Contracts;
using ArtKids.BLL.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ArtKids.API.Controllers;

[ApiController, Route("api/v1"), Authorize]
public sealed class CommerceController(CommerceService service) : ControllerBase
{
    [HttpGet("shop/products"), AllowAnonymous]
    public async Task<IActionResult> Products(
        int page = 1,
        int pageSize = 20,
        string? search = null,
        string? category = null,
        string? courseId = null
    )
    {
        return Ok(await service.Products(page, pageSize, search, category, courseId));
    }

    [HttpPost("courses/{courseId}/products"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> CreateCourseProduct(string courseId, CourseProductRequest r)
    {
        return Ok(await service.CreateCourseProduct(courseId, r));
    }

    [HttpGet("shop/products/{id}"), AllowAnonymous]
    public async Task<IActionResult> Product(string id)
    {
        return Ok(await service.Product(id));
    }

    [HttpGet("courses/{courseId}/products"), Authorize(Roles = "admin,instructor")]
    public async Task<IActionResult> CourseProducts(string courseId)
    {
        return Ok(await service.CourseProducts(courseId));
    }

    [HttpPut("courses/{courseId}/products/{productId}"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> UpdateCourseProduct(
        string courseId,
        string productId,
        CourseProductUpdateRequest r
    )
    {
        return Ok(await service.UpdateCourseProduct(courseId, productId, r));
    }

    [HttpDelete("courses/{courseId}/products/{productId}"), Authorize(Roles = "instructor")]
    public async Task<IActionResult> DeleteCourseProduct(string courseId, string productId)
    {
        await service.DeleteCourseProduct(courseId, productId);
        return NoContent();
    }

    [HttpPost("shop/products"), Authorize(Roles = "admin")]
    public async Task<IActionResult> CreateProduct(ProductRequest r)
    {
        return Ok(await service.SaveProduct(null, r));
    }

    [HttpPut("shop/products/{id}"), Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdateProduct(string id, ProductRequest r)
    {
        return Ok(await service.SaveProduct(id, r));
    }

    [HttpGet("commerce/plans"), AllowAnonymous]
    public async Task<IActionResult> Plans()
    {
        return Ok(await service.Plans());
    }

    [HttpPost("commerce/plans"), Authorize(Roles = "admin")]
    public async Task<IActionResult> CreatePlan(PlanRequest r)
    {
        return Ok(await service.SavePlan(null, r));
    }

    [HttpPut("commerce/plans/{id}"), Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdatePlan(string id, PlanRequest r)
    {
        return Ok(await service.SavePlan(id, r));
    }

    [HttpGet("commerce/cart"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Cart()
    {
        return Ok(await service.Cart());
    }

    [HttpPut("commerce/cart/items"), Authorize(Roles = "parent")]
    public async Task<IActionResult> CartItem(CartItemRequest r)
    {
        return Ok(await service.SetCartItem(r));
    }

    [HttpGet("vouchers/available")]
    public async Task<IActionResult> Vouchers()
    {
        return Ok(await service.Vouchers());
    }

    [HttpPost("vouchers/validate")]
    public async Task<IActionResult> ValidateVoucher(VoucherValidateRequest r)
    {
        return Ok(await service.ValidateVoucher(r));
    }

    [HttpPost("vouchers"), Authorize(Roles = "admin")]
    public async Task<IActionResult> CreateVoucher(VoucherRequest r)
    {
        return Ok(await service.SaveVoucher(null, r));
    }

    [HttpPut("vouchers/{id}"), Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdateVoucher(string id, VoucherRequest r)
    {
        return Ok(await service.SaveVoucher(id, r));
    }

    [HttpPost("commerce/checkout"), Authorize(Roles = "parent")]
    public async Task<IActionResult> Checkout(CheckoutRequest r)
    {
        return Ok(await service.Checkout(r));
    }

    [HttpGet("commerce/orders")]
    public async Task<IActionResult> Orders(int page = 1, int pageSize = 20)
    {
        return Ok(await service.Orders(page, pageSize));
    }

    [HttpGet("commerce/orders/{id}")]
    public async Task<IActionResult> Order(string id)
    {
        return Ok(await service.OrderDetail(id));
    }

    [HttpPost("commerce/orders/{id}/cancel")]
    public async Task<IActionResult> Cancel(string id, CancelRequest r)
    {
        return Ok(await service.Cancel(id, r.Reason));
    }

    [HttpPost("commerce/orders/{id}/confirm"), Authorize(Roles = "admin")]
    public async Task<IActionResult> Confirm(string id)
    {
        return Ok(await service.Confirm(id));
    }

    [HttpGet("commerce/subscriptions")]
    public async Task<IActionResult> Subscriptions()
    {
        return Ok(await service.Subscriptions());
    }

    [HttpGet("commerce/subscriptions/{id}/kit-deliveries")]
    public async Task<IActionResult> KitDeliveries(string id)
    {
        return Ok(await service.KitDeliveries(id));
    }
}
