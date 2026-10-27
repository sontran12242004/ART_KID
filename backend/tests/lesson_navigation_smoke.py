"""Check saved completion and next-lesson navigation on the local Flutter app."""

import re

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import go, log, open_page


def main():
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "parent")
        go(page, "/kid/lesson/lesson_basics_1")
        next_button = page.get_by_role("button", name="Bài tiếp theo", exact=True)
        complete = page.get_by_role("button", name="Đánh dấu hoàn thành", exact=True)
        page.wait_for_timeout(1200)
        if complete.count():
            complete.click()
        expect(next_button).to_be_visible()
        with page.expect_response(lambda r: "/lessons/lesson_basics_2?" in r.url) as lesson:
            next_button.click()
        assert lesson.value.status == 200
        assert lesson.value.json()["id"] == "lesson_basics_2"
        go(page, "/kid/lesson/lesson_basics_1")
        expect(next_button).to_be_visible()
        expect(complete).to_have_count(0)
        lessons = page.request.get("http://localhost:5080/api/v1/courses/course_basics/lessons").json()
        last_id = max(lessons, key=lambda row: row["orderIndex"])["id"]
        go(page, "/kid/lesson/" + last_id)
        page.wait_for_timeout(1000)
        if complete.count():
            complete.click()
        back = page.get_by_role("button", name="Về danh sách bài học", exact=True)
        expect(back).to_be_visible()
        expect(next_button).to_have_count(0)
        back.click()
        expect(page.get_by_text("Bài học", exact=True)).to_be_visible()
        expect(page.get_by_role("button", name=re.compile("Đã hoàn thành")).first).to_be_visible()
        log("PASS saved completion, next lesson and last-lesson return to course")
        browser.close()


if __name__ == "__main__":
    main()
