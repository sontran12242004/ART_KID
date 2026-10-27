"""Exercise course edit/delete and related-product popup against local Flutter + API."""

import base64
import re
import time
from pathlib import Path

from playwright.sync_api import expect, sync_playwright
from frontend_smoke import fill_field, log, open_page


def open_last_course(page):
    related = page.get_by_role("button", name="Xem học cụ liên quan", exact=True)
    page.wait_for_timeout(500)
    if related.count() and related.last.is_visible():
        return
    edit = page.get_by_role("button", name="Chỉnh sửa khóa học", exact=True).last
    edit.wait_for(state="visible")
    bounds = edit.bounding_box()
    page.mouse.click(100, bounds["y"] + bounds["height"] / 2)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "instructor")
        course_icons = page.get_by_role("button", name="Chỉnh sửa khóa học", exact=True)
        course_icons.first.wait_for(state="visible")
        initial_count = course_icons.count()
        title = f"zz UI course {int(time.time())}"
        page.get_by_role("button", name="Tạo khóa học", exact=True).click()
        fill_field(page, "Tên khóa học", title)
        fill_field(page, "Mô tả", "Course management test")
        with page.expect_response(
            lambda r: r.request.method == "POST" and r.url.endswith("/courses")
        ) as created:
            page.get_by_role("button", name="Tiếp tục", exact=True).click()
        assert created.value.status == 200, created.value.text()
        cid = created.value.json()["id"]
        expect(course_icons).to_have_count(initial_count + 1)
        page.wait_for_timeout(500)
        page.get_by_role("button", name="Chỉnh sửa khóa học", exact=True).last.click()
        edited_title = title + " edited"
        fill_field(page, "Tên khóa học", edited_title)
        with page.expect_response(
            lambda r: r.request.method == "PUT" and r.url.endswith("/courses/" + cid)
        ) as edited:
            page.get_by_role("button", name="Tiếp tục", exact=True).click()
        assert edited.value.status == 200
        assert edited.value.json()["title"] == edited_title
        open_last_course(page)
        with page.expect_response(
            lambda r: r.request.method == "GET" and r.url.endswith(f"/courses/{cid}/products")
        ) as empty:
            page.get_by_role("button", name="Xem học cụ liên quan", exact=True).click()
        assert empty.value.status == 200 and empty.value.json() == []
        expect(page.get_by_role("button", name="Chỉnh sửa học cụ", exact=True)).to_have_count(0)
        page.get_by_role("button", name="Đóng danh sách học cụ", exact=True).click()
        log("PASS course edit icon and empty related-product popup")

        page.get_by_role("button", name="Đăng bán học cụ", exact=True).click()
        png = page.evaluate("""() => {
            const c=document.createElement('canvas'); c.width=320; c.height=180;
            const ctx=c.getContext('2d'); ctx.fillStyle='#2a9d8f'; ctx.fillRect(0,0,320,180);
            return c.toDataURL('image/png').split(',')[1];
        }""")
        with page.expect_file_chooser() as chooser:
            page.get_by_role("button", name="Chọn hình ảnh học cụ", exact=True).click()
        chooser.value.set_files(
            {"name": "kit.png", "mimeType": "image/png", "buffer": base64.b64decode(png)}
        )
        product_title = "Popup kit " + str(int(time.time()))
        fill_field(page, "Tiêu đề học cụ", product_title)
        fill_field(page, "Giá bán (VNĐ)", "125000")
        fill_field(page, "Mô tả công dụng", "Brushes and paints for the course")
        fill_field(page, "Số lượng có sẵn", "5")
        with page.expect_response(
            lambda r: r.request.method == "POST" and r.url.endswith(f"/courses/{cid}/products")
        ) as product:
            page.get_by_role("button", name="Đăng bán học cụ", exact=True).click()
        assert product.value.status == 200, product.value.text()
        pid = product.value.json()["id"]
        open_last_course(page)
        with page.expect_response(
            lambda r: r.request.method == "GET" and r.url.endswith(f"/courses/{cid}/products")
        ) as listing:
            page.get_by_role("button", name="Xem học cụ liên quan", exact=True).click()
        assert listing.value.json()[0]["product"]["name"] == product_title
        page.get_by_role("button", name="Chỉnh sửa học cụ", exact=True).click()
        updated_product_title = product_title + " updated"
        fill_field(page, "Tiêu đề học cụ", updated_product_title)
        fill_field(page, "Giá bán (VNĐ)", "199000")
        fill_field(page, "Mô tả công dụng", "Updated usage description")
        fill_field(page, "Số lượng có sẵn", "4")
        product_path = f"/courses/{cid}/products/{pid}"
        with page.expect_response(
            lambda r: r.request.method == "PUT" and r.url.endswith(product_path)
        ) as saved:
            page.get_by_role("button", name="Lưu thay đổi", exact=True).click()
        assert saved.value.status == 200, saved.value.text()
        assert saved.value.json()["name"] == updated_product_title
        assert saved.value.json()["description"] == "Updated usage description"
        expect(page.get_by_role("button", name="Chỉnh sửa học cụ", exact=True)).to_be_visible()
        Path("backend/tests/artifacts").mkdir(exist_ok=True)
        page.screenshot(path="backend/tests/artifacts/course-products-popup.png")
        log("PASS product details and editing inside nested popup")

        page.get_by_role("button", name="Xóa học cụ", exact=True).click()
        page.get_by_role("button", name="Hủy", exact=True).click()
        expect(page.get_by_role("button", name="Chỉnh sửa học cụ", exact=True)).to_be_visible()
        page.get_by_role("button", name="Xóa học cụ", exact=True).click()
        with page.expect_response(
            lambda r: r.request.method == "DELETE" and r.url.endswith(product_path)
        ) as deleted_product:
            page.get_by_role("button", name="Xác nhận", exact=True).click()
        assert deleted_product.value.status == 204
        expect(page.get_by_role("button", name="Chỉnh sửa học cụ", exact=True)).to_have_count(0)
        page.get_by_role("button", name="Đóng danh sách học cụ", exact=True).click()
        page.get_by_role("button", name="Xóa khóa học", exact=True).last.click()
        page.get_by_role("button", name="Hủy", exact=True).click()
        expect(course_icons).to_have_count(initial_count + 1)
        page.get_by_role("button", name="Xóa khóa học", exact=True).last.click()
        with page.expect_response(
            lambda r: r.request.method == "DELETE" and r.url.endswith("/courses/" + cid)
        ) as deleted_course:
            page.get_by_role("button", name="Xác nhận", exact=True).click()
        assert deleted_course.value.status == 204
        expect(course_icons).to_have_count(initial_count)
        log("PASS cancel confirmations, product delete and course delete")
        browser.close()


if __name__ == "__main__":
    main()
