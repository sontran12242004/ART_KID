"""Verify real submission images, zoom and the legacy one-pixel notice."""

from pathlib import Path

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import go, log, open_page


def main():
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "instructor")
        go(page, "/submissions/3137bd2b59674b11945ec73cce068242")
        artwork = page.get_by_role("img", name="Ảnh bài vẽ đã nộp", exact=True)
        expect(artwork).to_be_visible(timeout=15000)
        bounds = artwork.bounding_box()
        assert bounds['width'] > 250 and bounds['height'] > 250
        page.get_by_role("button", name="Phóng to", exact=True).click()
        expect(page.get_by_role("img", name="Ảnh bài vẽ phóng to", exact=True)).to_be_visible()
        page.get_by_role("button", name="Đóng ảnh", exact=True).click()
        artifacts = Path(__file__).parent / 'artifacts'
        artifacts.mkdir(exist_ok=True)
        page.screenshot(path=str(artifacts / 'submission-artwork-preview.png'))
        go(page, "/submissions/1362571c70f4413fbf563c938a82c570")
        expect(page.get_by_role("button", name="Chấm điểm & nhận xét", exact=True)).to_be_visible()
        page.wait_for_timeout(1000)
        snapshot = page.locator('body').aria_snapshot()
        assert '1 × 1 pixel' in snapshot or 'File ảnh của bài nộp không đọc được' in snapshot
        expect(page.get_by_role("button", name="Phóng to", exact=True)).to_have_count(0)
        log('PASS real drawing visible, zoom opens, legacy 1px submission displays a clear notice')
        browser.close()


if __name__ == '__main__':
    main()
