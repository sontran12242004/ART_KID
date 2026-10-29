"""Marketplace behavior against the real migrated API; uses the existing HTTP harness.
Run: python -m unittest discover -s backend/tests -p marketplace_test.py -k test_marketplace
"""

import uuid
from integration_test import ApiTests, PNG


class MarketplaceTests(ApiTests):
    def listing(self, teacher=None, course=None, path="/marketplace/listings"):
        teacher = teacher or self.teacher
        image = self.upload(kind="product_image", child=None, token=teacher)
        body = {
            "name": "Teacher kit " + uuid.uuid4().hex,
            "priceVnd": 125000,
            "description": "Teacher-arranged supplies and shipping.",
            "imageAssetId": image["id"],
            "courseId": course,
            "isAvailable": True,
        }
        request = {**body, "quantityAvailable": 1} if path.startswith("/courses/") else body
        return self.request("POST", path, request, teacher), body, image

    def review(self, product, status="approved", reason=None, expected=200):
        return self.request(
            "POST", f'/marketplace/reviews/{product["id"]}',
            {"status": status, "reason": reason, "expectedRevision": product["revision"]},
            self.admin, expected,
        )

    def checkout(self, products, expected=200, key=None):
        return self.request("POST", "/commerce/checkout", {
            "idempotencyKey": key or uuid.uuid4().hex,
            "items": [{"itemType": "kit", "itemId": p["id"], "quantity": 2} for p in products],
            "paymentMethod": "cod",
            "shipping": {"recipientName": "Parent", "phoneNumber": "0901234567", "fullAddress": "123 Test"},
        }, self.parent, expected)

    def test_marketplace_moderation_visibility_and_resubmission(self):
        product, body, image = self.listing(course="course_basics")
        pid = product["id"]
        self.assertEqual((product["approvalStatus"], product["fulfillmentMode"]), ("pending", "seller"))
        self.assertTrue(product["isAvailable"])
        self.request("GET", f"/shop/products/{pid}", expected=404)
        public = self.request("GET", "/shop/products?pageSize=100")
        self.assertNotIn(pid, [p["product"]["id"] for p in public["items"]])
        self.request("GET", image["url"].removeprefix("/api/v1"), expected=404)
        self.request("GET", image["url"].removeprefix("/api/v1"), token=self.other_teacher, expected=404)
        for token in [self.admin, self.teacher]:
            self.assertEqual(self.request("GET", f'/media/{image["id"]}', token=token), PNG)
        self.request("GET", f'/media/{image["id"]}', token=self.other_teacher, expected=404)
        self.request("PUT", "/commerce/cart/items", {"productId": pid, "quantity": 1}, self.parent, 400)
        self.checkout([product], expected=400)
        self.review(product, "rejected", "   ", expected=400)
        rejected = self.review(product, "rejected", "Please describe the brushes.")
        self.assertEqual(rejected["rejectionReason"], "Please describe the brushes.")
        resubmitted = self.request("PUT", f"/marketplace/listings/{pid}", {
            **body, "description": "Four brushes and paper.", "expectedRevision": rejected["revision"],
        }, self.teacher)
        self.assertEqual(resubmitted["approvalStatus"], "pending")
        self.assertIsNone(resubmitted["rejectionReason"])
        self.review(product, expected=409)
        approved = self.review(resubmitted)
        self.assertEqual(self.request("GET", f"/shop/products/{pid}")["product"]["name"], body["name"])
        self.assertEqual(self.request("GET", image["url"].removeprefix("/api/v1")), PNG)
        edited = self.request("PUT", f"/marketplace/listings/{pid}", {
            **body, "priceVnd": 150000, "expectedRevision": approved["revision"],
        }, self.teacher)
        self.assertEqual(edited["approvalStatus"], "pending")
        self.request("GET", f"/shop/products/{pid}", expected=404)
        self.request("GET", image["url"].removeprefix("/api/v1"), expected=404)

    def test_marketplace_roles_ownership_and_legacy_bypass(self):
        product, body, _ = self.listing()
        pid = product["id"]
        for token in [self.admin, self.parent]:
            self.request("POST", "/marketplace/listings", body, token, 403)
            self.request("POST", "/courses/course_basics/products", {**body, "quantityAvailable": 1}, token, 403)
        foreign_course = self.request("POST", "/courses", {
            "title": "Other instructor course", "description": "Private ownership", "ageRange": "5-10", "priceVnd": 0,
        }, self.other_teacher)
        self.request("POST", "/marketplace/listings", {**body, "courseId": foreign_course["id"]}, self.teacher, 404)
        for method in ["GET", "PUT", "DELETE"]:
            self.request(method, f"/marketplace/listings/{pid}", body if method == "PUT" else None, self.other_teacher, 404)
        self.request("POST", f"/marketplace/reviews/{pid}", {"status": "approved", "expectedRevision": 1}, self.teacher, 403)
        self.request("PUT", f"/shop/products/{pid}", {
            "name": "Bypass", "priceVnd": 1, "description": "Bypass", "category": "individual_tool",
        }, self.admin, 409)
        self.request("POST", "/inventory/stock", {
            "productId": pid, "sku": "FORBIDDEN-SELLER", "quantityAvailable": 1,
            "reorderThreshold": 0, "unitCostVnd": 0,
        }, self.admin, 409)
        legacy, _, _ = self.listing(course="course_basics", path="/courses/course_basics/products")
        self.assertEqual(legacy["approvalStatus"], "pending")
        entries = self.request("GET", "/courses/course_basics/products", token=self.teacher)
        self.assertIn(legacy["id"], [e["product"]["id"] for e in entries])
        self.request("GET", "/courses/course_basics/products", token=self.other_teacher, expected=404)

    def test_marketplace_availability_stale_cart_and_no_warehouse(self):
        product, body, _ = self.listing()
        product = self.review(product)
        pid = product["id"]
        self.request("PUT", "/commerce/cart/items", {"productId": pid, "quantity": 2}, self.parent)
        unavailable = self.request("PUT", f"/marketplace/listings/{pid}/availability", {
            "isAvailable": False, "expectedRevision": product["revision"],
        }, self.teacher)
        unavailable = self.review(unavailable)
        self.assertFalse(self.request("GET", f"/shop/products/{pid}")["inStock"])
        self.checkout([product], expected=400)
        self.request("PUT", "/commerce/cart/items", {"productId": pid, "quantity": 0}, self.parent)
        updated = self.request("PUT", f"/marketplace/listings/{pid}", {
            **body, "expectedRevision": unavailable["revision"],
        }, self.teacher)
        self.review(updated)
        before = self.request("GET", "/inventory/stock?pageSize=100", token=self.admin)
        key = uuid.uuid4().hex
        order = self.checkout([product], key=key)
        self.assertEqual(order["order"]["id"], self.checkout([product], key=key)["order"]["id"])
        self.assertEqual(order["items"][0]["sellerId"], product["createdBy"])
        self.assertEqual(before, self.request("GET", "/inventory/stock?pageSize=100", token=self.admin))
        confirmed = self.request("POST", f'/commerce/orders/{order["order"]["id"]}/confirm', token=self.admin)
        self.assertEqual(confirmed["order"]["status"], "preparing")
        self.assertEqual(confirmed["order"]["paymentStatus"], "cod")

    def test_marketplace_mixed_seller_projection_and_manual_shipping(self):
        first, _, _ = self.listing()
        second, _, _ = self.listing(self.other_teacher)
        self.review(first)
        self.review(second)
        order = self.checkout([first, second, {"id": "prod_kit_clay"}])
        oid = order["order"]["id"]
        path = f"/marketplace/orders/{oid}"
        fulfillment = {"carrier": "GHN", "trackingNumber": "MANUAL-" + uuid.uuid4().hex, "status": "shipping"}
        self.request("PUT", path + "/fulfillment", fulfillment, self.teacher, 409)
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.teacher, expected=403)
        self.request("GET", f"/commerce/orders/{oid}", token=self.teacher, expected=404)
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Forbidden"}, self.teacher, 404)
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin)
        for token, own, foreign in [(self.teacher, first, second), (self.other_teacher, second, first)]:
            detail = self.request("GET", path, token=token)
            self.assertEqual([i["productId"] for i in detail["items"]], [own["id"]])
            self.assertEqual(detail["subtotalVnd"], 250000)
            self.assertNotIn("totalAmountVnd", detail)
            self.assertNotIn(foreign["id"], str(detail))
            self.assertNotIn("parentId", detail)
            self.assertEqual(detail["shippingInfo"]["fullAddress"], "123 Test")
        self.request("GET", path, token=self.parent, expected=403)
        self.request("PUT", path + "/fulfillment", {**fulfillment, "status": "delivered"}, self.teacher, 409)
        self.request("PUT", path + "/fulfillment", {**fulfillment, "carrier": "invalid"}, self.teacher, 400)
        for token in [self.teacher, self.other_teacher]:
            shipped = self.request("PUT", path + "/fulfillment", fulfillment, token)
            self.assertEqual(shipped["carrier"], "GHN")
            self.request("PUT", path + "/fulfillment", {**fulfillment, "status": "delivered"}, token)
        self.assertNotEqual(self.request("GET", f"/commerce/orders/{oid}", token=self.parent)["order"]["status"], "delivered")
        shipment = self.request("POST", "/fulfillment/shipments", {
            "orderId": oid, "inventorySkuId": "stock_prod_kit_clay", "carrier": "VNPost",
            "trackingNumber": "PLATFORM-" + uuid.uuid4().hex,
        }, self.admin)
        for status in ["shipping", "delivered"]:
            self.request("POST", f'/fulfillment/shipments/{shipment["id"]}/status', {"status": status}, self.admin)
        final = self.request("GET", f"/commerce/orders/{oid}", token=self.parent)
        self.assertEqual((final["order"]["status"], final["order"]["paymentStatus"]), ("delivered", "paid"))
