"""Check the local placeholder-key UX and result screen without calling VNPay."""

import argparse
import json

from playwright.sync_api import expect, sync_playwright

from frontend_smoke import PASSWORD, fill_field, go, log


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--email', default='parent.test@example.com')
    args = parser.parse_args()
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel='msedge', headless=True)
        page = browser.new_page(viewport={'width': 1280, 'height': 1100})
        page.set_default_timeout(20000)
        page.goto('http://localhost:8080/#/parent/login')
        page.wait_for_selector('flt-semantics-placeholder', state='attached', timeout=45000)
        page.locator('flt-semantics-placeholder').evaluate('(e)=>e.click()')
        page.get_by_role('textbox', name='Email', exact=True).click()
        page.wait_for_timeout(200)
        page.keyboard.type(args.email, delay=15)
        page.keyboard.press('Tab')
        page.wait_for_timeout(200)
        page.keyboard.type(PASSWORD, delay=15)
        page.get_by_role('button', name='Đăng Nhập', exact=True).click()
        page.wait_for_url('**/#/parent')

        # Supply a browser-only cart and forbid any real order mutation.
        page.route('**/api/v1/payments/vnpay/config', lambda route: route.fulfill(
            status=200, content_type='application/json', body='{"isConfigured":false}'))
        product = page.request.get('http://localhost:5080/api/v1/shop/products/prod_kit_animal').json()['product']
        page.route('**/api/v1/commerce/cart', lambda route: route.fulfill(status=200,
            content_type='application/json', body=json.dumps({'items': [{'product': product, 'quantity': 1}]})))
        checkout_requests = []
        def forbid_checkout(route):
            checkout_requests.append(route.request.url)
            route.fulfill(status=503, content_type='application/json', body='{"title":"Test forbids real orders"}')
        page.route('**/api/v1/commerce/checkout', forbid_checkout)
        go(page, '/parent/shop/cart')
        page.wait_for_timeout(500)
        go(page, '/parent/shop/checkout')
        fill_field(page, 'Tên người nhận', 'VNPay test')
        fill_field(page, 'Số điện thoại', '0901234567')
        fill_field(page, 'Địa chỉ nhận học cụ (bắt buộc khi có bộ kit)', 'Test address, Ho Chi Minh City')
        page.get_by_role('button', name='Đặt hàng', exact=True).click()
        page.wait_for_timeout(1000)
        assert 'VNPay Sandbox chưa được cấu hình' in page.locator('body').aria_snapshot()
        assert not checkout_requests
        log('PASS placeholder keys block checkout before creating an order')

        # Mock only the payment status response: browser state/return parameters
        # must not be enough to render a paid status before the server says so.
        state = {'paid': False}
        def status(route):
            route.fulfill(status=200, content_type='application/json', body=json.dumps({
                'id': 'ui-payment', 'orderCode': 'AK-UI-TEST', 'paymentStatus': 'paid' if state['paid'] else 'pending',
                'totalAmountVnd': 180000, 'status': 'pending_confirmation', 'canPay': not state['paid'], 'isConfigured': False
            }))
        page.route('**/api/v1/payments/vnpay/orders/ui-payment', status)
        go(page, '/parent/payments/vnpay/result?orderId=ui-payment&result=pending')
        expect(page.get_by_role('button', name='Thanh toán qua VNPay', exact=True)).to_have_count(0)
        assert 'bạn không cần thanh toán lại' in page.locator('body').aria_snapshot()
        assert 'Thanh toán thành công!' not in page.locator('body').aria_snapshot()
        state['paid'] = True
        page.get_by_role('button', name='Kiểm tra trạng thái', exact=True).click()
        page.wait_for_timeout(500)
        assert 'Thanh toán thành công!' in page.locator('body').aria_snapshot()
        expect(page.get_by_role('button', name='Thanh toán qua VNPay', exact=True)).to_have_count(0)
        go(page, '/parent/payments/vnpay/result?result=invalid')
        page.wait_for_timeout(400)
        assert 'Không xác minh được kết quả thanh toán' in page.locator('body').aria_snapshot()
        log('PASS payment-result UI trusts server status and handles invalid callback')
        browser.close()


if __name__ == '__main__':
    main()
