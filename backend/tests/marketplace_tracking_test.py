"""Parent tracking regressions against a real migrated API; no carrier integration."""
from contextlib import closing
import concurrent.futures
import sqlite3
from marketplace_order_workflow_test import OrderWorkflowTests


class MarketplaceTrackingTests(OrderWorkflowTests):
    def assert_timeline(self, detail):
        events = detail["trackingEvents"]
        self.assertEqual(len(events), len({e["id"] for e in events}))
        self.assertEqual(sum(e["isCurrent"] for e in events), 1)
        self.assertTrue(events[-1]["isCurrent"])
        self.assertTrue(all(e["isPassed"] for e in events[:-1]))
        self.assertEqual(detail["order"]["paymentStatus"], "cod")
        self.assertIsNone(detail["order"]["paidAt"])
        self.assertFalse(detail["shippingInfo"].get("trackingUrl"))

    def test_parent_tracking_records_seller_transitions_once(self):
        product = self.approved()
        order = self.place([product])
        oid = order["order"]["id"]
        progress = order["sellerProgress"]
        self.assertEqual(progress[0]["status"], "preparing")
        self.assertEqual(progress[0]["itemTitles"], [product["name"]])
        self.assertIsNone(progress[0]["carrier"])
        self.assertIsNone(progress[0]["deliveredAt"])
        self.assertIn("chuẩn bị", order["trackingEvents"][-1]["title"].lower())
        initial_ids = [e["id"] for e in order["trackingEvents"]]
        retry = self.request("POST", "/commerce/checkout", {
            "idempotencyKey": order["order"]["idempotencyKey"],
            "paymentMethod": "cod", "items": [{"itemType": "kit", "itemId": product["id"], "quantity": 1}],
            "shipping": {"recipientName": "Buyer", "phoneNumber": "0901234567", "fullAddress": "123 Test"},
        }, self.parent)
        self.assertEqual(initial_ids, [e["id"] for e in retry["trackingEvents"]])
        self.fulfill(oid, "preparing")
        self.fulfill(oid, "preparing")
        self.assertEqual(initial_ids, [e["id"] for e in self.detail(oid)["trackingEvents"]])
        self.fulfill(oid, "shipping")
        shipping = self.detail(oid)
        self.assertEqual(len(shipping["trackingEvents"]), len(initial_ids) + 1)
        self.assertIn("báo đã gửi", shipping["trackingEvents"][-1]["title"])
        self.assertEqual(shipping["sellerProgress"][0]["status"], "shipping")
        self.assertIsNotNone(shipping["sellerProgress"][0]["shippedAt"])
        for _ in range(2):
            self.fulfill(oid, "shipping")
        self.assertEqual(len(shipping["trackingEvents"]), len(self.detail(oid)["trackingEvents"]))
        self.fulfill(oid, "delivered")
        self.fulfill(oid, "delivered")
        final = self.detail(oid)
        self.assertEqual(len(final["trackingEvents"]), len(initial_ids) + 2)
        self.assertIn("báo đã giao", final["trackingEvents"][-1]["title"])
        self.assertIn("chưa được hãng vận chuyển xác minh", final["trackingEvents"][-1]["description"])
        self.assertEqual(final["sellerProgress"][0]["status"], "delivered")
        self.assertIsNotNone(final["sellerProgress"][0]["deliveredAt"])
        self.assert_timeline(final)

    def test_parent_tracking_separates_sellers_and_preserves_privacy(self):
        first = self.approved()
        second = self.approved(self.other_teacher)
        oid = self.place([first, second])["order"]["id"]
        before = self.detail(oid)
        self.fulfill(oid, "shipping")
        self.fulfill(oid, "delivered")
        partial = self.detail(oid)
        self.assertEqual(partial["order"]["status"], "shipping")
        progress = {p["sellerId"]: p for p in partial["sellerProgress"]}
        self.assertEqual(progress[first["createdBy"]]["status"], "delivered")
        self.assertEqual(progress[second["createdBy"]]["status"], "preparing")
        self.assertEqual(progress[second["createdBy"]]["itemTitles"], [second["name"]])
        own = self.request("GET", f"/marketplace/orders/{oid}", token=self.teacher)
        self.assertNotIn("sellerProgress", own)
        self.assertNotIn(second["id"], str(own))
        self.request("GET", f"/commerce/orders/{oid}", token=self.other, expected=404)
        self.request("GET", f"/commerce/orders/{oid}", token=self.other_teacher, expected=404)
        for status in ["shipping", "delivered"]:
            self.fulfill(oid, status, self.other_teacher)
        final = self.detail(oid)
        self.assertEqual(final["order"]["status"], "delivered")
        self.assertEqual(len(final["trackingEvents"]), len(before["trackingEvents"]) + 4)
        self.assert_timeline(final)

    def test_parent_tracking_localizes_old_text_without_fabricating_history(self):
        product = self.approved()
        oid = self.place([product])["order"]["id"]
        with closing(sqlite3.connect(self.data / "test.db")) as db, db:
            db.execute("UPDATE order_tracking_events SET description='Seller COD fulfillment may begin; collection is unverified.',is_current=1 WHERE order_id=? AND title='Đã đặt hàng'", (oid,))
        detail = self.detail(oid)
        self.assertNotIn("Seller COD fulfillment", str(detail["trackingEvents"]))
        self.assert_timeline(detail)
        with closing(sqlite3.connect(self.data / "test.db")) as db:
            self.assertEqual(db.execute("SELECT description FROM order_tracking_events WHERE order_id=? AND title='Đã đặt hàng'", (oid,)).fetchone()[0], "Seller COD fulfillment may begin; collection is unverified.")

    def test_parent_tracking_metadata_and_concurrent_retries_do_not_duplicate(self):
        product = self.approved()
        oid = self.place([product])["order"]["id"]
        before = len(self.detail(oid)["trackingEvents"])
        self.request("PUT", f"/marketplace/orders/{oid}/fulfillment", {
            "status": "preparing", "carrier": "GHN", "trackingNumber": "TEACHER-PROVIDED",
        }, self.teacher)
        self.assertEqual(before, len(self.detail(oid)["trackingEvents"]))
        def ship():
            try:
                return self.request("PUT", f"/marketplace/orders/{oid}/fulfillment", {
                    "status": "shipping", "carrier": "GHN", "trackingNumber": "TEACHER-PROVIDED",
                }, self.teacher)
            except AssertionError as error:
                self.assertIn("got 409", str(error))
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            list(pool.map(lambda _: ship(), range(2)))
        detail = self.detail(oid)
        self.assertEqual(len(detail["trackingEvents"]), before + 1)
        self.assertEqual(detail["sellerProgress"][0]["trackingNumber"], "TEACHER-PROVIDED")
        self.assert_timeline(detail)
