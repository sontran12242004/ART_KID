"""Browser smoke test for instructor course-kit publishing; local development only."""

import base64
import re
import time
from pathlib import Path

from playwright.sync_api import expect, sync_playwright
from frontend_smoke import fill_field, go, log, open_page


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        teacher = open_page(browser, "instructor")
        teacher.get_by_text("Vẽ cơ bản", exact=True).click()
        teacher.get_by_role("button", name="Đăng bán học cụ", exact=True).click()
        expect(teacher.get_by_role("heading", name="Đăng bán học cụ")).to_be_visible()
        preview = teacher.evaluate("""() => {
            const canvas = document.createElement('canvas');
            canvas.width = 400;
            canvas.height = 240;
            const ctx = canvas.getContext('2d');
            ctx.fillStyle = '#e5f7f3';
            ctx.fillRect(0, 0, 400, 240);
            ['#ef6351', '#ffbc42', '#2a9d8f', '#6c63a8'].forEach((color, index) => {
                ctx.fillStyle = color;
                ctx.fillRect(60 + index * 75, 50, 45, 130);
            });
            return canvas.toDataURL('image/png').split(',')[1];
        }""")
        with teacher.expect_file_chooser() as chooser:
            teacher.get_by_role("button", name="Chọn hình ảnh học cụ", exact=True).click()
        chooser.value.set_files(
            {"name": "course-kit.png", "mimeType": "image/png", "buffer": base64.b64decode(preview)}
        )
        title = f"Học cụ màu nước kiểm thử {int(time.time())}"
        fill_field(teacher, "Tiêu đề học cụ", title)
        fill_field(teacher, "Giá bán (VNĐ)", "125000")
        fill_field(
            teacher, "Mô tả công dụng", "Bộ màu và cọ giúp bé luyện phối màu trong khóa học."
        )
        Path("backend/tests/artifacts").mkdir(exist_ok=True)
        teacher.screenshot(path="backend/tests/artifacts/course-product-form.png")
        with teacher.expect_response(
            lambda r: r.request.method == "POST"
            and r.url.endswith("/marketplace/listings")
        ) as published:
            teacher.get_by_role("button", name="Gửi duyệt", exact=True).click()
        assert published.value.status == 200, published.value.text()
        product = published.value.json()
        assert product["courseId"] == "course_basics"
        image_url = "http://localhost:5080" + product["thumbnailUrl"]
        assert product["approvalStatus"] == "pending"
        assert teacher.request.get(image_url).status == 404
        log("PASS instructor submits a pending listing with no public image")
        admin = open_page(browser, "admin")
        go(admin, "/staff/marketplace/reviews/" + product["id"])
        with admin.expect_response(lambda r: r.request.method == "POST" and r.url.endswith("/marketplace/reviews/" + product["id"])) as review:
            admin.get_by_role("button", name="Phê duyệt", exact=True).click()
        assert review.value.status == 200, review.value.text()
        assert teacher.request.get(image_url).status == 200
        admin.screenshot(path="backend/tests/artifacts/marketplace-admin-review.png")
        log("PASS admin approval makes the listing and image public")

        parent = open_page(browser, "parent")
        go(parent, "/parent/courses/course_basics/products")
        parent.get_by_role("button", name=re.compile(re.escape(title))).click()
        expect(parent.get_by_text(title, exact=False).last).to_be_visible()
        with parent.expect_response(
            lambda r: r.request.method == "PUT" and r.url.endswith("/commerce/cart/items")
        ) as cart:
            parent.get_by_role("button", name=re.compile("Thêm.*giỏ", re.IGNORECASE)).click()
        assert cart.value.status == 200
        assert any(item["productId"] == product["id"] for item in cart.value.json()["items"])
        go(parent, "/parent/shop/cart")
        parent.get_by_role("button", name=re.compile("Tiến hành thanh toán")).click()
        fill_field(parent, "Tên người nhận", "Phụ huynh kiểm thử")
        fill_field(parent, "Số điện thoại", "0901234567")
        fill_field(parent, "Địa chỉ nhận học cụ (bắt buộc khi có bộ kit)", "123 Test Street")
        with parent.expect_response(
            lambda r: r.request.method == "POST" and r.url.endswith("/commerce/checkout")
        ) as checkout:
            parent.get_by_role("button", name="Đặt hàng", exact=False).click()
        assert checkout.value.status == 200, checkout.value.text()
        assert any(item["productId"] == product["id"] for item in checkout.value.json()["items"])
        parent.screenshot(path="backend/tests/artifacts/course-product-order.png")
        log("PASS parent views course kit, adds it to cart and places a real order")
        browser.close()


if __name__ == "__main__":
    main()
