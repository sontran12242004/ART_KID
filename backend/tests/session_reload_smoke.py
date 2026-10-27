"""Verify browser reload, selected child, token renewal and logout."""

import re

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import go, log, open_page


def enable_accessibility(page):
    page.wait_for_selector("flt-semantics-placeholder", state="attached", timeout=45000)
    page.locator("flt-semantics-placeholder").evaluate("(e)=>e.click()")


def main():
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "parent")
        # Choose the second child through the actual dropdown, rather than
        # assuming the first child's persisted state is sufficient.
        page.get_by_role("button", name=re.compile("Hồ sơ bé đang sử dụng")).click()
        page.get_by_role("menuitem", name=re.compile("Mi Test")).click()
        go(page, "/kid/lesson/lesson_basics_1")
        expect(page.get_by_role("group", name=re.compile("Mi Test"))).to_be_visible()
        page.reload()
        enable_accessibility(page)
        expect(page.get_by_role("group", name=re.compile("Mi Test"))).to_be_visible()
        assert "/kid/lesson/lesson_basics_1" in page.url
        log("PASS reload retains authentication, current lesson and selected child")
        # Force access-token renewal without exposing any saved credentials.
        page.evaluate("""() => {
            const key='artkids.session.v1';
            const saved=JSON.parse(sessionStorage.getItem(key));
            saved.accessToken='expired-test-token';
            sessionStorage.setItem(key, JSON.stringify(saved));
        }""")
        with page.expect_response(lambda r: r.url.endswith('/auth/refresh')) as refreshed:
            page.reload()
        assert refreshed.value.status == 200
        enable_accessibility(page)
        expect(page.get_by_role("group", name=re.compile("Mi Test"))).to_be_visible()
        log("PASS expired access token renews and restores the selected child")
        go(page, "/parent")
        with page.expect_response(lambda r: r.url.endswith('/auth/logout')):
            page.get_by_role("button", name="Đăng xuất", exact=True).click()
        expect(page.get_by_role("button", name="Đăng Nhập", exact=True)).to_be_visible()
        assert page.evaluate("sessionStorage.getItem('artkids.session.v1')") is None
        page.reload()
        enable_accessibility(page)
        expect(page.get_by_role("button", name="Đăng Nhập", exact=True)).to_be_visible()
        teacher = open_page(browser, "instructor")
        teacher.reload()
        enable_accessibility(teacher)
        expect(teacher.get_by_role("button", name="Tạo khóa học", exact=True)).to_be_visible()
        teacher.evaluate("""() => {
            const key='artkids.session.v1';
            const saved=JSON.parse(sessionStorage.getItem(key));
            saved.accessToken='invalid'; saved.refreshToken='revoked';
            sessionStorage.setItem(key, JSON.stringify(saved));
        }""")
        teacher.reload()
        enable_accessibility(teacher)
        expect(teacher.get_by_role("button", name="Đăng Nhập", exact=True)).to_be_visible()
        assert teacher.evaluate("sessionStorage.getItem('artkids.session.v1')") is None
        log("PASS logout clears saved credentials and instructor also survives reload")
        browser.close()


if __name__ == "__main__":
    main()
