"""Render original narrated drawing lessons. Run from the repository root."""

import asyncio
import argparse
import hashlib
import json
import subprocess
import wave
from functools import lru_cache
from pathlib import Path

import edge_tts
import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFont

from lesson_video_content import lessons

ROOT = Path(__file__).resolve().parents[1] / "seed-media"
CACHE = ROOT / ".cache"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
FPS = 12
WIDTH, HEIGHT = 1280, 720


@lru_cache(maxsize=32)
def font(size, bold=False):
    return ImageFont.truetype(
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf", size
    )


def wrapped(draw, text, xy, width, size=24, fill="#273444", bold=False):
    face = font(size, bold)
    x, y = xy
    line = ""
    for word in text.split():
        candidate = f"{line} {word}".strip()
        if draw.textlength(candidate, font=face) > width and line:
            draw.text((x, y), line, font=face, fill=fill)
            y += size + 9
            line = word
        else:
            line = candidate
    draw.text((x, y), line, font=face, fill=fill)
    return y + size + 9


async def narration(text, semaphore):
    key = hashlib.sha256(text.encode()).hexdigest()[:20]
    mp3 = CACHE / f"{key}.mp3"
    wav = CACHE / f"{key}.wav"
    async with semaphore:
        if not wav.exists():
            for attempt in range(4):
                try:
                    await edge_tts.Communicate(text, "vi-VN-HoaiMyNeural", rate="-10%").save(
                        str(mp3)
                    )
                    subprocess.run(
                        [
                            FFMPEG,
                            "-y",
                            "-loglevel",
                            "error",
                            "-i",
                            str(mp3),
                            "-ar",
                            "24000",
                            "-ac",
                            "1",
                            str(wav),
                        ],
                        check=True,
                    )
                    break
                except Exception:
                    if attempt == 3:
                        raise
                    await asyncio.sleep(2 + attempt)
    with wave.open(str(wav)) as audio:
        return audio.readframes(audio.getnframes()), audio.getnframes() / 24000


def artwork(draw, strokes, reveal=1, colored=False):
    total = sum(max(1, len(s.points)) for s in strokes)
    remaining = total * reveal
    visible = []
    for stroke in strokes:
        count = min(len(stroke.points), max(0, int(remaining)))
        remaining -= max(1, len(stroke.points))
        if count:
            visible.append((stroke, count))
    for stroke, count in visible:
        points = [(80 + x * 1.18, 175 + y * 1.12) for x, y in stroke.points]
        if stroke.fill and count == len(points) and (colored or stroke.fill_early):
            draw.polygon(points, fill=stroke.fill)
    for stroke, count in visible:
        points = [(80 + x * 1.18, 175 + y * 1.12) for x, y in stroke.points[:count]]
        if stroke.text:
            draw.text(points[0], stroke.text, font=font(19), fill=stroke.color)
        elif len(points) > 1:
            draw.line(points, fill=stroke.color, width=stroke.width, joint="curve")
    if reveal < 1 and visible:
        stroke, count = visible[-1]
        x, y = stroke.points[count - 1]
        x, y = 80 + x * 1.18, 175 + y * 1.12
        draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill="#f27059")


def frame(lesson, index, progress):
    image = Image.new("RGB", (WIDTH, HEIGHT), "#fff9ef")
    draw = ImageDraw.Draw(image)
    draw.text((32, 22), "ART KID • HỌC VẼ TỪNG BƯỚC", font=font(22, True), fill="#62558d")
    draw.text((32, 67), lesson.title, font=font(36, True), fill="#273444")
    draw.text((900, 30), lesson.course_title, font=font(22), fill="#62558d")
    draw.rounded_rectangle((32, 140, 842, 606), radius=22, fill="white", outline="#e8dfd3", width=2)
    draw.rounded_rectangle((864, 140, 1248, 606), radius=22, fill="#eee8fa")
    all_strokes = [stroke for step in lesson.steps for stroke in step.strokes]
    if index == 0:
        heading, detail = "Cùng chuẩn bị nhé!", lesson.goal
        artwork(draw, all_strokes, colored=True)
        caption = "Chuẩn bị giấy, bút chì, tẩy và màu. Bé có thể tạm dừng video để thực hành."
    elif index == len(lesson.steps) + 1:
        heading, detail = "Đến lượt bé!", lesson.practice
        artwork(draw, all_strokes, colored=True)
        caption = "Hoàn thành tranh, lưu bài vẽ và nhờ người lớn hỗ trợ nộp bài trong ứng dụng."
    else:
        step = lesson.steps[index - 1]
        heading, detail = f"Bước {index}: {step.title}", step.speech
        previous = [s for item in lesson.steps[: index - 1] for s in item.strokes]
        current = step.strokes
        combined = previous + current
        base = sum(len(s.points) for s in previous)
        total = max(1, sum(len(s.points) for s in combined))
        reveal = (
            base + sum(len(s.points) for s in current) * min(1, max(0, (progress - 0.08) / 0.60))
        ) / total
        artwork(draw, combined, reveal, colored=index == len(lesson.steps))
        caption = "Quan sát nét bút • Vẽ chậm từng nét • Tạm dừng để vẽ theo"
    y = wrapped(draw, heading, (888, 165), 330, 27, bold=True)
    wrapped(draw, detail, (888, y + 14), 330, 21)
    draw.rounded_rectangle((32, 624, 1248, 696), radius=16, fill="#273444")
    wrapped(draw, caption, (52, 640), 1170, 21, "white")
    draw.rectangle((32, 118, 1248, 123), fill="#e8dfd3")
    draw.rectangle(
        (32, 118, 32 + 1216 * (index + progress) / (len(lesson.steps) + 2), 123), fill="#35b7a5"
    )
    return image


def render(lesson, voices):
    output = ROOT / "videos" / f"{lesson.key}.mp4"
    durations = [
        max(9, duration + (3 if i in (0, len(voices) - 1) else 5))
        for i, (_, duration) in enumerate(voices)
    ]
    audio_path = CACHE / f"{lesson.key}-combined.wav"
    with wave.open(str(audio_path), "wb") as audio:
        audio.setparams((1, 2, 24000, 0, "NONE", "not compressed"))
        for (pcm, _), duration in zip(voices, durations):
            length = round(duration * FPS) / FPS
            padding = max(0, round(length * 24000) - len(pcm) // 2 - 12000)
            audio.writeframes(b"\0\0" * 12000 + pcm + b"\0\0" * padding)
    command = [
        FFMPEG,
        "-y",
        "-loglevel",
        "error",
        "-f",
        "rawvideo",
        "-vcodec",
        "rawvideo",
        "-pix_fmt",
        "rgb24",
        "-s",
        f"{WIDTH}x{HEIGHT}",
        "-r",
        str(FPS),
        "-i",
        "-",
        "-i",
        str(audio_path),
        "-c:v",
        "libx264",
        "-preset",
        "veryfast",
        "-crf",
        "24",
        "-threads",
        "2",
        "-pix_fmt",
        "yuv420p",
        "-c:a",
        "aac",
        "-b:a",
        "96k",
        "-movflags",
        "+faststart",
        "-shortest",
        str(output),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    try:
        for index, duration in enumerate(durations):
            count = round(duration * FPS)
            for number in range(count):
                process.stdin.write(frame(lesson, index, number / count).tobytes())
        process.stdin.close()
        if process.wait() != 0:
            raise RuntimeError(f"FFmpeg failed: {lesson.key}")
    except BaseException:
        process.kill()
        raise
    frame(lesson, len(lesson.steps) + 1, 1).save(ROOT / "previews" / f"{lesson.key}.png")
    texts = (
        [f"Chào bé! {lesson.goal} Chuẩn bị giấy, bút chì và màu. Bé hãy tạm dừng khi cần nhé."]
        + [s.speech for s in lesson.steps]
        + [
            f"Bé đã hoàn thành bài học. {lesson.practice} Hãy lưu bài vẽ và nhờ người lớn hỗ trợ nộp bài trong ứng dụng nhé."
        ]
    )
    (ROOT / "transcripts" / f"{lesson.key}.txt").write_text("\n\n".join(texts), encoding="utf-8")
    return {
        "key": lesson.key,
        "courseId": lesson.course_id,
        "courseTitle": lesson.course_title,
        "title": lesson.title,
        "orderIndex": lesson.order,
        "practiceInstructions": lesson.practice,
        "file": f"videos/{lesson.key}.mp4",
        "durationSeconds": round(sum(round(d * FPS) / FPS for d in durations), 2),
        "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    }


async def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=[lesson.key for lesson in lessons()])
    args = parser.parse_args()
    for directory in (CACHE, ROOT / "videos", ROOT / "previews", ROOT / "transcripts"):
        directory.mkdir(parents=True, exist_ok=True)
    semaphore = asyncio.Semaphore(8)
    catalog_path = ROOT / "catalog.json"
    catalog = (
        json.loads(catalog_path.read_text(encoding="utf-8"))
        if args.only and catalog_path.exists()
        else []
    )
    content = [lesson for lesson in lessons() if not args.only or lesson.key == args.only]

    async def prepare(lesson):
        texts = (
            [f"Chào bé! {lesson.goal} Chuẩn bị giấy, bút chì và màu. Bé hãy tạm dừng khi cần nhé."]
            + [s.speech for s in lesson.steps]
            + [
                f"Bé đã hoàn thành bài học. {lesson.practice} Hãy lưu bài vẽ và nhờ người lớn hỗ trợ nộp bài trong ứng dụng nhé."
            ]
        )
        result = await asyncio.gather(*(narration(text, semaphore) for text in texts))
        print(f"Narration ready: {lesson.key}", flush=True)
        return result

    prepared = await asyncio.gather(*(prepare(lesson) for lesson in content))
    for lesson, voices in zip(content, prepared):
        print(f"Rendering: {lesson.key}", flush=True)
        generated = await asyncio.to_thread(render, lesson, voices)
        catalog = [item for item in catalog if item["key"] != lesson.key] + [generated]
        order = {item.key: index for index, item in enumerate(lessons())}
        catalog.sort(key=lambda item: order[item["key"]])
        catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Completed: {lesson.key} ({generated['durationSeconds']} seconds)", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
