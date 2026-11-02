"""Real HTTP regressions: listing moderation must not approve marketplace orders.
Run with unittest discover and -k test_order_workflow (uses the existing isolated API harness).
"""
import sqlite3
from contextlib import closing
import time
import uuid
from marketplace_test import MarketplaceTests


class OrderWorkflowTests(MarketplaceTests):
    def approved(self, teacher=None):
        product, _, _ = self.listing(teacher)
        return self.review(product)

    def place(self, products, payment="cod", voucher=None):
        return self.request("POST", "/commerce/checkout", {
            "idempotencyKey": uuid.uuid4().hex,
            "paymentMethod": payment,
            "items": [{"itemType": "kit", "itemId": p["id"], "quantity": 1} for p in products],
            "voucherCode": voucher,
            "shipping": {"recipientName": "Buyer", "phoneNumber": "0901234567", "fullAddress": "123 Test"},
        }, self.parent)

    def fulfill(self, oid, status, token=None, expected=200):
        return self.request("PUT", f"/marketplace/orders/{oid}/fulfillment", {
            "carrier": "VNPost", "status": status,
        }, token or self.teacher, expected)

    def detail(self, oid):
        return self.request("GET", f"/commerce/orders/{oid}", token=self.parent)

    def test_order_workflow_cod_immediate_fulfillment_does_not_verify_collection(self):
        p = self.approved()
        order = self.place([p])
        oid = order["order"]["id"]
        self.assertEqual(order["order"]["status"], "preparing")
        self.assertFalse(order["order"]["requiresLegacyConfirmation"])
        self.assertTrue(order["order"]["canCancel"])
        seller = self.request("GET", f"/marketplace/orders/{oid}", token=self.teacher)
        self.assertTrue(seller["canFulfill"])
        self.assertEqual(seller["sellerStatus"], "preparing")
        self.assertTrue(any(o["id"] == oid for o in self.request("GET", "/marketplace/orders", token=self.teacher)["items"]))
        self.fulfill(oid, "shipping", self.other_teacher, 404)
        self.fulfill(oid, "shipping", self.parent, 403)
        self.fulfill(oid, "shipping", self.admin, 403)
        self.fulfill(oid, "preparing")
        self.fulfill(oid, "shipping")
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Too late"}, self.parent, 409)
        self.fulfill(oid, "delivered")
        self.fulfill(oid, "delivered")
        final = self.detail(oid)
        self.assertEqual((final["order"]["status"], final["order"]["paymentStatus"]), ("delivered", "cod"))
        self.assertIsNone(final["order"]["paidAt"])
        self.assertEqual(self.request("GET", f'/shop/products/{p["id"]}')["product"]["soldCount"], 1)
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin)
        self.assertEqual(self.detail(oid)["order"]["paymentStatus"], "cod")

    def test_order_workflow_transfer_pending_without_verification_policy(self):
        p = self.approved()
        for products in [[p], [p, {"id": "prod_kit_clay"}]]:
            order = self.place(products, "manual_transfer")
            oid = order["order"]["id"]
            seller = self.request("GET", f"/marketplace/orders/{oid}", token=self.teacher)
            self.assertEqual(seller["sellerStatus"], "pending_payment")
            self.assertFalse(seller["canFulfill"])
            self.assertTrue(seller["awaitingPayment"])
            self.assertFalse(order["order"]["requiresLegacyConfirmation"])
            for status in ["preparing", "shipping", "delivered"]:
                self.fulfill(oid, status, expected=409)
            self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin, expected=409)
            self.assertEqual(self.detail(oid)["order"]["paymentStatus"], "pending")
            self.assertIsNone(self.detail(oid)["order"]["paidAt"])
            self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "No transfer policy"}, self.parent)
            self.fulfill(oid, "shipping", expected=409)

    def test_order_workflow_cancel_cod_before_dispatch_restores_voucher_once(self):
        p = self.approved()
        order = self.place([p, self.approved()], voucher="ARTKIDS10")
        oid = order["order"]["id"]
        usage = next(v["usageLimit"] for v in self.request("GET", "/vouchers/available", token=self.parent) if v["code"] == "ARTKIDS10")
        self.fulfill(oid, "preparing")
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Wrong buyer"}, self.other, 404)
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Before dispatch"}, self.parent)
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Retry"}, self.parent)
        self.assertEqual(self.detail(oid)["order"]["status"], "cancelled")
        self.fulfill(oid, "shipping", expected=409)
        after = next(v["usageLimit"] for v in self.request("GET", "/vouchers/available", token=self.parent) if v["code"] == "ARTKIDS10")
        self.assertEqual(after, usage + 1)

    def test_order_workflow_mixed_cod_preserves_platform_confirmation_and_seller_isolation(self):
        first = self.approved()
        second = self.approved(self.other_teacher)
        order = self.place([first, second, {"id": "prod_kit_clay"}])
        oid = order["order"]["id"]
        self.assertTrue(order["order"]["requiresLegacyConfirmation"])
        for token, p in [(self.teacher, first), (self.other_teacher, second)]:
            seller = self.request("GET", f"/marketplace/orders/{oid}", token=token)
            self.assertEqual([i["productId"] for i in seller["items"]], [p["id"]])
            self.assertTrue(seller["canFulfill"])
            self.fulfill(oid, "shipping", token)
            self.fulfill(oid, "delivered", token)
        pending = self.detail(oid)
        self.assertEqual(pending["order"]["status"], "pending_confirmation")
        self.assertFalse(pending["order"]["canCancel"])
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Seller already dispatched"}, self.parent, 409)
        # Expired platform holds must not cancel an already-dispatched seller portion.
        with closing(sqlite3.connect(self.data / "test.db")) as db, db:
            db.execute("UPDATE inventory_reservations SET expires_at='2000-01-01 00:00:00' WHERE order_item_id IN (SELECT id FROM order_items WHERE order_id=?)", (oid,))
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin)
        shipment = self.request("POST", "/fulfillment/shipments", {
            "orderId": oid, "inventorySkuId": "stock_prod_kit_clay", "carrier": "VNPost", "trackingNumber": uuid.uuid4().hex,
        }, self.admin)
        for status in ["shipping", "delivered"]:
            self.request("POST", f'/fulfillment/shipments/{shipment["id"]}/status', {"status": status}, self.admin)
        final = self.detail(oid)["order"]
        self.assertEqual((final["status"], final["paymentStatus"]), ("delivered", "cod"))
        self.assertIsNone(final["paidAt"])

    def test_order_workflow_expiry_does_not_cancel_dispatched_seller_items(self):
        p = self.approved()
        platform = {"id": "prod_kit_clay"}
        waiting = self.place([p, platform])["order"]["id"]
        dispatched = self.place([p, platform])["order"]["id"]
        self.fulfill(dispatched, "shipping")
        with closing(sqlite3.connect(self.data / "test.db")) as db, db:
            db.execute("UPDATE inventory_reservations SET expires_at='2000-01-01 00:00:00' WHERE order_item_id IN (SELECT id FROM order_items WHERE order_id IN (?,?))", (waiting, dispatched))
        # The existing background job runs reservation recovery every 60 seconds.
        deadline = time.monotonic() + 75
        while self.detail(waiting)["order"]["status"] != "cancelled" and time.monotonic() < deadline:
            time.sleep(1)
        self.assertEqual(self.detail(waiting)["order"]["status"], "cancelled")
        self.assertEqual(self.detail(dispatched)["order"]["status"], "pending_confirmation")
        self.fulfill(waiting, "shipping", expected=409)
        self.request("POST", f"/commerce/orders/{dispatched}/confirm", token=self.admin)
        self.assertEqual(self.detail(dispatched)["order"]["paymentStatus"], "cod")

    def test_order_workflow_verified_transfer_state_is_required_and_not_seller_writable(self):
        p = self.approved()
        oid = self.place([p], "manual_transfer")["order"]["id"]
        self.request("PUT", f"/marketplace/orders/{oid}/fulfillment", {
            "carrier": "VNPost", "status": "shipping", "paymentStatus": "paid",
        }, self.teacher, 409)
        self.assertEqual(self.detail(oid)["order"]["paymentStatus"], "pending")
        # Trusted persisted state simulates a future verified-funds adapter, not a new payment endpoint.
        verified_at = "2026-10-29 01:00:00"
        with closing(sqlite3.connect(self.data / "test.db")) as db, db:
            db.execute("UPDATE orders SET payment_status='paid',paid_at=? WHERE id=?", (verified_at, oid))
        seller = self.request("GET", f"/marketplace/orders/{oid}", token=self.teacher)
        self.assertTrue(seller["canFulfill"])
        self.assertFalse(seller["awaitingPayment"])
        self.assertFalse(seller["collectionUnverified"])
        self.fulfill(oid, "shipping")
        self.fulfill(oid, "delivered")
        self.assertEqual(self.detail(oid)["order"]["paymentStatus"], "paid")
