"""Browse teacher courses, lessons, submissions and grade one local assignment."""

import re

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import fill_field, go, log, open_page


def main():
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        page = open_page(browser, "instructor")
        with page.expect_response(lambda r: r.url.endswith('/grading/courses')) as courses:
            page.get_by_role("button", name="Chấm bài học sinh", exact=True).click()
        course = next(c for c in courses.value.json() if c['pendingCount'] > 0)
        with page.expect_response(lambda r: '/grading/courses/' in r.url and r.url.endswith('/lessons')) as lessons:
            page.get_by_role("button", name=re.compile(re.escape(course['title']))).click()
        lesson = next(l for l in lessons.value.json()['lessons'] if l['pendingCount'] > 0)
        with page.expect_response(lambda r: '/grading/lessons/' in r.url) as submissions:
            page.get_by_role("button", name=re.compile(re.escape(lesson['title']))).click()
        submission = submissions.value.json()['items'][0]
        expect(page.get_by_role('button', name=re.compile(re.escape(submission['childName']))).first).to_be_visible()
        with page.expect_response(lambda r: '/kid/submissions/' in r.url) as details:
            page.get_by_role('button', name=re.compile(re.escape(submission['childName']))).first.click()
        selected = details.value.json()['submission']
        assert details.value.json()['child']['id'] == selected['childId']
        assert submission['childName'] in page.locator('body').aria_snapshot()
        page.get_by_role('button', name='Chấm điểm & nhận xét', exact=True).click()
        fill_field(page, 'Điểm (0–10)', '8')
        fill_field(page, 'Nhận xét', 'Great work from the course grading screen!')
        page.get_by_role('button', name='Tiếp tục', exact=True).click()
        expect(page.get_by_text('8/10', exact=False).last).to_be_visible()
        go(page, '/staff/grading')
        refreshed = page.request.get('http://localhost:5080/api/v1/grading/courses',
            headers={'Authorization': courses.value.request.headers['authorization']})
        updated = next(c for c in refreshed.json() if c['id'] == course['id'])
        assert updated['pendingCount'] == course['pendingCount'] - 1
        expect(page.get_by_role('button', name=re.compile(re.escape(course['title']) + r'.*' + str(updated['pendingCount']) + ' bài cần chấm'))).to_be_visible()
        log('PASS course > lesson > child submission > review and pending-count update')
        browser.close()


if __name__ == '__main__':
    main()
