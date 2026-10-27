"""Move existing lesson video references to Cloudinary through the verified API flow.

Requires configured Cloudinary credentials in the running backend. Keeps lesson IDs,
progress and original local files; skips lessons already using a URL.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default="http://localhost:5080/api/v1")
    parser.add_argument("--email", default="instructor.test@example.invalid")
    parser.add_argument(
        "--password", default=os.environ.get("ARTKID_SEED_PASSWORD", "ArtKids-Test-2026!")
    )
    parser.add_argument("--course-id", action="append")
    parser.add_argument(
        "--report",
        type=Path,
        default=Path(__file__).resolve().parents[1] / ".test-data/cloudinary-video-migration.json",
    )
    args = parser.parse_args()
    token = None

    def api(path, data=None):
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = "Bearer " + token
        request = urllib.request.Request(
            args.base_url.rstrip("/") + path,
            data=json.dumps(data).encode() if data is not None else None,
            headers=headers,
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            try:
                detail = json.loads(error.read()).get("title", "Request failed")
            except (ValueError, AttributeError):
                detail = "Request failed"
            raise RuntimeError(f"ART KID API {path} failed (HTTP {error.code}): {detail}") from None

    auth = api("/auth/login", {"email": args.email, "password": args.password})
    token = auth["accessToken"]
    status = api("/media/video-storage")
    if not status["isConfigured"]:
        raise RuntimeError("Configure Cloudinary on the backend and restart the API first.")
    courses = api("/courses?pageSize=100")["items"]
    owned = [
        course
        for course in courses
        if auth["user"]["role"] == "admin" or course["instructorId"] == auth["user"]["id"]
    ]
    if args.course_id:
        owned = [course for course in owned if course["id"] in args.course_id]
        if {course["id"] for course in owned} != set(args.course_id):
            raise ValueError("One or more selected courses are unavailable to this instructor.")
    report = []
    for course in owned:
        course_id = course["id"]
        for summary in api(f"/courses/{course_id}/lessons"):
            lesson = api("/lessons/" + summary["id"])
            if not lesson.get("videoAssetId"):
                print(f"Skipped URL/no-video lesson: {lesson['id']}", flush=True)
                continue
            request = urllib.request.Request(
                args.base_url.rstrip("/") + "/media/" + lesson["videoAssetId"],
                headers={"Authorization": "Bearer " + token},
            )
            with urllib.request.urlopen(request, timeout=120) as response:
                video = response.read(status["maxUploadBytes"] + 1)
            if len(video) > status["maxUploadBytes"]:
                raise ValueError(f"Video exceeds configured cloud size limit: {lesson['id']}")
            session = api(
                f"/courses/{course_id}/lessons/video-upload",
                {
                    "fileName": lesson["id"] + ".mp4",
                    "sizeBytes": len(video),
                    "lessonId": lesson["id"],
                },
            )
            chunk_size = session["chunkBytes"]
            upload_id = uuid.uuid4().hex
            for start in range(0, len(video), chunk_size):
                chunk = video[start : start + chunk_size]
                boundary = "ArtKidCloud" + uuid.uuid4().hex
                parts = [
                    f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode()
                    for name, value in session["upload"]["fields"].items()
                ]
                parts.append(
                    f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="lecture.mp4"\r\nContent-Type: video/mp4\r\n\r\n'.encode()
                    + chunk
                    + b"\r\n"
                )
                parts.append(f"--{boundary}--\r\n".encode())
                headers = {"Content-Type": f"multipart/form-data; boundary={boundary}"}
                if len(video) > chunk_size:
                    headers.update(
                        {
                            "Content-Range": f"bytes {start}-{start + len(chunk) - 1}/{len(video)}",
                            "X-Unique-Upload-Id": upload_id,
                        }
                    )
                try:
                    with urllib.request.urlopen(
                        urllib.request.Request(
                            session["upload"]["uploadUrl"], data=b"".join(parts), headers=headers
                        ),
                        timeout=180,
                    ) as response:
                        uploaded = json.load(response)
                except urllib.error.HTTPError as error:
                    try:
                        message = (
                            json.loads(error.read())
                            .get("error", {})
                            .get("message", "Upload rejected")
                        )
                    except (ValueError, AttributeError):
                        message = "Upload rejected"
                    for name in ("api_key", "signature"):
                        value = session["upload"]["fields"].get(name)
                        if value:
                            message = message.replace(value, "[redacted]")
                    hint = (
                        " Run .\\backend\\scripts\\configure-cloudinary.ps1 and re-enter credentials."
                        if error.code == 401
                        else ""
                    )
                    raise RuntimeError(
                        f"Cloudinary upload failed (HTTP {error.code}): {message[:400]}.{hint}"
                    ) from None
                if (
                    start + len(chunk) == len(video)
                    and uploaded.get("public_id") != session["upload"]["fields"]["public_id"]
                ):
                    raise ValueError("Cloudinary did not confirm the expected uploaded video.")
            saved = api(
                f"/courses/{course_id}/lessons/video-upload/complete",
                {
                    "uploadToken": session["uploadToken"],
                    "title": lesson["title"],
                    "orderIndex": lesson["orderIndex"],
                    "practiceInstructions": lesson["practiceInstructions"],
                },
            )
            assert (
                saved["id"] == lesson["id"] and saved["videoAssetId"] is None and saved["videoUrl"]
            )
            report.append(
                {
                    "lessonId": saved["id"],
                    "previousVideoAssetId": lesson["videoAssetId"],
                    "videoUrl": saved["videoUrl"],
                }
            )
            output = args.report
            output.parent.mkdir(exist_ok=True)
            output.write_text(json.dumps(report, indent=2), encoding="utf-8")
            print(f"Moved to Cloudinary: {saved['id']}", flush=True)
    print(f"Completed: {len(report)} videos migrated. Original files retained for backup.")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
