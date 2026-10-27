"""Check instructor course lecture lists, playback, switching and mobile layout."""

import re
from pathlib import Path

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import log, open_page


def open_course(page, index):
    edit = page.get_by_role("button", name="Chỉnh sửa khóa học", exact=True).nth(index)
    edit.wait_for(state="visible")
    bounds = edit.bounding_box()
    page.mouse.click(100, bounds["y"] + bounds["height"] / 2)
    page.get_by_role("button", name="Xem video bài giảng", exact=True).click()
    expect(page.get_by_text(re.compile(r"^Bài [1-5]:"))).to_have_count(5)


def play(page, duration):
    page.wait_for_function(
        "expected => {const v=document.querySelector('video'); return v && v.readyState>=2 && Math.abs(v.duration-expected)<.2;}",
        arg=duration,
        timeout=45000,
    )
    page.get_by_role("button", name="Phát / Tạm dừng", exact=True).last.click()
    page.wait_for_function("() => document.querySelector('video').currentTime>1")


def main():
    artifacts = Path(__file__).parent / "artifacts"
    artifacts.mkdir(exist_ok=True)
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "instructor")
        open_course(page, 0)
        play(page, 119.08)
        page.get_by_text("Bài 2: Phối màu", exact=True).click()
        play(page, 126.08)
        page.screenshot(path=str(artifacts / "instructor-lectures-desktop.png"))
        page.get_by_role("button", name="Đóng video bài giảng", exact=True).click()
        expect(page.locator("video")).to_have_count(0)
        log("PASS basic course: five lessons, playback, switching and player disposal")

        edit = page.get_by_role("button", name="Chỉnh sửa khóa học", exact=True).first
        bounds = edit.bounding_box()
        page.mouse.click(100, bounds["y"] + bounds["height"] / 2)
        open_course(page, 1)
        page.get_by_text("Bài 5: Vẽ chim trên cành", exact=True).click()
        play(page, 130.17)
        page.set_viewport_size({"width": 390, "height": 844})
        page.wait_for_timeout(800)
        expect(page.get_by_role("button", name="Đóng video bài giảng", exact=True)).to_be_visible()
        expect(page.locator("video")).to_be_visible()
        page.screenshot(path=str(artifacts / "instructor-lectures-mobile.png"))
        page.get_by_role("button", name="Đóng video bài giảng", exact=True).click()
        expect(page.locator("video")).to_have_count(0)
        log("PASS animal course: five lessons, final lesson playback and mobile layout")
        browser.close()


if __name__ == "__main__":
    main()
