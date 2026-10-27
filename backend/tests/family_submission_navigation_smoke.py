"""Browse the selected child's course, lesson, drawing and teacher feedback."""

import re

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import go, log, open_page


def main():
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "parent")
        with page.expect_response(lambda r: '/family/submission-browser?' in r.url) as courses:
            page.get_by_role('button', name='Bài vẽ & nhận xét', exact=True).click()
        course = next(c for c in courses.value.json()['items'] if c['totalCount'] > 0)
        with page.expect_response(lambda r: 'courseId=' in r.url and '/family/submission-browser?' in r.url) as lessons:
            page.get_by_role('button', name=re.compile(re.escape(course['title']))).click()
        lesson = next(l for l in lessons.value.json()['items'] if l['totalCount'] > 0)
        with page.expect_response(lambda r: 'lessonId=' in r.url and '/family/submission-browser?' in r.url) as drawings:
            page.get_by_role('button', name=re.compile(re.escape(lesson['title']))).click()
        child_name = drawings.value.json()['childName']
        with page.expect_response(lambda r: '/family/submission-browser?' in r.url and 'status=reviewed' in r.url) as reviewed:
            page.get_by_role('checkbox', name='Đã nhận xét', exact=True).click()
        assert all(s['status'] == 'reviewed' for s in reviewed.value.json()['items'])
        with page.expect_response(lambda r: '/kid/submissions/' in r.url) as details:
            page.get_by_role('button', name=re.compile(re.escape(child_name) + ' ·')).first.click()
        assert details.value.json()['child']['nickname'] == child_name
        expect(page.get_by_role('button', name='Chấm điểm & nhận xét', exact=True)).to_have_count(0)
        assert details.value.json()['reviews']
        go(page, '/parent/submissions')
        page.get_by_role('button', name=re.compile('Hồ sơ bé đang sử dụng')).click()
        with page.expect_response(lambda r: '/family/submission-browser?' in r.url) as sibling:
            page.get_by_role('menuitem').nth(1).click()
        assert sibling.value.json()['childName'] != child_name
        page.wait_for_timeout(300)
        assert 'Bài vẽ của ' + sibling.value.json()['childName'] in page.locator('body').aria_snapshot()
        log('PASS parent course > lesson > reviewed drawing and switching selected child')
        browser.close()


if __name__ == '__main__':
    main()
