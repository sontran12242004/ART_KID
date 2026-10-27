"""Exercise the completion gate for canvas and paper submissions locally."""

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import PNG, go, log, open_page


def main():
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "parent")
        complete = page.get_by_role("button", name="Đánh dấu hoàn thành", exact=True)
        go(page, "/kid/lesson/lesson_basics_2")
        expect(complete).to_be_disabled()
        paper = page.get_by_role("button", name="Giấy vẽ", exact=True)
        paper.click(position={"x": 60, "y": 60})
        expect(complete).to_be_disabled()
        page.get_by_role("button", name="Nộp bài vẽ", exact=True).click()
        page.get_by_role("button", name="Vẽ tiếp", exact=True).click()
        expect(complete).to_be_disabled()
        page.get_by_role("button", name="Nộp bài vẽ", exact=True).click()
        page.get_by_role("button", name="Xác nhận nộp bài", exact=True).click()
        expect(complete).to_be_enabled(timeout=15000)
        complete.click()
        expect(page.get_by_role("button", name="Bài tiếp theo", exact=True)).to_be_visible()
        with page.expect_response(lambda r: "/lessons/" in r.url and "childId=" in r.url) as details:
            page.get_by_role("button", name="Bài tiếp theo", exact=True).click()
        expect(complete).to_be_disabled()
        lesson_id = details.value.json()["id"]
        go(page, "/kid/lesson/" + lesson_id + "/submit")
        with page.expect_file_chooser() as chooser:
            page.get_by_role("button", name="Chọn ảnh bài vẽ", exact=True).click()
        chooser.value.set_files({"name": "paper.png", "mimeType": "image/png", "buffer": PNG})
        page.get_by_role("button", name="Gửi bài cho giáo viên", exact=True).click()
        with page.expect_response(lambda r: r.request.method == "POST" and r.url.endswith("/kid/submissions")):
            page.get_by_role("button", name="Xác nhận", exact=True).click()
        go(page, "/kid/lesson/" + lesson_id)
        expect(complete).to_be_enabled()
        log("PASS completion stays disabled until a canvas or paper assignment is submitted")
        browser.close()


if __name__ == "__main__":
    main()
