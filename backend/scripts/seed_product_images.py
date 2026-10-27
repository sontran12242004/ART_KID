"""Upload generated sample product images and fill missing/1px shop thumbnails.

Uses the public upload/product APIs; leaves prices, inventory and valid images intact.
Set ARTKIDS_SEED_PASSWORD to the local administrator password before running.
"""

import argparse
import json
import os
from pathlib import Path
import struct
import urllib.request
import uuid


ROOT = Path(__file__).resolve().parents[1]
IMAGE_FILES = {
    'prod_tool_brushes': 'brushes.png',
    'prod_kit_animal': 'animal-kit.png',
    'prod_kit_acrylic': 'acrylic.png',
    'prod_tool_kuretake': 'watercolors.png',
    'prod_kit_fairytale': 'fairytale-kit.png',
    'prod_kit_clay': 'clay.png',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--api-base', default='http://localhost:5080/api/v1')
    parser.add_argument('--email', default='admin.test@example.com')
    args = parser.parse_args()
    password = os.environ.get('ARTKIDS_SEED_PASSWORD')
    if not password:
        raise SystemExit('Set ARTKIDS_SEED_PASSWORD to the local admin password.')
    base = args.api_base.rstrip('/')
    token = None

    def api(method, path, data=None, raw=None, content_type=None):
        headers = {'Content-Type': content_type or 'application/json'}
        if token:
            headers['Authorization'] = 'Bearer ' + token
        body = raw if raw is not None else json.dumps(data).encode() if data is not None else None
        request = urllib.request.Request(base + path, data=body, headers=headers, method=method)
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)

    token = api('POST', '/auth/login', {'email': args.email, 'password': password})['accessToken']
    report = []
    page = 1
    while True:
        catalogue = api('GET', f'/shop/products?page={page}&pageSize=100')
        for entry in catalogue['items']:
            product = entry['product']
            if not product['isActive']:
                continue
            product_id = product['id']
            filename = IMAGE_FILES.get(product_id)
            thumbnail = product.get('thumbnailUrl', '')
            tiny = False
            if thumbnail.startswith('/api/v1/media/products/'):
                with urllib.request.urlopen(base.removesuffix('/api/v1') + thumbnail, timeout=30) as response:
                    header = response.read(24)
                tiny = header.startswith(b'\x89PNG\r\n\x1a\n') and min(struct.unpack('!II', header[16:24])) <= 1
            if thumbnail and not tiny:
                print('SKIP existing image: ' + product_id)
                continue
            # A legacy course-product smoke test used a one-pixel watercolor PNG.
            if filename is None and tiny and product.get('courseId') == 'course_basics':
                filename = 'watercolors.png'
            if filename is None:
                continue
            image = ROOT / 'seed-data/product-images' / filename
            boundary = 'ArtKidImage' + uuid.uuid4().hex
            body = (f'--{boundary}\r\nContent-Disposition: form-data; name="kind"\r\n\r\nproduct_image\r\n'
                    f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\n'
                    'Content-Type: image/png\r\n\r\n').encode() + image.read_bytes() + f'\r\n--{boundary}--\r\n'.encode()
            uploaded = api('POST', '/media/upload', raw=body, content_type='multipart/form-data; boundary=' + boundary)
            fields = ('name', 'priceVnd', 'originalPriceVnd', 'description', 'category', 'courseId',
                      'recommendedSubscriptionPlanId', 'kitItems', 'isActive')
            updated = {field: product.get(field) for field in fields}
            updated.update(thumbnailUrl=uploaded['url'], images=[uploaded['url']])
            saved = api('PUT', '/shop/products/' + product_id, updated)
            assert saved['thumbnailUrl'] == uploaded['url']
            for field in fields:
                assert saved[field] == product.get(field), f'Unexpected change: {field}'
            report.append({'productId': product_id, 'filename': filename, 'url': uploaded['url']})
            print('UPDATED image: ' + product_id)
        if page * 100 >= catalogue['total']:
            break
        page += 1
    print(f'Completed: {len(report)} product images updated.')


if __name__ == '__main__':
    main()
