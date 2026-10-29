"""Real HTTP integration tests against a fresh migrated SQLite database.
Run: python backend/tests/integration_test.py (after dotnet build backend/ArtKids.slnx).
No third-party Python modules and no existing developer data are used.
"""

import base64
import concurrent.futures
import json
import os
from pathlib import Path
import socket
import sqlite3
import subprocess
import tempfile
import time
import unittest
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "src/ArtKids.API"
PASSWORD = "ArtKids-Test-2026!"
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aGnUAAAAASUVORK5CYII="
)


class ApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (ROOT / ".test-data").mkdir(exist_ok=True)
        cls.temp = tempfile.TemporaryDirectory(dir=ROOT / ".test-data")
        cls.data = Path(cls.temp.name)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        cls.base = f"http://127.0.0.1:{port}"
        env = os.environ.copy()
        env.update(
            ASPNETCORE_ENVIRONMENT="Development",
            Database__Provider="Sqlite",
            ASPNETCORE_URLS=cls.base,
            ConnectionStrings__Sqlite=f'Data Source={cls.data / "test.db"};Default Timeout=15',
            Storage__Root=str(cls.data / "uploads"),
            AI__Mode="Demo",
            Jwt__Key="integration-test-signing-key-with-at-least-64-characters-never-use-in-production",
        )
        cls.postgres = None
        if os.environ.get("ARTKIDS_TEST_POSTGRES") == "1":
            import uuid
            import psycopg
            from psycopg import sql

            cls.postgres = json.loads((ROOT / ".local/postgres-connection.json").read_text())
            cls.pg_database = "artkids_test_" + uuid.uuid4().hex
            with psycopg.connect(
                host=cls.postgres["host"],
                port=cls.postgres["port"],
                dbname="postgres",
                user="postgres",
                password=cls.postgres["adminPassword"],
                autocommit=True,
            ) as connection:
                connection.execute(
                    sql.SQL("CREATE DATABASE {} OWNER {}").format(
                        sql.Identifier(cls.pg_database), sql.Identifier(cls.postgres["username"])
                    )
                )
            env["Database__Provider"] = "Postgres"
            env["ConnectionStrings__Postgres"] = (
                f"Host={cls.postgres['host']};Port={cls.postgres['port']};Database={cls.pg_database};Username={cls.postgres['username']};Password={cls.postgres['password']}"
            )
        cls.log = open(cls.data / "server.log", "w", encoding="utf-8")
        cls.process = subprocess.Popen(
            ["dotnet", str(API / "bin/Debug/net10.0/ArtKids.API.dll")],
            cwd=API,
            env=env,
            stdout=cls.log,
            stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
        )
        for _ in range(120):
            try:
                with urllib.request.urlopen(cls.base + "/health", timeout=1):
                    break
            except (urllib.error.URLError, TimeoutError):
                if cls.process.poll() is not None:
                    raise RuntimeError((cls.data / "server.log").read_text())
                time.sleep(0.25)
        else:
            raise RuntimeError("API did not become healthy.")
        cls.admin = cls.login("admin.test@example.invalid")["accessToken"]
        cls.parent = cls.login("parent.test@example.invalid")["accessToken"]
        cls.teacher = cls.login("instructor.test@example.invalid")["accessToken"]
        cls.other_teacher = cls.login("instructor2.test@example.invalid")["accessToken"]
        cls.request(
            "POST",
            "/auth/register",
            {
                "email": "other@example.invalid",
                "password": PASSWORD,
                "fullName": "Other parent",
                "role": "admin",
            },
        )
        cls.other = cls.login("other@example.invalid")["accessToken"]

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        try:
            cls.process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            cls.process.kill()
            cls.process.wait()
        cls.log.close()
        if cls.postgres:
            import psycopg
            from psycopg import sql

            with psycopg.connect(
                host=cls.postgres["host"],
                port=cls.postgres["port"],
                dbname="postgres",
                user="postgres",
                password=cls.postgres["adminPassword"],
                autocommit=True,
            ) as connection:
                connection.execute(
                    sql.SQL("DROP DATABASE {} WITH (FORCE)").format(sql.Identifier(cls.pg_database))
                )
        # Keep failed-test logs until the Python process exits; TemporaryDirectory owns cleanup.
        cls.temp.cleanup()

    @classmethod
    def request(
        cls, method, path, data=None, token=None, expected=200, raw=None, content_type=None
    ):
        headers = {}
        if token:
            headers["Authorization"] = "Bearer " + token
        if raw is not None:
            body = raw
            headers["Content-Type"] = content_type
        else:
            body = json.dumps(data).encode() if data is not None else None
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(
            cls.base + "/api/v1" + path, data=body, headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                status = response.status
                payload = response.read()
        except urllib.error.HTTPError as e:
            status = e.code
            payload = e.read()
        if status != expected:
            raise AssertionError(
                f'{method} {path}: expected {expected}, got {status}: {payload[:1500].decode(errors="replace")}'
            )
        return json.loads(payload) if payload and payload[:1] in (b"{", b"[") else payload

    @classmethod
    def login(cls, email):
        return cls.request("POST", "/auth/login", {"email": email, "password": PASSWORD})

    def upload(self, data=PNG, kind="drawing", child="child-1", token=None, expected=200):
        boundary = "ArtKidsBoundary12345"
        parts = []
        fields = {"kind": kind}
        if child is not None:
            fields["childId"] = child
        for key, value in fields.items():
            parts.append(
                f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode()
            )
        parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="picture.png"\r\nContent-Type: image/png\r\n\r\n'.encode()
            + data
            + b"\r\n"
        )
        parts.append(f"--{boundary}--\r\n".encode())
        return self.request(
            "POST",
            "/media/upload",
            token=token or self.parent,
            expected=expected,
            raw=b"".join(parts),
            content_type=f"multipart/form-data; boundary={boundary}",
        )

    def consent(self, purpose="data_processing", child="child-1"):
        return self.request(
            "POST",
            "/auth/consent",
            {"childId": child, "purpose": purpose, "policyVersion": "1"},
            self.parent,
        )

    def test_01_authentication_and_ownership(self):
        self.request("GET", "/children", expected=401)
        self.request(
            "POST",
            "/auth/login",
            {"email": "parent.test@example.invalid", "password": "incorrect"},
            expected=401,
        )
        me = self.request("GET", "/auth/me", token=self.other)
        self.assertEqual(me["role"], "parent")
        self.assertNotIn("passwordHash", me)
        self.request("GET", "/children/child-1", token=self.other, expected=404)
        self.request(
            "POST",
            "/shop/products",
            {"name": "X", "priceVnd": 1, "description": "X", "category": "individual_tool"},
            self.parent,
            403,
        )
        self.request(
            "POST",
            "/auth/staff",
            {
                "email": "evil@example.invalid",
                "password": PASSWORD,
                "fullName": "X",
                "role": "admin",
            },
            self.parent,
            403,
        )
        self.request(
            "POST", "/auth/kid-pin/update", {"password": PASSWORD, "pin": "1357"}, self.parent, 204
        )
        self.assertFalse(
            self.request("POST", "/auth/kid-pin/verify", {"pin": "0000"}, self.parent)["valid"]
        )
        self.assertTrue(
            self.request("POST", "/auth/kid-pin/verify", {"pin": "1357"}, self.parent)["valid"]
        )

    def test_02_refresh_rotation_and_logout(self):
        session = self.login("parent.test@example.invalid")
        rotated = self.request("POST", "/auth/refresh", {"refreshToken": session["refreshToken"]})
        self.request(
            "POST", "/auth/refresh", {"refreshToken": session["refreshToken"]}, expected=401
        )
        self.request(
            "POST",
            "/auth/logout",
            {"refreshToken": rotated["refreshToken"]},
            rotated["accessToken"],
            204,
        )
        self.request(
            "POST", "/auth/refresh", {"refreshToken": rotated["refreshToken"]}, expected=401
        )

    def test_03_course_permissions_and_progress(self):
        lesson = self.request("GET", "/lessons/lesson_basics_1?childId=child-1", token=self.parent)
        self.assertFalse(lesson["completed"])
        self.assertEqual(lesson["nextLessonId"], "lesson_basics_2")
        last = self.request("GET", "/lessons/lesson_basics_2?childId=child-1", token=self.parent)
        self.assertIsNone(last["nextLessonId"])
        self.assertGreaterEqual(self.request("GET", "/courses")["total"], 2)
        self.request(
            "PUT",
            "/courses/course_basics",
            {"title": "Hijacked", "description": "x", "ageRange": "4–12", "priceVnd": 0},
            self.other_teacher,
            404,
        )
        self.request(
            "GET", "/lessons/lesson_animals_1?childId=child-1", token=self.parent, expected=403
        )
        self.request(
            "POST", "/enrollments", {"childId": "child-2", "courseId": "course_basics"}, self.parent
        )
        completion = {"childId": "child-1", "lessonId": "lesson_basics_1", "status": "completed", "learningSeconds": 0}
        self.assertFalse(lesson["hasSubmission"])
        self.request("POST", "/courses/progress", completion, self.parent, expected=409)
        self.upload(expected=403)
        self.consent()
        asset = self.upload()
        # Uploading an image alone is not a submitted assignment.
        self.request("POST", "/courses/progress", completion, self.parent, expected=409)
        self.request("POST", "/kid/submissions", {
            "childId": "child-1", "lessonId": "lesson_basics_1", "imageAssetId": asset["id"]
        }, self.parent)
        self.assertTrue(self.request("GET", "/lessons/lesson_basics_1?childId=child-1", token=self.parent)["hasSubmission"])
        self.request("POST", "/courses/progress", {**completion, "childId": "child-2"}, self.parent, expected=409)
        self.request("POST", "/courses/progress", {**completion, "lessonId": "lesson_basics_2"}, self.parent, expected=409)
        progress = self.request(
            "POST",
            "/courses/progress",
            {
                "childId": "child-1",
                "lessonId": "lesson_basics_1",
                "status": "completed",
                "learningSeconds": 60,
            },
            self.parent,
        )
        self.assertEqual(progress["status"], "completed")
        lesson = self.request("GET", "/lessons/lesson_basics_1?childId=child-1", token=self.parent)
        self.assertTrue(lesson["completed"])
        other_child = self.request("GET", "/lessons/lesson_basics_1?childId=child-2", token=self.parent)
        self.assertFalse(other_child["completed"])
        lessons = self.request("GET", "/courses/course_basics/lessons?childId=child-1", token=self.parent)
        self.assertTrue(next(x for x in lessons if x["id"] == "lesson_basics_1")["completed"])
        self.assertFalse(next(x for x in lessons if x["id"] == "lesson_basics_2")["completed"])
        other_lessons = self.request("GET", "/courses/course_basics/lessons?childId=child-2", token=self.parent)
        self.assertTrue(all(not x["completed"] for x in other_lessons))
        self.request("GET", "/courses/course_basics/lessons?childId=child-1", token=self.other, expected=404)
        self.request("GET", "/courses/course_basics/lessons?childId=child-1", expected=404)
        self.request(
            "POST",
            "/courses/progress",
            {
                "childId": "child-1",
                "lessonId": "lesson_basics_1",
                "status": "in_progress",
                "learningSeconds": 0,
            },
            self.parent,
        )
        rows = self.request("GET", "/courses/progress?childId=child-1", token=self.parent)
        self.assertEqual(rows[0]["completedLessons"], 1)
        self.request(
            "POST",
            "/courses/progress",
            {"childId": "child-1", "lessonId": "lesson_basics_2", "status": "completed"},
            self.other,
            404,
        )

    def test_04_upload_submission_review_and_ai(self):
        self.consent()
        self.upload(data=b"not-an-image", expected=415)
        asset = self.upload()
        self.request("GET", f'/media/{asset["id"]}', token=self.other, expected=404)
        submission = self.request(
            "POST",
            "/kid/submissions",
            {"childId": "child-1", "lessonId": "lesson_basics_1", "imageAssetId": asset["id"]},
            self.parent,
        )
        sid = submission["id"]
        self.request(
            "POST",
            f"/kid/submissions/{sid}/reviews",
            {"score": 9, "feedback": "Great"},
            self.other_teacher,
            404,
        )
        self.request(
            "POST",
            f"/kid/submissions/{sid}/reviews",
            {"score": 11, "feedback": "Invalid"},
            self.teacher,
            400,
        )
        self.request("GET", f'/media/{asset["id"]}', token=self.teacher)
        review = self.request(
            "POST",
            f"/kid/submissions/{sid}/reviews",
            {"score": 9.5, "feedback": "Nét vẽ rõ và phối màu đẹp."},
            self.teacher,
        )
        self.assertEqual(review["score"], 9.5)
        self.request("GET", f"/kid/submissions/{sid}", token=self.other, expected=404)
        self.request("POST", "/ai/generate", {"submissionId": sid}, self.parent, 403)
        self.consent("ai_generation")
        job = self.request("POST", "/ai/generate", {"submissionId": sid}, self.parent, 202)
        for _ in range(30):
            result = self.request("GET", "/ai/jobs/" + job["id"], token=self.parent)
            if result["job"]["status"] in ("completed", "failed"):
                break
            time.sleep(0.5)
        self.assertEqual(result["job"]["status"], "completed", result)
        self.assertIn("demo", result["result"]["displayName"])
        badges = self.request("GET", "/children/child-1/badges", token=self.parent)
        self.assertTrue(any(x["isUnlocked"] for x in badges))

    def test_05_checkout_atomicity_idempotency_and_cancel(self):
        self.request(
            "PUT",
            "/commerce/cart/items",
            {"productId": "prod_kit_animal", "quantity": 2},
            self.parent,
        )
        self.request(
            "POST",
            "/commerce/checkout",
            {
                "idempotencyKey": "test-no-stock",
                "items": [{"itemType": "kit", "itemId": "prod_kit_animal", "quantity": 99}],
                "shipping": {
                    "recipientName": "Test",
                    "phoneNumber": "0900000000",
                    "fullAddress": "Test address",
                },
            },
            self.parent,
            409,
        )
        stock = self.request("GET", "/inventory/stock/SKU-PROD_KIT_ANIMAL", token=self.admin)
        self.assertEqual(stock["quantityAvailable"], 50)
        payload = {
            "idempotencyKey": "test-checkout-01",
            "items": [{"itemType": "kit", "itemId": "prod_kit_animal", "quantity": 2}],
            "voucherCode": "ARTKIDS10",
            "shipping": {
                "recipientName": "Test",
                "phoneNumber": "0900000000",
                "fullAddress": "Test address",
            },
        }
        order = self.request("POST", "/commerce/checkout", payload, self.parent)
        oid = order["order"]["id"]
        self.assertEqual(order["order"]["totalAmountVnd"], 324000)
        repeated = self.request("POST", "/commerce/checkout", payload, self.parent)
        self.assertEqual(repeated["order"]["id"], oid)
        stock = self.request("GET", "/inventory/stock/SKU-PROD_KIT_ANIMAL", token=self.admin)
        self.assertEqual((stock["quantityAvailable"], stock["quantityReserved"]), (48, 2))
        self.request("GET", "/commerce/orders/" + oid, token=self.other, expected=404)
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.parent, expected=403)
        self.request(
            "POST", f"/commerce/orders/{oid}/cancel", {"reason": "Test cancellation"}, self.parent
        )
        self.request("POST", f"/commerce/orders/{oid}/cancel", {"reason": "Retry"}, self.parent)
        stock = self.request("GET", "/inventory/stock/SKU-PROD_KIT_ANIMAL", token=self.admin)
        self.assertEqual((stock["quantityAvailable"], stock["quantityReserved"]), (50, 0))

    def test_06_confirm_delivery_and_subscription(self):
        payload = {
            "idempotencyKey": "test-delivery-01",
            "items": [{"itemType": "kit", "itemId": "prod_tool_brushes", "quantity": 1}],
            "shipping": {
                "recipientName": "Test",
                "phoneNumber": "0900000000",
                "fullAddress": "Test address",
            },
        }
        order = self.request("POST", "/commerce/checkout", payload, self.parent)
        oid = order["order"]["id"]
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin)
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin)
        self.request(
            "POST", f"/commerce/orders/{oid}/cancel", {"reason": "Too late"}, self.parent, 409
        )
        shipment = self.request(
            "POST",
            "/fulfillment/shipments",
            {
                "orderId": oid,
                "inventorySkuId": "stock_prod_tool_brushes",
                "carrier": "GHN",
                "trackingNumber": "TEST-001",
            },
            self.admin,
        )
        self.request(
            "POST",
            f'/fulfillment/shipments/{shipment["id"]}/status',
            {"status": "delivered"},
            self.admin,
            409,
        )
        self.request(
            "POST",
            f'/fulfillment/shipments/{shipment["id"]}/status',
            {"status": "shipping"},
            self.admin,
        )
        self.request(
            "POST",
            f'/fulfillment/shipments/{shipment["id"]}/status',
            {"status": "delivered"},
            self.admin,
        )
        delivered = self.request("GET", "/commerce/orders/" + oid, token=self.parent)
        self.assertEqual(delivered["order"]["status"], "delivered")
        sub = self.request(
            "POST",
            "/commerce/checkout",
            {
                "idempotencyKey": "test-subscription-01",
                "childId": "child-1",
                "items": [{"itemType": "subscription", "itemId": "plan_monthly", "quantity": 1}],
            },
            self.parent,
        )
        self.request("POST", f'/commerce/orders/{sub["order"]["id"]}/confirm', token=self.admin)
        enrolled = self.request(
            "POST",
            "/enrollments",
            {"childId": "child-1", "courseId": "course_animals"},
            self.parent,
        )
        self.assertEqual(enrolled["courseId"], "course_animals")
        # Move the subscription window into the past; an expired subscription must not grant video access.
        if self.postgres:
            import psycopg

            now = datetime.now(timezone.utc)
            with psycopg.connect(
                host=self.postgres["host"],
                port=self.postgres["port"],
                dbname=self.pg_database,
                user=self.postgres["username"],
                password=self.postgres["password"],
            ) as db:
                db.execute(
                    "UPDATE subscriptions SET starts_at=%s, ends_at=%s",
                    (now - timedelta(days=31), now - timedelta(days=1)),
                )
        else:
            self.expire_sqlite_subscriptions()
        self.request(
            "GET", "/lessons/lesson_animals_1?childId=child-1", token=self.parent, expected=403
        )
        purchase = self.request(
            "POST",
            "/commerce/checkout",
            {
                "idempotencyKey": "test-own-course-after-expiry",
                "childId": "child-1",
                "items": [{"itemType": "course", "itemId": "course_animals", "quantity": 1}],
            },
            self.parent,
        )
        self.request(
            "POST", f'/commerce/orders/{purchase["order"]["id"]}/confirm', token=self.admin
        )
        self.request("GET", "/lessons/lesson_animals_1?childId=child-1", token=self.parent)

    def expire_sqlite_subscriptions(self):
        with sqlite3.connect(self.data / "test.db") as db:
            now = datetime.now(timezone.utc)
            db.execute(
                "UPDATE subscriptions SET starts_at=?, ends_at=?",
                (
                    (now - timedelta(days=31)).strftime("%Y-%m-%d %H:%M:%S"),
                    (now - timedelta(days=1)).strftime("%Y-%m-%d %H:%M:%S"),
                ),
            )

    def test_07_live_capacity_30_and_teacher_access(self):
        cls = self.request(
            "POST",
            "/live/classes",
            {"courseId": "course_basics", "name": "30 students", "capacity": 30},
            self.teacher,
        )
        self.request(
            "POST",
            "/live/classes",
            {"courseId": "course_basics", "name": "Invalid", "capacity": 31},
            self.teacher,
            400,
        )
        self.request(
            "POST", f'/live/classes/{cls["id"]}/enrollments', {"childId": "child-1"}, self.parent
        )
        for i in range(29):
            child = self.request(
                "POST", "/children", {"nickname": f"Student {i}", "birthYear": 2018}, self.parent
            )
            self.request(
                "POST",
                "/enrollments",
                {"childId": child["id"], "courseId": "course_basics"},
                self.parent,
            )
            self.request(
                "POST",
                f'/live/classes/{cls["id"]}/enrollments',
                {"childId": child["id"]},
                self.parent,
            )
        self.request(
            "POST",
            f'/live/classes/{cls["id"]}/enrollments',
            {"childId": "child-2"},
            self.parent,
            409,
        )
        roster = self.request("GET", f'/live/classes/{cls["id"]}/roster', token=self.teacher)
        self.assertEqual(len(roster), 30)
        self.request(
            "GET", f'/live/classes/{cls["id"]}/roster', token=self.other_teacher, expected=404
        )
        now = datetime.now(timezone.utc)
        payload = {
            "title": "Live art",
            "startsAt": (now + timedelta(minutes=5)).isoformat().replace("+00:00", "Z"),
            "endsAt": (now + timedelta(minutes=65)).isoformat().replace("+00:00", "Z"),
            "lessonId": "lesson_basics_1",
            "roomUrl": "https://meet.example.invalid/test-room",
        }
        session = self.request("POST", f'/live/classes/{cls["id"]}/sessions', payload, self.teacher)
        self.request("POST", f'/live/classes/{cls["id"]}/sessions', payload, self.teacher, 409)
        join = self.request(
            "POST", f'/live/sessions/{session["id"]}/join', {"childId": "child-1"}, self.parent
        )
        self.assertIn("joinUrl", join)
        self.request(
            "POST", f'/live/sessions/{session["id"]}/join', {"childId": "child-2"}, self.parent, 403
        )
        self.request(
            "POST", f'/live/sessions/{session["id"]}/leave', {"childId": "child-1"}, self.parent
        )
        attendance = self.request(
            "GET", f'/live/sessions/{session["id"]}/attendance', token=self.teacher
        )
        self.assertEqual(len(attendance), 1)
        self.request(
            "PUT",
            f'/live/classes/{cls["id"]}',
            {"name": "Too small", "capacity": 29, "status": "open"},
            self.teacher,
            409,
        )
        self.request(
            "PUT",
            f'/live/classes/{cls["id"]}',
            {"name": "Closed", "capacity": 30, "status": "completed"},
            self.teacher,
        )
        self.request(
            "POST", f'/live/sessions/{session["id"]}/join', {"childId": "child-1"}, self.parent, 409
        )

    def test_08_concurrent_last_seat(self):
        cls = self.request(
            "POST",
            "/live/classes",
            {"courseId": "course_basics", "name": "Last seat", "capacity": 1},
            self.teacher,
        )

        def attempt(child):
            try:
                self.request(
                    "POST",
                    f'/live/classes/{cls["id"]}/enrollments',
                    {"childId": child},
                    self.parent,
                )
                return 200
            except AssertionError as error:
                if "got 409" in str(error):
                    return 409
                raise

        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            statuses = list(pool.map(attempt, ["child-1", "child-2"]))
        self.assertEqual(sorted(statuses), [200, 409])

    def test_09_matching_game_validation_and_gallery(self):
        self.request(
            "PUT",
            "/children/child-1/game/living_room",
            {
                "currentStep": "matching",
                "currentAnimalIndex": 3,
                "unlockedStickers": ["cat"],
                "matchedAnimals": ["dog"],
            },
            self.parent,
            400,
        )
        self.request(
            "PUT",
            "/children/child-1/game/living_room",
            {
                "currentStep": "matching",
                "currentAnimalIndex": 3,
                "unlockedStickers": ["cat", "dog", "bird"],
                "matchedAnimals": ["cat", "dog", "bird"],
            },
            self.parent,
        )
        one = self.request("POST", "/children/child-1/game/living_room/complete", token=self.parent)
        two = self.request("POST", "/children/child-1/game/living_room/complete", token=self.parent)
        self.assertEqual(one["id"], two["id"])
        self.request("GET", "/children/child-1/gallery", token=self.other, expected=404)

    def test_10_swagger_and_catalogue_contracts(self):
        with urllib.request.urlopen(self.base + "/swagger/v1/swagger.json") as response:
            doc = json.load(response)
        self.assertGreaterEqual(len(doc["paths"]), 60)
        self.assertIn("/api/v1/live/sessions/{id}/join", doc["paths"])
        self.request(
            "POST",
            "/vouchers/validate",
            {"code": "EXPIRED20", "subtotalVnd": 500000},
            self.parent,
            400,
        )
        self.request(
            "POST",
            "/vouchers/validate",
            {"code": "ARTKIDS10", "subtotalVnd": 10000},
            self.parent,
            400,
        )

    def test_11_subscription_monthly_kit_schedule(self):
        plan = self.request(
            "POST",
            "/commerce/plans",
            {
                "name": "Three monthly kits",
                "priceVnd": 900000,
                "durationMonths": 3,
                "includesKit": True,
                "kitInventorySkuId": "stock_prod_kit_clay",
                "kitQuantity": 2,
            },
            self.admin,
        )
        order = self.request(
            "POST",
            "/commerce/checkout",
            {
                "idempotencyKey": "test-recurring-kits-01",
                "childId": "child-1",
                "items": [{"itemType": "subscription", "itemId": plan["id"], "quantity": 1}],
                "shipping": {
                    "recipientName": "Test",
                    "phoneNumber": "0900000000",
                    "fullAddress": "Test address",
                },
            },
            self.parent,
        )
        self.assertEqual(order["order"]["shippingFeeVnd"], 0)
        oid = order["order"]["id"]
        self.request("POST", f"/commerce/orders/{oid}/confirm", token=self.admin)
        stock = self.request("GET", "/inventory/stock/SKU-PROD_KIT_CLAY", token=self.admin)
        self.assertEqual((stock["quantityAvailable"], stock["quantityReserved"]), (44, 0))
        subscriptions = self.request("GET", "/commerce/subscriptions", token=self.parent)
        subscription = next(s for s in subscriptions if s["planId"] == plan["id"])
        schedule = self.request(
            "GET", f'/commerce/subscriptions/{subscription["id"]}/kit-deliveries', token=self.parent
        )
        self.assertEqual(len(schedule), 3)
        self.assertEqual(sum(s["delivery"]["quantity"] for s in schedule), 6)
        first = schedule[0]["delivery"]
        third = schedule[2]["delivery"]
        self.request(
            "POST",
            "/fulfillment/shipments",
            {
                "orderId": oid,
                "inventorySkuId": "stock_prod_kit_clay",
                "carrier": "GHN",
                "trackingNumber": "FUTURE-KIT",
                "subscriptionKitDeliveryId": third["id"],
            },
            self.admin,
            409,
        )
        shipment = self.request(
            "POST",
            "/fulfillment/shipments",
            {
                "orderId": oid,
                "inventorySkuId": "stock_prod_kit_clay",
                "carrier": "GHN",
                "trackingNumber": "MONTHLY-KIT-1",
                "subscriptionKitDeliveryId": first["id"],
            },
            self.admin,
        )
        self.assertEqual(shipment["quantity"], 2)
        self.request(
            "POST",
            f'/fulfillment/shipments/{shipment["id"]}/status',
            {"status": "shipping"},
            self.admin,
        )
        self.request(
            "POST",
            f'/fulfillment/shipments/{shipment["id"]}/status',
            {"status": "delivered"},
            self.admin,
        )
        self.assertEqual(
            self.request("GET", f"/commerce/orders/{oid}", token=self.parent)["order"]["status"],
            "shipping",
        )

    def test_12_instructor_course_product_listing(self):
        self.consent()
        drawing = self.upload()
        self.request("GET", f'/media/products/{drawing["id"]}', expected=404)
        video = self.upload(data=b"0000ftypisom", kind="video", child=None, token=self.teacher)
        self.request("GET", f'/media/products/{video["id"]}', expected=404)
        image = self.upload(kind="product_image", child=None, token=self.teacher)
        url = image["url"]
        self.request("GET", url.removeprefix("/api/v1"), expected=404)
        body = {
            "name": "Teacher watercolor kit",
            "priceVnd": 125000,
            "description": "Brushes and watercolors for the drawing lessons.",
            "imageAssetId": image["id"],
            "quantityAvailable": 3,
        }
        path = "/courses/course_basics/products"
        self.request("POST", path, body, self.other_teacher, 404)
        self.request("POST", path, body, self.parent, 403)
        for changes in [
            {"priceVnd": 0},
            {"quantityAvailable": 0},
            {"name": ""},
            {"description": ""},
        ]:
            self.request("POST", path, {**body, **changes}, self.teacher, 400)
        self.upload(kind="product_image", child=None, token=self.parent, expected=403)
        self.upload(
            data=b"not an image", kind="product_image", child=None, token=self.teacher, expected=415
        )
        foreign = self.upload(kind="product_image", child=None, token=self.other_teacher)
        self.request("POST", path, {**body, "imageAssetId": foreign["id"]}, self.teacher, 403)
        product = self.request("POST", path, body, self.teacher)
        self.assertEqual(product["courseId"], "course_basics")
        self.assertEqual(product["category"], "course_kit")
        self.assertEqual(product["thumbnailUrl"], url)
        self.assertEqual(product["approvalStatus"], "pending")
        self.request("GET", url.removeprefix("/api/v1"), expected=404)
        product = self.request("POST", f'/marketplace/reviews/{product["id"]}',
            {"status": "approved", "expectedRevision": product["revision"]}, self.admin)
        self.assertEqual(self.request("GET", url.removeprefix("/api/v1")), PNG)
        self.request("POST", path, body, self.teacher, 409)
        listing = self.request("GET", "/shop/products?courseId=course_basics&pageSize=100")
        matches = [p for p in listing["items"] if p["product"]["id"] == product["id"]]
        self.assertTrue(matches[0]["inStock"])
        self.assertTrue(all(p["product"]["courseId"] == "course_basics" for p in listing["items"]))
        self.assertFalse(
            any(
                p["product"]["id"] == product["id"]
                for p in self.request("GET", "/shop/products?courseId=course_animals")["items"]
            )
        )
        self.request(
            "PUT", "/commerce/cart/items", {"productId": product["id"], "quantity": 1}, self.parent
        )
        order = self.request(
            "POST",
            "/commerce/checkout",
            {
                "idempotencyKey": "teacher-kit-purchase-001",
                "items": [{"itemType": "kit", "itemId": product["id"], "quantity": 1}],
                "paymentMethod": "cod",
                "shipping": {
                    "recipientName": "Parent",
                    "phoneNumber": "0901234567",
                    "fullAddress": "123 Test Street",
                },
            },
            self.parent,
        )
        self.assertEqual(order["items"][0]["unitPriceVnd"], 125000)
        self.request(
            "POST",
            f'/commerce/orders/{order["order"]["id"]}/cancel',
            {"reason": "Test complete"},
            self.parent,
        )
        self.request("DELETE", f'/marketplace/listings/{product["id"]}', token=self.teacher, expected=204)
        self.request("GET", url.removeprefix("/api/v1"), expected=404)

    def test_13_course_and_product_management(self):
        course_body = {
            "title": "Editable course",
            "description": "Original course",
            "ageRange": "5-10",
            "priceVnd": 0,
            "isPublished": True,
        }
        course = self.request("POST", "/courses", course_body, self.teacher)
        cid = course["id"]
        self.request(
            "PUT",
            f"/courses/{cid}",
            {**course_body, "title": "Edited course"},
            self.other_teacher,
            404,
        )
        self.request("DELETE", f"/courses/{cid}", token=self.other_teacher, expected=404)
        self.request("DELETE", f"/courses/{cid}", token=self.parent, expected=403)
        self.request(
            "PUT", f"/courses/{cid}", {**course_body, "title": "Edited course"}, self.teacher
        )
        self.assertEqual(self.request("GET", f"/courses/{cid}")["title"], "Edited course")
        lesson = self.request(
            "POST",
            f"/courses/{cid}/lessons",
            {"title": "Retained lesson", "orderIndex": 1},
            self.teacher,
        )
        self.request("POST", "/enrollments", {"childId": "child-1", "courseId": cid}, self.parent)
        image = self.upload(kind="product_image", child=None, token=self.teacher)
        product = self.request(
            "POST",
            f"/courses/{cid}/products",
            {
                "name": "Editable kit",
                "description": "Original use",
                "priceVnd": 125000,
                "quantityAvailable": 5,
                "imageAssetId": image["id"],
            },
            self.teacher,
        )
        pid = product["id"]
        product = self.request("POST", f'/marketplace/reviews/{pid}',
            {"status": "approved", "expectedRevision": product["revision"]}, self.admin)
        path = f"/courses/{cid}/products/{pid}"
        self.request("GET", f"/courses/{cid}/products", token=self.other_teacher, expected=404)
        self.request("GET", f"/courses/{cid}/products", token=self.parent, expected=403)
        order = self.request(
            "POST",
            "/commerce/checkout",
            {
                "idempotencyKey": "editable-kit-order-001",
                "items": [{"itemType": "kit", "itemId": pid, "quantity": 1}],
                "shipping": {
                    "recipientName": "Parent",
                    "phoneNumber": "0901234567",
                    "fullAddress": "123 Test Street",
                },
            },
            self.parent,
        )
        edited = {
            "name": "Updated kit",
            "description": "Updated use",
            "priceVnd": 199000,
            "quantityAvailable": 4,
            "expectedQuantityAvailable": 4,
        }
        self.request("PUT", path, edited, self.other_teacher, 404)
        self.request("DELETE", path, token=self.other_teacher, expected=404)
        self.request("PUT", path, edited, self.parent, 403)
        self.request("PUT", path, {**edited, "priceVnd": -1}, self.teacher, 400)
        self.request("PUT", f"/courses/course_basics/products/{pid}", edited, self.teacher, 404)
        self.request("PUT", f"/marketplace/listings/{pid}", {
            **edited, "courseId": cid, "expectedRevision": product["revision"] - 1,
        }, self.teacher, 409)
        replacement = self.upload(kind="product_image", child=None, token=self.teacher)
        updated = self.request(
            "PUT", path, {**edited, "imageAssetId": replacement["id"]}, self.teacher
        )
        self.assertEqual(updated["thumbnailUrl"], replacement["url"])
        self.request("GET", replacement["url"].removeprefix("/api/v1"), expected=404)
        self.request("POST", f'/marketplace/reviews/{pid}',
            {"status": "approved", "expectedRevision": updated["revision"]}, self.admin)
        self.assertEqual(self.request("GET", replacement["url"].removeprefix("/api/v1")), PNG)
        entries = self.request("GET", f"/courses/{cid}/products", token=self.teacher)
        self.assertEqual(entries[0]["quantityAvailable"], 1)
        self.assertEqual(entries[0]["quantityReserved"], 0)
        detail = self.request("GET", f'/commerce/orders/{order["order"]["id"]}', token=self.parent)
        self.assertEqual(detail["items"][0]["unitPriceVnd"], 125000)
        self.request("DELETE", path, token=self.teacher, expected=204)
        self.assertEqual(self.request("GET", f"/courses/{cid}/products", token=self.teacher), [])
        self.request("GET", f"/shop/products/{pid}", expected=404)
        self.request(
            "POST",
            f'/commerce/orders/{order["order"]["id"]}/cancel',
            {"reason": "Keep order history"},
            self.parent,
        )
        image2 = self.upload(kind="product_image", child=None, token=self.teacher)
        second = self.request(
            "POST",
            f"/courses/{cid}/products",
            {
                "name": "Archived with course",
                "description": "Use",
                "priceVnd": 10000,
                "quantityAvailable": 1,
                "imageAssetId": image2["id"],
            },
            self.teacher,
        )
        self.request("DELETE", f"/courses/{cid}", token=self.teacher, expected=204)
        for token in [None, self.teacher, self.admin]:
            self.assertFalse(
                any(
                    c["id"] == cid
                    for c in self.request("GET", "/courses?pageSize=100", token=token)["items"]
                )
            )
        self.request("GET", f"/courses/{cid}", expected=404)
        self.request("GET", f'/shop/products/{second["id"]}', expected=404)
        self.assertEqual(self.request("GET", f"/shop/products?courseId={cid}")["items"], [])
        self.request("PUT", f"/courses/{cid}", course_body, self.teacher, 404)
        self.request("GET", f"/courses/{cid}/products", token=self.teacher, expected=404)
        self.request(
            "POST", "/enrollments", {"childId": "child-2", "courseId": cid}, self.parent, 404
        )
        self.assertEqual(
            self.request("GET", f'/lessons/{lesson["id"]}?childId=child-1', token=self.parent)[
                "title"
            ],
            "Retained lesson",
        )
        self.assertEqual(len(self.request("GET", f"/courses/{cid}/lessons", token=self.parent)), 1)
        self.assertEqual(
            self.request("GET", f'/commerce/orders/{order["order"]["id"]}', token=self.parent)[
                "order"
            ]["status"],
            "cancelled",
        )


    def test_14_grading_hierarchy(self):
        self.request("GET", "/grading/courses", token=self.parent, expected=403)
        self.request("GET", "/grading/courses", expected=401)
        self.request("GET", "/grading/courses/course_basics/lessons", token=self.other_teacher, expected=404)
        self.request("GET", "/grading/lessons/lesson_basics_1/submissions", token=self.other_teacher, expected=404)
        self.consent()
        asset = self.upload()
        submission = self.request("POST", "/kid/submissions", {
            "childId": "child-1", "lessonId": "lesson_basics_1", "imageAssetId": asset["id"]
        }, self.parent)
        courses = self.request("GET", "/grading/courses", token=self.teacher)
        before = next(x for x in courses if x["id"] == "course_basics")["pendingCount"]
        self.assertGreaterEqual(before, 1)
        lessons = self.request("GET", "/grading/courses/course_basics/lessons", token=self.teacher)["lessons"]
        self.assertGreaterEqual(next(x for x in lessons if x["id"] == "lesson_basics_1")["pendingCount"], 1)
        rows = self.request("GET", "/grading/lessons/lesson_basics_1/submissions", token=self.teacher)
        row = next(x for x in rows["items"] if x["id"] == submission["id"])
        self.assertEqual(row["childId"], "child-1")
        self.assertTrue(row["childName"])
        self.assertGreater(row["birthYear"], 2000)
        detail = self.request("GET", "/kid/submissions/" + submission["id"], token=self.teacher)
        self.assertEqual(detail["child"]["id"], "child-1")
        self.request("POST", "/kid/submissions/" + submission["id"] + "/reviews", {"score": 8, "feedback": "Good drawing"}, self.teacher)
        courses = self.request("GET", "/grading/courses", token=self.teacher)
        self.assertEqual(next(x for x in courses if x["id"] == "course_basics")["pendingCount"], before - 1)
        pending = self.request("GET", "/grading/lessons/lesson_basics_1/submissions", token=self.teacher)
        self.assertFalse(any(x["id"] == submission["id"] for x in pending["items"]))
        all_rows = self.request("GET", "/grading/lessons/lesson_basics_1/submissions?pendingOnly=false", token=self.teacher)
        self.assertTrue(any(x["id"] == submission["id"] for x in all_rows["items"]))


    def test_15_family_submission_browser(self):
        base = "/family/submission-browser?childId=child-1"
        self.request("GET", base, expected=401)
        self.request("GET", base, token=self.teacher, expected=403)
        self.request("GET", base, token=self.other, expected=404)
        self.request("POST", "/enrollments", {"childId": "child-2", "courseId": "course_basics"}, self.parent)
        self.consent()
        asset = self.upload()
        submission = self.request("POST", "/kid/submissions", {
            "childId": "child-1", "lessonId": "lesson_basics_1", "imageAssetId": asset["id"]
        }, self.parent)
        courses = self.request("GET", base, token=self.parent)
        course = next(x for x in courses["items"] if x["id"] == "course_basics")
        self.assertGreaterEqual(course["totalCount"], 1)
        self.assertGreaterEqual(course["pendingCount"], 1)
        lessons = self.request("GET", base + "&courseId=course_basics", token=self.parent)
        lesson = next(x for x in lessons["items"] if x["id"] == "lesson_basics_1")
        self.assertEqual(lesson["pendingCount"] + lesson["reviewedCount"], lesson["totalCount"])
        rows = self.request("GET", base + "&lessonId=lesson_basics_1&status=pending_review", token=self.parent)
        self.assertTrue(any(x["id"] == submission["id"] for x in rows["items"]))
        self.assertTrue(all(x["status"] == "pending_review" for x in rows["items"]))
        sibling = self.request("GET", "/family/submission-browser?childId=child-2&lessonId=lesson_basics_1", token=self.parent)
        self.assertEqual(sibling["total"], 0)
        self.request("POST", "/kid/submissions/" + submission["id"] + "/reviews", {"score": 9, "feedback": "Well done"}, self.teacher)
        rows = self.request("GET", base + "&lessonId=lesson_basics_1&status=reviewed", token=self.parent)
        self.assertTrue(any(x["id"] == submission["id"] for x in rows["items"]))
        self.request("GET", base + "&lessonId=lesson_basics_1&status=invalid", token=self.parent, expected=400)
        self.request("GET", base + "&unassigned=true", token=self.parent)


if __name__ == "__main__":
    unittest.main(verbosity=2)
