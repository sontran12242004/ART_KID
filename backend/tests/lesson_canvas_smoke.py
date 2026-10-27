"""Draw on a real Flutter canvas, submit its PNG and review it as the instructor."""

from io import BytesIO
from pathlib import Path

from PIL import Image
from playwright.sync_api import expect, sync_playwright

from frontend_smoke import fill_field, go, log, open_page


def main():
    artifacts = Path(__file__).parent / "artifacts"
    artifacts.mkdir(exist_ok=True)
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "parent")
        go(page, "/kid/lesson/lesson_basics_1")
        page.wait_for_function(
            "() => {const v=document.querySelector('video');return v && v.readyState>=2 && v.duration>60;}",
            timeout=45000,
        )
        page.mouse.move(1100, 800)
        page.mouse.wheel(0, 900)
        page.wait_for_timeout(700)
        paper = page.get_by_role("button", name="Giấy vẽ", exact=True)
        paper.scroll_into_view_if_needed()
        expect(page.get_by_role("button", name="Nộp bài vẽ", exact=True)).to_be_disabled()
        bounds = paper.bounding_box()
        x, y = bounds["x"] + 60, bounds["y"] + 60
        page.mouse.move(x, y)
        page.mouse.down()
        page.mouse.move(x + 140, y + 100, steps=18)
        page.mouse.up()
        page.wait_for_timeout(400)
        expect(page.get_by_role("button", name="Nộp bài vẽ", exact=True)).to_be_enabled()
        page.get_by_role("button", name="Hoàn tác", exact=True).click()
        expect(page.get_by_role("button", name="Nộp bài vẽ", exact=True)).to_be_disabled()
        paper.scroll_into_view_if_needed()
        bounds = paper.bounding_box()
        x, y = bounds["x"] + 60, bounds["y"] + 60
        page.mouse.move(x, y)
        page.mouse.down()
        page.mouse.move(x + 170, y + 80, steps=20)
        page.mouse.move(x + 50, y + 150, steps=15)
        page.mouse.up()
        page.wait_for_timeout(400)
        page.mouse.move(1150, 800)
        page.mouse.wheel(0, 400)
        page.wait_for_timeout(400)
        bounds = paper.bounding_box()
        page.mouse.click(
            bounds["x"] + bounds["width"] * 3.5 / 6, bounds["y"] + bounds["height"] + 38
        )
        paper.scroll_into_view_if_needed()
        bounds = paper.bounding_box()
        x, y = bounds["x"] + 280, bounds["y"] + 70
        page.mouse.move(x, y)
        page.mouse.down()
        page.mouse.move(x + 140, y + 120, steps=20)
        page.mouse.up()
        page.wait_for_timeout(400)
        page.get_by_role("button", name="Vẽ lại", exact=True).click()
        page.get_by_role("button", name="Hủy", exact=True).click()
        expect(page.get_by_role("button", name="Nộp bài vẽ", exact=True)).to_be_enabled()
        # Scrolling the lesson panel and changing the responsive breakpoint must
        # preserve both the drawing and its enabled undo/submit actions.
        page.mouse.move(150, 300)
        page.mouse.wheel(0, 1000)
        page.mouse.wheel(0, -1000)
        page.wait_for_timeout(400)
        before = paper.screenshot()
        assert sum(n for n, c in Image.open(BytesIO(before)).convert("RGB").getcolors(2000000) if c == (231, 111, 81)) > 100
        page.set_viewport_size({"width": 390, "height": 844})
        page.wait_for_timeout(800)
        expect(page.get_by_role("button", name="N\u1ed9p b\u00e0i v\u1ebd", exact=True)).to_be_enabled()
        mobile = Image.open(BytesIO(paper.screenshot())).convert("RGB")
        assert sum(n for n, c in mobile.getcolors(2000000) if c == (231, 111, 81)) > 30
        page.screenshot(path=str(artifacts / "lesson-workspace-mobile.png"))
        page.set_viewport_size({"width": 1280, "height": 1100})
        page.wait_for_timeout(800)
        assert paper.screenshot() == before
        log("PASS scrolling and desktop/mobile resize preserve the complete drawing")
        page.screenshot(path=str(artifacts / "lesson-canvas-drawing.png"))
        page.get_by_role("button", name="Nộp bài vẽ", exact=True).click()
        page.get_by_role("button", name="Vẽ tiếp", exact=True).click()
        expect(page.get_by_role("button", name="Nộp bài vẽ", exact=True)).to_be_enabled()
        page.get_by_role("button", name="Nộp bài vẽ", exact=True).click()
        with page.expect_response(
            lambda response: response.request.method == "POST"
            and response.url.endswith("/media/upload")
        ) as upload:
            with page.expect_response(
                lambda response: response.request.method == "POST"
                and response.url.endswith("/kid/submissions")
            ) as submitted:
                page.get_by_role("button", name="Xác nhận nộp bài", exact=True).click()
        assert upload.value.status == 200, upload.value.text()
        assert submitted.value.status == 200, submitted.value.text()
        asset = upload.value.json()
        submission = submitted.value.json()
        assert submission["lessonId"] == "lesson_basics_1"
        assert submission["childId"] == "child-1"
        assert submission["imageAssetId"] == asset["id"]
        assert submission["status"] == "pending_review"
        auth = submitted.value.request.headers["authorization"]
        response = page.request.get(
            "http://localhost:5080/api/v1/media/" + asset["id"], headers={"Authorization": auth}
        )
        assert response.status == 200
        image = Image.open(BytesIO(response.body())).convert("RGBA")
        assert image.width > 300 and image.height > 200
        assert image.getpixel((0, 0)) == (255, 255, 255, 255)
        colors = image.getcolors(image.width * image.height)
        assert sum(count for count, color in colors if color[:3] != (255, 255, 255)) > 500
        expect(page.get_by_role("button", name="Đã nộp bài", exact=True)).to_be_disabled()
        log("PASS canvas, undo, PNG export, correct child/lesson and pending-review submission")
        page.get_by_role("button", name="Xem bài đã nộp", exact=True).click()
        teacher = open_page(browser, "instructor")
        go(teacher, "/submissions/" + submission["id"])
        teacher.get_by_role("button", name="Chấm điểm & nhận xét", exact=True).click()
        fill_field(teacher, "Điểm (0–10)", "9")
        fill_field(teacher, "Nhận xét", "Canvas submission checked: great drawing!")
        teacher.get_by_role("button", name="Tiếp tục", exact=True).click()
        expect(teacher.get_by_text("9/10", exact=False).last).to_be_visible()
        go(page, "/parent")
        go(page, "/submissions/" + submission["id"])
        expect(page.get_by_text("9/10", exact=False).last).to_be_visible()
        log("PASS instructor reviews canvas artwork and parent sees the grade")
        browser.close()


if __name__ == "__main__":
    main()
