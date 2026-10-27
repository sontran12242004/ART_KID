"""Verify generated files, seeded lessons and real Flutter web video playback."""

import hashlib
import json
import re
import subprocess
import urllib.request
from pathlib import Path

import imageio_ffmpeg
from playwright.sync_api import sync_playwright

from frontend_smoke import go, log, open_page

ROOT = Path(__file__).resolve().parents[1]
BASE = "http://localhost:5080/api/v1"


def api(path, token=None, data=None, headers=None):
    request_headers = {"Content-Type": "application/json", **(headers or {})}
    if token:
        request_headers["Authorization"] = "Bearer " + token
    return urllib.request.urlopen(
        urllib.request.Request(
            BASE + path,
            data=json.dumps(data).encode() if data is not None else None,
            headers=request_headers,
        ),
        timeout=60,
    )


def main():
    (ROOT / "tests/artifacts").mkdir(parents=True, exist_ok=True)
    catalog = json.loads((ROOT / "seed-media/catalog.json").read_text(encoding="utf-8"))
    assert len(catalog) == 10
    with api(
        "/auth/login",
        data={"email": "instructor.test@example.invalid", "password": "ArtKids-Test-2026!"},
    ) as response:
        token = json.load(response)["accessToken"]
    seeded = []
    for course in ("course_basics", "course_animals"):
        with api(f"/courses/{course}/lessons") as response:
            rows = json.load(response)
        assert len(rows) == 5 and all(row["hasVideo"] for row in rows)
        assert [row["orderIndex"] for row in rows] == list(range(1, 6))
        seeded.extend(rows)
    for item in catalog:
        file = ROOT / "seed-media" / item["file"]
        assert hashlib.sha256(file.read_bytes()).hexdigest() == item["sha256"]
        decoded = subprocess.run(
            [
                imageio_ffmpeg.get_ffmpeg_exe(),
                "-hide_banner",
                "-i",
                str(file),
                "-af",
                "volumedetect",
                "-f",
                "null",
                "-",
            ],
            capture_output=True,
            check=True,
        ).stderr.decode(errors="replace")
        assert "1280x720" in decoded and "Audio: aac" in decoded
        duration = re.search(r"Duration: (\d+):(\d+):([\d.]+)", decoded)
        assert duration
        seconds = int(duration[1]) * 3600 + int(duration[2]) * 60 + float(duration[3])
        assert abs(seconds - item["durationSeconds"]) < 0.3
        volume = re.search(r"mean_volume: (-?[\d.]+) dB", decoded)
        assert volume and -55 < float(volume[1]) < 0, decoded[-1500:]
        row = next(
            row
            for row in seeded
            if row["courseId"] == item["courseId"] and row["orderIndex"] == item["orderIndex"]
        )
        assert row["title"] == item["title"]
        with api("/lessons/" + row["id"], token) as response:
            detail = json.load(response)
        download = (
            api("/media/" + detail["videoAssetId"], token, headers={"Range": "bytes=0-1023"})
            if detail.get("videoAssetId")
            else urllib.request.urlopen(
                urllib.request.Request(detail["videoUrl"], headers={"Range": "bytes=0-1023"}),
                timeout=60,
            )
        )
        with download as response:
            assert response.status == 206
            assert response.headers["Content-Type"].startswith("video/mp4")
            assert b"ftyp" in response.read()[:16]
        log(f"PASS decoded narrated video, lesson link and protected range download: {item['key']}")
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="msedge", headless=True)
        for course in ("course_basics", "course_animals"):
            page = open_page(browser, "parent")
            lesson = next(row for row in seeded if row["courseId"] == course)
            expected_duration = next(
                item["durationSeconds"]
                for item in catalog
                if item["courseId"] == course and item["orderIndex"] == lesson["orderIndex"]
            )
            go(page, "/kid/lesson/" + lesson["id"])
            page.wait_for_function(
                "expected => {const v=document.querySelector('video');return v && v.readyState >= 2 && Math.abs(v.duration-expected)<.2;}",
                arg=expected_duration,
                timeout=45000,
            )
            page.get_by_role("button", name="Phát / Tạm dừng", exact=True).last.click()
            page.wait_for_function("() => document.querySelector('video').currentTime > 1")
            result = page.locator("video").evaluate(
                "v=>({duration:v.duration,currentTime:v.currentTime,width:v.videoWidth,height:v.videoHeight,error:v.error})"
            )
            assert result["width"] == 1280 and result["height"] == 720 and result["error"] is None
            page.screenshot(path=str(ROOT / "tests/artifacts" / f"{course}-video-playback.png"))
            log(f"PASS parent Flutter player: {course}, {result}")
            page.close()
        browser.close()


if __name__ == "__main__":
    main()
