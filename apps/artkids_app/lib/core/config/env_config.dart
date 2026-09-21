import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Đọc biến môi trường từ env/{flavor}.env
class EnvConfig {
  EnvConfig._();

  static String _get(String key, [String defaultValue = '']) {
    if (!dotenv.isInitialized) return defaultValue;
    return dotenv.env[key] ?? defaultValue;
  }

  static String get apiBaseUrl =>
      _get('API_BASE_URL', 'http://10.0.2.2:3000/api');

  static String get cdnBaseUrl =>
      _get('CDN_BASE_URL', 'http://10.0.2.2:9000/artkids-media');

  static String get flavor => _get('FLAVOR', 'dev');

  static bool get enableMockAi => _get('ENABLE_MOCK_AI') == 'true';

  static bool get enableMockOrders =>
      _get('ENABLE_MOCK_ORDERS', 'true') != 'false'; // Default to true if not explicitly false

  static bool get enableMockShop =>
      _get('ENABLE_MOCK_SHOP', 'true') != 'false'; // Default to true if not explicitly false

  static bool get enableMockCoursesProgress =>
      _get('ENABLE_MOCK_COURSES_PROGRESS', 'true') != 'false'; // Bật mock tiến độ theo khóa học

  static String get geminiApiKey => _get('GEMINI_API_KEY');

  static void validate() {
    assert(apiBaseUrl.isNotEmpty, 'API_BASE_URL is required');
  }
}
