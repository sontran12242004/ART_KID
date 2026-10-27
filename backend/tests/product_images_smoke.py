"""Check product image files and their rendering in the local shop/detail UI."""

import argparse
from io import BytesIO
from pathlib import Path

from PIL import Image
from playwright.sync_api import sync_playwright

from frontend_smoke import go, log


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--email', default='parent.test@example.com')
    args = parser.parse_args()
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel='msedge', headless=True)
        page = browser.new_page(viewport={'width': 1440, 'height': 1000})
        page.set_default_timeout(20000)
        products = page.request.get('http://localhost:5080/api/v1/shop/products?pageSize=100').json()['items']
        for row in products:
            product = row['product']
            assert product['thumbnailUrl']
            response = page.request.get('http://localhost:5080' + product['thumbnailUrl'])
            assert response.status == 200
            image = Image.open(BytesIO(response.body()))
            image.load()
            assert min(image.size) >= 200
        page.goto('http://localhost:8080/#/parent/login')
        page.wait_for_selector('flt-semantics-placeholder', state='attached', timeout=45000)
        page.locator('flt-semantics-placeholder').evaluate('(e)=>e.click()')
        page.get_by_role('textbox', name='Email', exact=True).click()
        page.wait_for_timeout(200)
        page.keyboard.type(args.email, delay=15)
        page.keyboard.press('Tab')
        page.wait_for_timeout(200)
        page.keyboard.type('ArtKids-Test-2026!', delay=15)
        page.get_by_role('button', name='Đăng Nhập', exact=True).click()
        page.wait_for_url('**/#/parent')
        responses = []
        page.on('response', lambda r: responses.append(r.status) if '/media/products/' in r.url else None)
        go(page, '/parent/shop')
        page.wait_for_timeout(2000)
        assert len(responses) >= 2 and all(status == 200 for status in responses)
        artifacts = Path(__file__).parent / 'artifacts'
        artifacts.mkdir(exist_ok=True)
        page.screenshot(path=str(artifacts / 'shop-product-images.png'))
        go(page, '/parent/shop/product/prod_tool_brushes')
        page.wait_for_timeout(1000)
        page.screenshot(path=str(artifacts / 'shop-product-image-detail.png'))
        log(f'PASS {len(products)} product images load; shop and detail screenshots saved')
        browser.close()


if __name__ == '__main__':
    main()
