"""Real HTTP + migrated DB tests using invented signing keys, never real gateway credentials."""

import hashlib
import concurrent.futures
import hmac
import os
import unittest
import urllib.error
import urllib.parse
import urllib.request
import uuid

import integration_test as integration

SECRET = 'integration-only-vnpay-signing-secret-not-for-real-payments'


class PaymentHarness(unittest.TestCase):
    request = classmethod(integration.ApiTests.request.__func__)
    login = classmethod(integration.ApiTests.login.__func__)
    tearDownClass = classmethod(integration.ApiTests.tearDownClass.__func__)

    @classmethod
    def start(cls, enabled):
        settings = {'Vnpay__Enabled': str(enabled).lower(), 'Vnpay__TmnCode': 'TESTVNP1',
                    'Vnpay__HashSecret': SECRET,
                    'Vnpay__ReturnUrl': 'http://localhost:5080/api/v1/payments/vnpay/return',
                    'Vnpay__FrontendReturnUrl': 'http://localhost:8080/#/parent/payments/vnpay/result'}
        previous = {key: os.environ.get(key) for key in settings}
        os.environ.update(settings)
        try:
            integration.ApiTests.setUpClass.__func__(cls)
        finally:
            for key, value in previous.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

    def checkout(self, expected=200):
        return self.request('POST', '/commerce/checkout', {
            'idempotencyKey': uuid.uuid4().hex,
            'items': [{'itemType': 'kit', 'itemId': 'prod_kit_animal', 'quantity': 1}],
            'paymentMethod': 'vnpay',
            'shipping': {'recipientName': 'VNPay test', 'phoneNumber': '0900000000', 'fullAddress': 'Test address'}
        }, self.parent, expected)


class DisabledVnpayTests(PaymentHarness):
    @classmethod
    def setUpClass(cls): cls.start(False)

    def test_missing_keys_do_not_create_orders(self):
        config = self.request('GET', '/payments/vnpay/config', token=self.parent)
        self.assertFalse(config['isConfigured'])
        before = self.request('GET', '/commerce/orders', token=self.parent)
        self.checkout(expected=503)
        self.assertEqual(before, self.request('GET', '/commerce/orders', token=self.parent))
        self.assertNotIn('hashSecret', config)


class VnpayTests(PaymentHarness):
    @classmethod
    def setUpClass(cls): cls.start(True)

    def callback(self, payment_url, **updates):
        data = dict(urllib.parse.parse_qsl(urllib.parse.urlsplit(payment_url).query))
        data.pop('vnp_SecureHash')
        data.update(vnp_ResponseCode='00', vnp_TransactionStatus='00', vnp_TransactionNo='123456789', vnp_PayDate='20261102120000')
        data.update(updates)
        return data

    def signed_query(self, data):
        canonical = urllib.parse.urlencode(sorted((k, v) for k, v in data.items() if k.startswith('vnp_') and k not in ('vnp_SecureHash', 'vnp_SecureHashType') and v))
        signature = hmac.new(SECRET.encode(), canonical.encode(), hashlib.sha512).hexdigest()
        return urllib.parse.urlencode({**data, 'vnp_SecureHash': signature})

    def ipn(self, data):
        return self.request('GET', '/payments/vnpay/ipn?' + self.signed_query(data))

    def test_verified_ipn_and_return_are_separate(self):
        order = self.checkout()['order']
        oid = order['id']
        self.assertEqual(order['paymentStatus'], 'pending')
        endpoint = f'/payments/vnpay/orders/{oid}/url'
        self.request('POST', endpoint, token=self.other, expected=404)
        self.request('POST', endpoint, token=self.teacher, expected=403)
        payment = self.request('POST', endpoint, token=self.parent)
        repeated = self.request('POST', endpoint, token=self.parent)
        self.assertEqual(payment['id'], repeated['id'])
        self.assertEqual(payment['paymentUrl'], repeated['paymentUrl'])
        fields = dict(urllib.parse.parse_qsl(urllib.parse.urlsplit(payment['paymentUrl']).query))
        self.assertEqual(int(fields['vnp_Amount']), order['totalAmountVnd'] * 100)
        signature = fields.pop('vnp_SecureHash')
        self.assertEqual(signature, urllib.parse.parse_qs(self.signed_query(fields))['vnp_SecureHash'][0])
        callback = self.callback(payment['paymentUrl'])
        self.assertEqual(self.request('GET', '/payments/vnpay/ipn?' + self.signed_query(callback)[:-4] + '0000')['RspCode'], '97')
        self.assertEqual(self.ipn({**callback, 'vnp_Amount': '100'})['RspCode'], '04')
        self.assertEqual(self.ipn({**callback, 'vnp_TmnCode': 'OTHER'})['RspCode'], '97')
        self.assertEqual(self.ipn({**callback, 'vnp_TxnRef': 'missing-payment'})['RspCode'], '01')
        self.request('POST', f'/commerce/orders/{oid}/confirm', token=self.admin, expected=409)
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, *args, **kwargs): return None
        opener = urllib.request.build_opener(NoRedirect)
        with self.assertRaises(urllib.error.HTTPError) as response:
            opener.open(self.base + '/api/v1/payments/vnpay/return?' + self.signed_query(callback))
        self.assertEqual(response.exception.code, 302)
        self.assertIn('orderId=' + oid, response.exception.headers['Location'])
        self.assertEqual(self.request('GET', f'/payments/vnpay/orders/{oid}', token=self.parent)['paymentStatus'], 'pending')
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            codes = list(executor.map(lambda _: self.ipn(callback)['RspCode'], range(4)))
        self.assertEqual(codes.count('00'), 1)
        self.assertTrue(all(code in ('00', '02', '99') for code in codes))
        self.assertEqual(self.ipn(callback)['RspCode'], '02')
        state = self.request('GET', f'/payments/vnpay/orders/{oid}', token=self.parent)
        self.assertEqual(state['paymentStatus'], 'paid')
        self.assertFalse(state['canPay'])
        self.request('POST', endpoint, token=self.parent, expected=409)
        self.request('POST', f'/commerce/orders/{oid}/cancel', {'reason': 'Cannot cancel paid'}, self.parent, expected=409)
        # Paid stock must remain confirmable after the original reservation TTL.
        update = "UPDATE inventory_reservations SET expires_at = ? WHERE order_item_id IN (SELECT id FROM order_items WHERE order_id = ?)"
        if self.postgres:
            import psycopg
            c = self.postgres
            with psycopg.connect(host=c['host'], port=c['port'], dbname=self.pg_database, user=c['username'], password=c['password']) as db:
                from datetime import datetime, timezone
                db.execute(update.replace('?', '%s'), (datetime(2020, 1, 1, tzinfo=timezone.utc), oid))
        else:
            import sqlite3
            with sqlite3.connect(self.data / 'test.db') as db:
                db.execute(update, ('2020-01-01 00:00:00', oid))
        self.request('POST', f'/commerce/orders/{oid}/confirm', token=self.admin)

    def test_failed_retry_and_late_callback_after_cancel(self):
        oid = self.checkout()['order']['id']
        endpoint = f'/payments/vnpay/orders/{oid}/url'
        first = self.request('POST', endpoint, token=self.parent)
        declined = self.callback(first['paymentUrl'], vnp_ResponseCode='24', vnp_TransactionStatus='02', vnp_TransactionNo='0')
        self.assertEqual(self.ipn(declined)['RspCode'], '00')
        self.assertEqual(self.request('GET', f'/payments/vnpay/orders/{oid}', token=self.parent)['paymentStatus'], 'pending')
        retry = self.request('POST', endpoint, token=self.parent)
        self.assertNotEqual(retry['id'], first['id'])
        duplicate_keys = self.signed_query(self.callback(retry['paymentUrl'])) + '&vnp_Amount=100'
        self.assertEqual(self.request('GET', '/payments/vnpay/ipn?' + duplicate_keys)['RspCode'], '97')
        self.request('POST', f'/commerce/orders/{oid}/cancel', {'reason': 'Cancelled before callback'}, self.parent)
        self.assertEqual(self.ipn(self.callback(retry['paymentUrl'], vnp_TransactionNo='777777777'))['RspCode'], '00')
        state = self.request('GET', f'/payments/vnpay/orders/{oid}', token=self.parent)
        self.assertEqual((state['status'], state['paymentStatus']), ('cancelled', 'paid'))
        self.assertFalse(state['canPay'])
        self.request('POST', f'/commerce/orders/{oid}/confirm', token=self.admin, expected=409)


if __name__ == '__main__':
    unittest.main(verbosity=2)
