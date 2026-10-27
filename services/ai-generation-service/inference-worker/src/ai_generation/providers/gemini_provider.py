import os
import json
import base64
from typing import Dict, Any, Optional
import httpx


class GeminiAnimalClassifier:
    """
    Sử dụng Google Gemini 1.5 Flash Vision để phân tích và nhận diện loài vật
    từ tranh vẽ của trẻ em, gợi ý chuyển động và lời khen ngợi.
    """

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        self.model = os.getenv("GEMINI_MODEL", "gemini-3.6-flash")
        self.endpoint = (
            f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"
            f"?key={self.api_key}"
        )

    async def analyze_drawing(
        self, image_bytes: bytes, mime_type: str = "image/png"
    ) -> Dict[str, Any]:
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not set.")

        base64_image = base64.b64encode(image_bytes).decode("utf-8")

        system_instruction = (
            "Bạn là chuyên gia thẩm định và phân tích tranh vẽ trẻ em của ArtKids. "
            "Nhìn vào bức tranh và trả về JSON thuần túy (không markdown) với cấu trúc: "
            '{"animalType": "tên loài (vd: lion, dog, cat, rabbit)", '
            '"displayName": "Tên tiếng Việt vui nhộn cho bé", '
            '"cheeringMessage": "Lời khen ngợi truyền cảm hứng cho bé (1-2 câu)", '
            '"suggestedAnimationId": "id hoạt ảnh 2D/3D khớp với tranh"}'
        )

        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": system_instruction},
                        {"inline_data": {"mime_type": mime_type, "data": base64_image}},
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.3,
                "maxOutputTokens": 500,
            },
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                self.endpoint, headers={"Content-Type": "application/json"}, json=payload
            )
            response.raise_for_status()
            data = response.json()

            candidates = data.get("candidates", [])
            if candidates:
                text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                try:
                    # Parse JSON từ output
                    return json.loads(text.strip("```json\n").strip("```"))
                except json.JSONDecodeError:
                    return {
                        "animalType": "creature",
                        "displayName": "Con Vật Sáng Tạo",
                        "cheeringMessage": text,
                        "suggestedAnimationId": "default_anim",
                    }

            raise RuntimeError("Gemini API did not return candidates.")
