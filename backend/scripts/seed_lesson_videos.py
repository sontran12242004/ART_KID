"""Upload generated lessons to a running local ART KID API, without duplicates."""

import argparse
import hashlib
import json
import os
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default="http://localhost:5080/api/v1")
    parser.add_argument("--email", default="instructor.test@example.invalid")
    parser.add_argument(
        "--password", default=os.environ.get("ARTKID_SEED_PASSWORD", "ArtKids-Test-2026!")
    )
    args = parser.parse_args()
    token = None

    def request(method, path, data=None, raw=None, content_type="application/json"):
        body = raw if raw is not None else json.dumps(data).encode() if data is not None else None
        headers = {"Content-Type": content_type}
        if token:
            headers["Authorization"] = "Bearer " + token
        with urllib.request.urlopen(
            urllib.request.Request(
                args.base_url.rstrip("/") + path, data=body, headers=headers, method=method
            ),
            timeout=120,
        ) as response:
            payload = response.read()
            return json.loads(payload) if payload else None

    auth = request("POST", "/auth/login", {"email": args.email, "password": args.password})
    token = auth["accessToken"]
    catalog = json.loads((ROOT / "seed-media/catalog.json").read_text(encoding="utf-8"))
    if len(catalog) != 10:
        raise ValueError("Generate all ten videos before seeding.")
    receipt_path = ROOT / ".test-data/video-seed-receipt.json"
    receipt_path.parent.mkdir(exist_ok=True)
    receipts = json.loads(receipt_path.read_text()) if receipt_path.exists() else {}
    for item in catalog:
        course = item["courseId"]
        existing = request("GET", f"/courses/{course}/lessons")
        lesson = next((row for row in existing if row["orderIndex"] == item["orderIndex"]), None)
        if lesson is None and item["key"] == "basics_03":
            lesson = next((row for row in existing if row["title"] == "Video test local"), None)
        key = args.base_url + "/" + item["key"]
        previous = receipts.get(key, {})
        detail = request("GET", "/lessons/" + lesson["id"]) if lesson else {}
        if detail.get("videoUrl") and not detail.get("videoAssetId"):
            print(f"Preserved external video: {item['key']}", flush=True)
            continue
        if (
            lesson
            and previous.get("sha256") == item["sha256"]
            and previous.get("lessonId") == lesson["id"]
            and detail.get("videoAssetId") == previous.get("assetId")
        ):
            print(f"Already seeded: {item['key']}", flush=True)
            continue
        video = (ROOT / "seed-media" / item["file"]).read_bytes()
        if hashlib.sha256(video).hexdigest() != item["sha256"]:
            raise ValueError(f"Video hash mismatch: {item['file']}")
        boundary = "ArtKid" + uuid.uuid4().hex
        body = (
            (
                f'--{boundary}\r\nContent-Disposition: form-data; name="kind"\r\n\r\nvideo\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{item["key"]}.mp4"\r\nContent-Type: video/mp4\r\n\r\n'
            ).encode()
            + video
            + f"\r\n--{boundary}--\r\n".encode()
        )
        asset = request(
            "POST",
            "/media/upload",
            raw=body,
            content_type=f"multipart/form-data; boundary={boundary}",
        )
        data = {
            "title": item["title"],
            "orderIndex": item["orderIndex"],
            "videoAssetId": asset["id"],
            "videoUrl": None,
            "practiceInstructions": item["practiceInstructions"],
        }
        path = f"/courses/{course}/lessons"
        saved = request(
            "PUT" if lesson else "POST", path + ("/" + lesson["id"] if lesson else ""), data
        )
        receipts[key] = {"sha256": item["sha256"], "lessonId": saved["id"], "assetId": asset["id"]}
        receipt_path.write_text(json.dumps(receipts, indent=2), encoding="utf-8")
        print(f"Seeded: {item['key']} -> {saved['id']}", flush=True)
    for course in {item["courseId"] for item in catalog}:
        rows = request("GET", f"/courses/{course}/lessons")
        for item in (entry for entry in catalog if entry["courseId"] == course):
            assert any(
                row["title"] == item["title"]
                and row["orderIndex"] == item["orderIndex"]
                and row.get("hasVideo")
                for row in rows
            ), item
        print(f"Verified five linked videos: {course}", flush=True)


if __name__ == "__main__":
    main()
