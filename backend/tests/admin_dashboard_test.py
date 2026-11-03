"""Admin dashboard totals and course authoring permissions on an isolated database."""
import sqlite3
import unittest
import uuid
from datetime import datetime, timedelta, timezone

from integration_test import ApiTests


class AdminDashboardTests(ApiTests):
    def test_admin_dashboard_totals_and_permissions(self):
        for token in [self.teacher, self.parent]:
            self.request('GET', '/admin/dashboard', token=token, expected=403)
        self.request('GET', '/admin/dashboard', expected=401)
        before = self.request('GET', '/admin/dashboard', token=self.admin)
        now = datetime.now(timezone(timedelta(hours=7)))
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        current = (start + timedelta(minutes=30)).astimezone(timezone.utc)
        previous = (start - timedelta(minutes=1)).astimezone(timezone.utc)
        if self.postgres:
            import psycopg
            config = self.postgres
            connection = psycopg.connect(host=config['host'], port=config['port'],
                dbname=self.pg_database, user=config['username'], password=config['password'])
            mark = '%s'
        else:
            connection = sqlite3.connect(self.data / 'test.db')
            mark = '?'
        ids = []
        with connection.transaction() if self.postgres else connection:
            parent = connection.execute("SELECT id FROM users WHERE role='parent' LIMIT 1").fetchone()[0]
            for amount, status, payment, paid_at in [
                (100000, 'preparing', 'paid', current),
                (50000, 'delivered', 'paid', previous),
                (900000, 'pending_confirmation', 'pending', None),
                (800000, 'cancelled', 'paid', current),
            ]:
                key = uuid.uuid4().hex
                ids.append(key)
                values = [key, datetime.now(timezone.utc).isoformat(), key, parent, status,
                    'one_time_purchase', payment, 'vnpay', amount, 0, 0, amount, key,
                    (paid_at if self.postgres else paid_at.strftime('%Y-%m-%d %H:%M:%S'))
                    if paid_at else None]
                connection.execute('INSERT INTO orders (id,created_at,order_code,parent_id,status,'
                    'order_type,payment_status,payment_method_name,subtotal_vnd,shipping_fee_vnd,'
                    'discount_vnd,total_amount_vnd,idempotency_key,paid_at) VALUES ('
                    + ','.join([mark]*len(values)) + ')', values)
        try:
            after = self.request('GET', '/admin/dashboard', token=self.admin)
            self.assertEqual(after['totalRevenueVnd'] - before['totalRevenueVnd'], 150000)
            self.assertEqual(after['monthRevenueVnd'] - before['monthRevenueVnd'], 100000)
            self.assertEqual(after['paidOrderCount'] - before['paidOrderCount'], 2)
            self.assertEqual(after['pendingOrderCount'] - before['pendingOrderCount'], 1)
            self.assertEqual(after['revenueMonth'], now.strftime('%m/%Y'))
        finally:
            with connection.transaction() if self.postgres else connection:
                for key in ids:
                    connection.execute('DELETE FROM orders WHERE id='+mark, (key,))
            connection.close()

    def test_only_instructor_creates_courses(self):
        before = self.request('GET', '/admin/dashboard', token=self.admin)
        course = dict(title='Dashboard course', description='Permission test',
            ageRange='5-10', priceVnd=0, isPublished=True)
        self.request('POST', '/courses', course, self.admin, expected=403)
        self.request('POST', '/courses', course, self.parent, expected=403)
        created = self.request('POST', '/courses', course, self.teacher)
        after = self.request('GET', '/admin/dashboard', token=self.admin)
        self.assertEqual(after['courseCount'], before['courseCount']+1)
        self.assertEqual(after['publishedCourseCount'], before['publishedCourseCount']+1)
        self.request('DELETE', '/courses/'+created['id'], token=self.teacher, expected=204)
        final = self.request('GET', '/admin/dashboard', token=self.admin)
        self.assertEqual(final['courseCount'], before['courseCount'])


if __name__ == '__main__':
    suite = unittest.TestSuite(AdminDashboardTests(name) for name in [
        'test_admin_dashboard_totals_and_permissions', 'test_only_instructor_creates_courses'])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(not result.wasSuccessful())
