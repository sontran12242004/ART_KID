import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';

class GeminiAnalysisResult {
  const GeminiAnalysisResult({
    required this.animalType,
    required this.displayName,
    required this.cheeringMessage,
    required this.suggestedAnimationId,
    required this.rawResponse,
    this.funFact = '',
  });

  final String animalType;
  final String displayName;
  final String cheeringMessage;
  final String suggestedAnimationId;
  final String rawResponse;
  final String funFact;

  factory GeminiAnalysisResult.fromGeminiText(String text) {
    try {
      var cleaned = text.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        try {
          final parsed = jsonDecode(jsonStr);
          return GeminiAnalysisResult(
            animalType: (parsed['animalType'] ?? 'unknown').toString().trim(),
            displayName: (parsed['displayName'] ?? 'Bạn Nhỏ Đáng Yêu')
                .toString()
                .replaceAll('"', '')
                .trim(),
            cheeringMessage: (parsed['cheeringMessage'] ?? 'Bức vẽ của bé thật tuyệt vời!')
                .toString()
                .replaceAll('"', '')
                .trim(),
            suggestedAnimationId: (parsed['suggestedAnimationId'] ?? 'lion_dance').toString().trim(),
            funFact: (parsed['funFact'] ?? '').toString().replaceAll('"', '').trim(),
            rawResponse: text,
          );
        } catch (_) {
          // Fallback parsing bằng Regex nếu jsonDecode gặp lỗi cú pháp
          final animalMatch = RegExp(r'"animalType"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
          final displayMatch = RegExp(r'"displayName"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
          final cheeringMatch = RegExp(r'"cheeringMessage"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
          final funFactMatch = RegExp(r'"funFact"\s*:\s*"([^"]+)"').firstMatch(jsonStr);

          if (displayMatch != null || animalMatch != null) {
            return GeminiAnalysisResult(
              animalType: animalMatch?.group(1)?.trim() ?? 'creature',
              displayName: displayMatch?.group(1)?.replaceAll('"', '').trim() ?? 'Bạn Nhỏ Đáng Yêu',
              cheeringMessage: cheeringMatch?.group(1)?.replaceAll('"', '').trim() ??
                  'Bức vẽ của bé thật đáng yêu và sáng tạo!',
              suggestedAnimationId: 'creature_dance',
              funFact: funFactMatch?.group(1)?.replaceAll('"', '').trim() ?? '',
              rawResponse: text,
            );
          }
        }
      }
    } catch (_) {}

    var fallbackMsg = text
        .replaceAll('"', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim();
    if (fallbackMsg.contains(':')) {
      final parts = fallbackMsg.split(':');
      if (parts.length > 1) fallbackMsg = parts.last.trim();
    }
    if (fallbackMsg.isEmpty) {
      fallbackMsg = 'Bức vẽ của bé chứa đầy sự sáng tạo! 🎉';
    }

    return GeminiAnalysisResult(
      animalType: 'creature',
      displayName: 'Con Vật Bí Ẩn',
      cheeringMessage: fallbackMsg,
      suggestedAnimationId: 'creature_idle',
      funFact: '',
      rawResponse: text,
    );
  }
}

class GeminiService {
  GeminiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Phân tích ảnh vẽ của bé bằng Gemini Vision API
  Future<GeminiAnalysisResult> analyzeDrawing({
    required List<int> imageBytes,
    String mimeType = 'image/png',
  }) async {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY chưa được cấu hình trong env.');
    }

    final base64Image = base64Encode(imageBytes);

    const systemPrompt = '''
Bạn là trợ lý AI thông minh, thân thiện của ứng dụng học vẽ ArtKids dành cho trẻ em 4-12 tuổi.
Hãy quan sát bức vẽ của trẻ và nhận diện con vật trong tranh.
Trả về định dạng JSON duy nhất với các trường:
{
  "animalType": "tên loài vật (tiếng Anh viết thường, vd: lion, cat, dog, bird, elephant, fish, rabbit, horse, dolphin, butterfly, dinosaur, penguin, owl, fox, bear, whale, tiger, giraffe, monkey, turtle)",
  "displayName": "Tên tiếng Việt ngộ nghĩnh (vd: Chú Sư Tử Dũng Cảm, Bé Mèo Tinh Nghịch)",
  "cheeringMessage": "Lời khen ngợi và động viên ngắn gọn (1-2 câu, lời văn ấm áp, vui vẻ cho trẻ em)",
  "suggestedAnimationId": "tên hoạt ảnh gợi ý (vd: lion_dance, cat_play, bird_fly)",
  "funFact": "Một sự thật thú vị về con vật này (1 câu ngắn, dễ hiểu cho trẻ em, vd: Sư tử có thể ngủ tới 20 giờ mỗi ngày!)"
}
''';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": systemPrompt},
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "maxOutputTokens": 400,
      }
    };

    // gemini-3.6-flash là model đã kích hoạt thành công trên tài khoản của bạn
    final models = [
      'gemini-3.6-flash',
      'gemini-1.5-flash',
      'gemini-2.0-flash-exp',
    ];

    DioException? lastException;

    for (final model in models) {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
      try {
        final response = await _dio.post(
          url,
          data: body,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          final candidates = response.data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final text =
                candidates[0]['content']['parts'][0]['text'] as String? ?? '';
            return GeminiAnalysisResult.fromGeminiText(text);
          }
        }
      } on DioException catch (e) {
        lastException = e;
        // Nếu lỗi 404 (model không tìm thấy trên tier này), tiếp tục thử model tiếp theo
        if (e.response?.statusCode == 404) {
          continue;
        }
        rethrow;
      }
    }

    if (lastException != null) {
      throw lastException;
    }

    throw Exception('Không nhận được phản hồi hợp lệ từ Gemini API');
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
