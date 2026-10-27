"""Real API and browser tests with an isolated Cloudinary HTTP test double.

No Cloudinary credentials or network uploads are used. Includes existing API tests.
Run after building API and Flutter web: python backend/tests/cloudinary_test.py
"""

import base64
import hashlib
import json
import os
import subprocess
import sys
import re
import threading
import time
import unittest
import urllib.parse
import urllib.request
from email.parser import BytesParser
from email.policy import default
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from integration_test import ApiTests, PNG

SECRET = "cloudinary-test-secret-not-a-real-credential"
KEY = "test-key"


def signature(fields):
    serialized = "&".join(f"{key}={value}" for key, value in sorted(fields.items()))
    return hashlib.sha256((serialized + SECRET).encode()).hexdigest()


class CloudinaryMock(BaseHTTPRequestHandler):
    assets = {}
    chunks = {}
    requests = []

    def log_message(self, *_):
        pass

    def send(self, status, body, content_type="application/json", extra=None):
        payload = json.dumps(body).encode() if isinstance(body, dict) else body
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Access-Control-Allow-Origin", "*")
        for name, value in (extra or {}).items():
            self.send_header(name, str(value))
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self):
        self.send(
            204,
            b"",
            extra={
                "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
                "Access-Control-Allow-Headers": "content-type,content-range,x-unique-upload-id",
            },
        )

    def do_POST(self):
        self.requests.append(("POST", self.path, dict(self.headers)))
        content = self.rfile.read(int(self.headers["Content-Length"]))
        message = BytesParser(policy=default).parsebytes(
            (
                "Content-Type: " + self.headers["Content-Type"] + "\r\nMIME-Version: 1.0\r\n\r\n"
            ).encode()
            + content
        )
        fields = {}
        file = b""
        for part in message.iter_parts():
            name = part.get_param("name", header="content-disposition")
            if name == "file":
                file = part.get_payload(decode=True)
            else:
                fields[name] = part.get_payload(decode=True).decode()
        expected = {
            key: value for key, value in fields.items() if key not in ("api_key", "signature")
        }
        if (
            fields.get("signature") != signature(expected)
            or fields.get("api_key") != KEY
            or self.headers.get("Authorization")
        ):
            return self.send(401, {"error": "Invalid upload authentication"})
        public_id = fields["public_id"]
        content_range = self.headers.get("Content-Range")
        if content_range:
            start, end, total = map(
                int, re.fullmatch(r"bytes (\d+)-(\d+)/(\d+)", content_range).groups()
            )
            upload_id = self.headers["X-Unique-Upload-Id"]
            current = self.chunks.setdefault(upload_id, bytearray())
            if len(current) != start or len(file) != end - start + 1:
                return self.send(400, {"error": "Invalid chunk range"})
            current.extend(file)
            if len(current) < total:
                return self.send(200, {"done": False})
            file = bytes(current)
        self.assets[public_id] = {
            "public_id": public_id,
            "resource_type": "video",
            "type": "authenticated",
            "format": "mp4",
            "bytes": len(file),
            "version": 12345,
            "width": 1280,
            "height": 720,
            "duration": 119.083333,
            "content": file,
        }
        self.send(200, {"public_id": public_id, "version": 12345, "done": True})

    def do_GET(self):
        self.requests.append(("GET", self.path, dict(self.headers)))
        parsed = urllib.parse.urlparse(self.path)
        if "/resources/video/authenticated/" in parsed.path:
            if (
                self.headers.get("Authorization")
                != "Basic " + base64.b64encode((KEY + ":" + SECRET).encode()).decode()
            ):
                return self.send(401, {"error": "Invalid admin authentication"})
            public_id = urllib.parse.unquote(
                parsed.path.split("/resources/video/authenticated/", 1)[1]
            )
            asset = self.assets.get(public_id)
            metadata = urllib.parse.parse_qs(parsed.query).get("media_metadata") == ["true"]
            return self.send(
                200 if asset else 404,
                (
                    {
                        key: value
                        for key, value in asset.items()
                        if key != "content" and (key != "duration" or metadata)
                    }
                    if asset
                    else {"error": "Not found"}
                ),
            )
        fields = dict(urllib.parse.parse_qsl(parsed.query))
        expected = {
            key: value for key, value in fields.items() if key not in ("signature", "api_key")
        }
        if (
            fields.get("signature") != signature(expected)
            or int(fields.get("expires_at", "0")) < time.time()
        ):
            return self.send(403, {"error": "Invalid or expired playback signature"})
        asset = self.assets.get(fields.get("public_id"))
        if not asset:
            return self.send(404, {"error": "Not found"})
        content = asset["content"]
        headers = {"Accept-Ranges": "bytes"}
        if self.headers.get("Range"):
            match = re.fullmatch(r"bytes=(\d+)-(\d*)", self.headers["Range"])
            start = int(match[1])
            end = min(int(match[2]) if match[2] else len(content) - 1, len(content) - 1)
            headers["Content-Range"] = f"bytes {start}-{end}/{len(content)}"
            return self.send(206, content[start : end + 1], "video/mp4", headers)
        self.send(200, content, "video/mp4", headers)


class CloudinaryTests(ApiTests):
    @classmethod
    def setUpClass(cls):
        cls.cloud = ThreadingHTTPServer(("127.0.0.1", 0), CloudinaryMock)
        cls.cloud_thread = threading.Thread(target=cls.cloud.serve_forever, daemon=True)
        cls.cloud_thread.start()
        cls.cloud_root = f"http://127.0.0.1:{cls.cloud.server_port}"
        cls.previous = {
            key: os.environ.get(key)
            for key in (
                "Cloudinary__CloudName",
                "Cloudinary__ApiKey",
                "Cloudinary__ApiSecret",
                "Cloudinary__ApiBaseUrl",
            )
        }
        os.environ.update(
            Cloudinary__CloudName="artkids-test",
            Cloudinary__ApiKey=KEY,
            Cloudinary__ApiSecret=SECRET,
            Cloudinary__ApiBaseUrl=cls.cloud_root,
        )
        super().setUpClass()

    @classmethod
    def tearDownClass(cls):
        try:
            super().tearDownClass()
        finally:
            cls.cloud.shutdown()
            cls.cloud.server_close()
            for key, value in cls.previous.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

    def prepare(self, **overrides):
        return self.request(
            "POST",
            "/courses/course_basics/lessons/video-upload",
            {"fileName": "lesson.mp4", "sizeBytes": 24, **overrides},
            self.teacher,
        )

    def test_14_verified_cloudinary_upload_and_access(self):
        path = "/courses/course_basics/lessons/video-upload"
        self.request("POST", path, {"fileName": "v.mp4", "sizeBytes": 24}, self.parent, 403)
        self.request("POST", path, {"fileName": "v.mp4", "sizeBytes": 24}, self.other_teacher, 404)
        self.request("POST", path, {"fileName": "v.exe", "sizeBytes": 24}, self.teacher, 415)
        self.request("POST", path, {"fileName": "v.mp4", "sizeBytes": 100000001}, self.teacher, 413)
        before = sorted(str(file) for file in (self.data / "uploads").glob("*"))
        session = self.prepare()
        fields = session["upload"]["fields"]
        self.assertNotIn("api_secret", fields)
        self.assertEqual(fields["type"], "authenticated")
        self.assertEqual(
            fields["signature"],
            signature(
                {key: value for key, value in fields.items() if key not in ("api_key", "signature")}
            ),
        )
        public_id = fields["public_id"]
        CloudinaryMock.assets[public_id] = {
            "public_id": public_id,
            "resource_type": "video",
            "type": "authenticated",
            "format": "mp4",
            "bytes": 25,
            "version": 12345,
            "width": 1280,
            "height": 720,
            "duration": 119.08,
            "content": b"test",
        }
        body = {
            "uploadToken": session["uploadToken"],
            "title": "Cloud lecture",
            "orderIndex": 30,
            "practiceInstructions": "Draw a house",
        }
        self.request(
            "POST", path + "/complete", {**body, "uploadToken": "tampered"}, self.teacher, 400
        )
        self.request("POST", path + "/complete", body, self.teacher, 400)
        CloudinaryMock.assets[public_id]["bytes"] = 24
        duration = CloudinaryMock.assets[public_id].pop("duration")
        self.request("POST", path + "/complete", body, self.teacher, 502)
        CloudinaryMock.assets[public_id]["duration"] = duration
        lesson = self.request("POST", path + "/complete", body, self.teacher)
        self.assertIsNone(lesson["videoAssetId"])
        self.assertEqual(
            lesson["videoUrl"],
            f"https://res.cloudinary.com/artkids-test/video/authenticated/v12345/{public_id}.mp4",
        )
        again = self.request("POST", path + "/complete", body, self.teacher)
        self.assertEqual(again["id"], lesson["id"])
        details = self.request("GET", "/lessons/" + lesson["id"], token=self.teacher)
        self.assertNotEqual(details["videoUrl"], lesson["videoUrl"])
        query = dict(urllib.parse.parse_qsl(urllib.parse.urlparse(details["videoUrl"]).query))
        self.assertGreater(int(query["expires_at"]), time.time())
        self.assertEqual(
            query["signature"],
            signature(
                {key: value for key, value in query.items() if key not in ("api_key", "signature")}
            ),
        )
        self.request("GET", "/lessons/" + lesson["id"] + "?childId=child-1", token=self.parent)
        self.request(
            "GET", "/lessons/" + lesson["id"] + "?childId=child-1", token=self.other, expected=404
        )
        self.request(
            "POST",
            "/courses/course_basics/lessons",
            {"title": "Copied private video", "orderIndex": 31, "videoUrl": lesson["videoUrl"]},
            self.teacher,
            400,
        )
        old = self.request("GET", "/lessons/lesson_basics_1", token=self.teacher)
        replacement = self.prepare(lessonId="lesson_basics_1")
        replacement_id = replacement["upload"]["fields"]["public_id"]
        CloudinaryMock.assets[replacement_id] = {
            **CloudinaryMock.assets[public_id],
            "public_id": replacement_id,
        }
        updated = self.request(
            "POST",
            path + "/complete",
            {
                "uploadToken": replacement["uploadToken"],
                "title": old["title"],
                "orderIndex": old["orderIndex"],
                "practiceInstructions": old["practiceInstructions"],
            },
            self.teacher,
        )
        self.assertEqual(updated["id"], old["id"])
        self.assertIsNone(updated["videoAssetId"])
        self.assertEqual(before, sorted(str(file) for file in (self.data / "uploads").glob("*")))

    def test_15_browser_chunk_upload_and_playback(self):
        from playwright.sync_api import expect, sync_playwright
        from frontend_smoke import fill_field, open_page

        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(channel="msedge", headless=True)
            context = browser.new_context()

            def forward(route):
                suffix = route.request.url.split("/api/v1", 1)[1]
                route.fulfill(response=route.fetch(url=self.base + "/api/v1" + suffix))

            context.route("http://localhost:5080/api/v1/**", forward)

            class ContextPages:
                def new_page(self, viewport):
                    result = context.new_page()
                    result.set_viewport_size(viewport)
                    return result

            page = open_page(ContextPages(), "instructor")
            edit = page.get_by_role("button", name="Chỉnh sửa khóa học", exact=True).first
            edit.wait_for(state="visible")
            bounds = edit.bounding_box()
            page.mouse.click(100, bounds["y"] + bounds["height"] / 2)
            page.get_by_role("button", name="Tải video & thêm bài học", exact=True).click()
            fill_field(page, "Tên bài giảng", "Cloud browser upload")
            fill_field(page, "Thứ tự bài giảng", "40")
            fill_field(page, "Hướng dẫn thực hành", "Draw your favorite shapes")
            video = (
                Path(__file__).parents[1] / "seed-media/videos/basics_01.mp4"
            ).read_bytes() + b"\0" * (6 * 1024 * 1024)
            with page.expect_file_chooser() as chooser:
                page.get_by_role("button", name="Chọn video MP4", exact=True).click()
            chooser.value.set_files(
                {"name": "lecture.mp4", "mimeType": "video/mp4", "buffer": video}
            )
            try:
                with page.expect_response(
                    lambda response: response.request.method == "POST"
                    and response.url.endswith("/lessons/video-upload/complete"),
                    timeout=45000,
                ) as saved:
                    page.get_by_role("button", name="Tải video & lưu bài giảng", exact=True).click()
            except Exception:
                page.screenshot(path="backend/tests/artifacts/cloudinary-upload-error.png")
                print(
                    page.locator("body").inner_text().encode("ascii", "backslashreplace").decode(),
                    flush=True,
                )
                print(
                    [
                        (method, path.split("?", 1)[0])
                        for method, path, _ in CloudinaryMock.requests
                    ],
                    flush=True,
                )
                raise
            self.assertEqual(saved.value.status, 200, saved.value.text())
            lesson = saved.value.json()
            self.assertIsNone(lesson["videoAssetId"])
            self.assertTrue(lesson["videoUrl"].startswith("https://res.cloudinary.com/"))
            expect(
                page.get_by_role("button", name="Xem video bài giảng", exact=True)
            ).to_be_visible()
            page.get_by_role("button", name="Xem video bài giảng", exact=True).click()
            page.get_by_text("Bài 40: Cloud browser upload", exact=True).click()
            page.wait_for_function(
                "() => {const v=document.querySelector('video');return v && v.readyState>=2 && v.duration>100;}",
                timeout=30000,
            )
            page.get_by_role("button", name="Phát / Tạm dừng", exact=True).last.click()
            page.wait_for_function("() => document.querySelector('video').currentTime>1")
            Path("backend/tests/artifacts").mkdir(exist_ok=True)
            page.screenshot(path="backend/tests/artifacts/cloudinary-upload-playback.png")
            uploads = [
                headers
                for method, path, headers in CloudinaryMock.requests
                if method == "POST" and path.endswith("/video/upload")
            ]
            self.assertGreaterEqual(len(uploads), 2)
            self.assertTrue(all("Authorization" not in headers for headers in uploads))
            self.assertTrue(any("Content-Range" in headers for headers in uploads))
            browser.close()

    def test_16_migrate_existing_video_preserves_lesson_and_progress(self):
        course = self.request(
            "POST",
            "/courses",
            {
                "title": "Video migration tool",
                "description": "Migration test",
                "ageRange": "5-10",
                "priceVnd": 0,
                "isPublished": True,
            },
            self.teacher,
        )
        video = (Path(__file__).parents[1] / "seed-media/videos/basics_01.mp4").read_bytes()
        asset = self.upload(data=video, kind="video", child=None, token=self.teacher)
        lesson = self.request(
            "POST",
            f"/courses/{course['id']}/lessons",
            {
                "title": "Existing local video",
                "orderIndex": 1,
                "videoAssetId": asset["id"],
                "practiceInstructions": "Practice drawing",
            },
            self.teacher,
        )
        self.request(
            "POST", "/enrollments", {"courseId": course["id"], "childId": "child-1"}, self.parent
        )
        progress = self.request(
            "POST",
            "/courses/progress",
            {
                "childId": "child-1",
                "lessonId": lesson["id"],
                "status": "completed",
                "learningSeconds": 10,
            },
            self.parent,
        )
        command = [
            sys.executable,
            str(Path(__file__).parents[1] / "scripts/migrate_videos_to_cloudinary.py"),
            "--base-url",
            self.base + "/api/v1",
            "--course-id",
            course["id"],
            "--report",
            str(self.data / "migration-report.json"),
        ]
        subprocess.run(command, check=True, capture_output=True)
        after = self.request("GET", "/lessons/" + lesson["id"], token=self.teacher)
        self.assertIsNone(after["videoAssetId"])
        self.assertTrue(
            after["videoUrl"].startswith(self.cloud_root + "/v1_1/artkids-test/video/download?")
        )
        rows = self.request("GET", f"/courses/{course['id']}/lessons", token=self.teacher)
        self.assertEqual([row["id"] for row in rows], [lesson["id"]])
        self.assertTrue((self.data / "migration-report.json").exists())
        assets_before = len(CloudinaryMock.assets)
        subprocess.run(command, check=True, capture_output=True)
        self.assertEqual(len(CloudinaryMock.assets), assets_before)
        actual = self.request(
            "POST",
            "/courses/progress",
            {
                "childId": "child-1",
                "lessonId": lesson["id"],
                "status": "completed",
                "learningSeconds": 0,
            },
            self.parent,
        )
        self.assertEqual(actual["id"], progress["id"])
        self.assertEqual(actual["learningSeconds"], 10)


if __name__ == "__main__":
    unittest.main(defaultTest="CloudinaryTests", verbosity=2)
