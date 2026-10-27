"""Real Flutter web + API smoke test. Requires: pip install playwright, Edge.
Start API on 5080 and serve Flutter build/web on 8080 before running.
Writes test submissions/orders to the development database; never run on production.
"""

import os
import re
from pathlib import Path
from playwright.sync_api import sync_playwright, expect

BASE = os.environ.get("ARTKIDS_WEB_URL", "http://localhost:8080")
PASSWORD = "ArtKids-Test-2026!"
def test_drawing_png():
    """Build a visible drawing for local browser tests, instead of one pixel."""
    import struct
    import zlib
    width, height = 320, 240
    pixels = bytearray()
    for y in range(height):
        pixels.append(0)
        for x in range(width):
            if (x - 250) ** 2 + (y - 55) ** 2 < 24 ** 2:
                color = (255, 195, 45)
            elif 80 <= x <= 225 and 110 <= y <= 205:
                color = (70, 170, 200)
            elif 60 <= y < 115 and abs(x - 152) < (y - 45) * 1.4:
                color = (235, 100, 80)
            else:
                color = (255, 255, 255)
            pixels.extend(color)
    def chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data))
    return (bytes([137,80,78,71,13,10,26,10])
            + chunk(b'IHDR', struct.pack('!2I5B', width, height, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(bytes(pixels))) + chunk(b'IEND', b''))


PNG = test_drawing_png()


def log(message):
    print(message.encode("ascii", "backslashreplace").decode(), flush=True)


def open_page(browser, role):
    page = browser.new_page(viewport={"width": 1280, "height": 1100})
    page.set_default_timeout(20000)
    page.on("pageerror", lambda e: log("PAGE ERROR: " + str(e)))
    page.goto(BASE + "/#/parent/login", wait_until="domcontentloaded")
    page.wait_for_selector("flt-semantics-placeholder", state="attached", timeout=45000)
    page.locator("flt-semantics-placeholder").evaluate("(e)=>e.click()")
    page.wait_for_timeout(500)
    page.get_by_role("textbox", name="Email", exact=True).click()
    page.wait_for_timeout(200)
    page.keyboard.type(role + ".test@example.invalid", delay=15)
    page.keyboard.press("Tab")
    page.wait_for_timeout(200)
    page.keyboard.type(PASSWORD, delay=15)
    page.get_by_role("button", name="Đăng Nhập", exact=True).click()
    page.wait_for_url(re.compile(r"/#/(parent|staff)$"))
    return page


def go(page, path):
    page.evaluate("(path)=>{location.hash=path}", path)
    page.wait_for_timeout(700)


def fill_field(page, label, text):
    page.get_by_role("textbox", name=label, exact=True).click()
    page.wait_for_timeout(200)
    page.keyboard.press("Control+A")
    page.wait_for_timeout(100)
    page.keyboard.insert_text(text)
    page.wait_for_timeout(150)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        parent = open_page(browser, "parent")
        expect(parent.get_by_text("Hồ sơ bé đang sử dụng", exact=False)).to_be_visible()
        log("PASS parent login and database dashboard")
        go(parent, "/kid/lesson/lesson_basics_1")
        expect(parent.get_by_text("Nét vẽ đầu tiên", exact=True).last).to_be_visible()
        complete = parent.get_by_role("button", name="Đánh dấu hoàn thành", exact=True)
        if complete.count():
            complete.click()
        expect(parent.get_by_role("button", name="Bài tiếp theo", exact=True)).to_be_visible()
        log("PASS lesson completion")
        go(parent, "/kid/lesson/lesson_basics_1/submit")
        with parent.expect_file_chooser() as chooser:
            parent.get_by_role("button", name="Chọn ảnh bài vẽ", exact=False).click()
        chooser.value.set_files(
            {"name": "browser-test.png", "mimeType": "image/png", "buffer": PNG}
        )
        parent.get_by_role("button", name="Gửi bài cho giáo viên", exact=True).click()
        parent.get_by_role("button", name="Xác nhận", exact=True).click()
        parent.wait_for_url(re.compile(r"/#/parent/submissions$"))
        parent.wait_for_timeout(800)
        go(parent, "/parent/submissions/lessons/lesson_basics_1")
        with parent.expect_response(
            lambda r: r.request.method == "GET" and "/kid/submissions/" in r.url
        ) as details:
            parent.get_by_role("button", name=re.compile("Bo Test \u00b7")).first.click()
        submission_path = "/submissions/" + details.value.json()["submission"]["id"]
        expect(
            parent.locator("flt-semantics").filter(has_text="Bài vẽ và đánh giá").first
        ).to_be_visible()
        log("PASS PNG upload, submission persistence and protected image")
        teacher = open_page(browser, "instructor")
        go(teacher, submission_path)
        teacher.get_by_role("button", name="Chấm điểm & nhận xét", exact=True).click()
        fill_field(teacher, "\u0110i\u1ec3m (0\u201310)", "9.5")
        fill_field(teacher, "Nh\u1eadn x\u00e9t", "Bé vẽ rất tốt, tiếp tục luyện nét nhé!")
        teacher.get_by_role("button", name="Tiếp tục", exact=True).click()
        expect(teacher.get_by_text("9.5/10", exact=False).last).to_be_visible()
        go(parent, "/parent")
        go(parent, submission_path)
        expect(parent.get_by_text("9.5/10", exact=False).last).to_be_visible()
        log("PASS teacher review and parent review visibility")
        go(parent, "/parent/shop/product/prod_kit_animal")
        parent.get_by_role("button", name=re.compile("Thêm.*giỏ", re.IGNORECASE)).click()
        expect(parent.get_by_text(re.compile("Đã thêm.*giỏ hàng"))).to_be_visible()
        go(parent, "/parent/shop/cart")
        parent.get_by_role("button", name=re.compile("Tiến hành thanh toán")).click()
        fill_field(parent, "T\u00ean ng\u01b0\u1eddi nh\u1eadn", "Phụ huynh kiểm thử")
        fill_field(parent, "S\u1ed1 \u0111i\u1ec7n tho\u1ea1i", "0901234567")
        fill_field(
            parent,
            "\u0110\u1ecba ch\u1ec9 nh\u1eadn h\u1ecdc c\u1ee5 (b\u1eaft bu\u1ed9c khi c\u00f3 b\u1ed9 kit)",
            "123 Nguyễn Văn Linh, TP Hồ Chí Minh",
        )
        parent.get_by_role("button", name="Đặt hàng", exact=False).click()
        parent.wait_for_url(re.compile(r"/#/parent/orders/"))
        expect(parent.get_by_text("Chờ xác nhận", exact=True).first).to_be_visible()
        log("PASS persisted cart and server checkout")
        Path("backend/tests/artifacts").mkdir(exist_ok=True)
        parent.screenshot(path="backend/tests/artifacts/order.png")
        go(parent, "/parent")
        parent.screenshot(path="backend/tests/artifacts/parent.png")
        teacher.screenshot(path="backend/tests/artifacts/review.png")
        browser.close()
        log("All frontend smoke flows passed.")


if __name__ == "__main__":
    main()
