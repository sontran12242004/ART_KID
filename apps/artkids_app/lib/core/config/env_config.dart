import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Đọc biến môi trường từ env/{flavor}.env
class EnvConfig {
  EnvConfig._();

  static String _get(String key, [String defaultValue = '']) {
    if (!dotenv.isInitialized) return defaultValue;
    return dotenv.env[key] ?? defaultValue;
  }

  static String get apiBaseUrl =>
      const String.fromEnvironment('API_BASE_URL').isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : _get(
          'API_BASE_URL',
          kIsWeb
              ? 'http://localhost:5080/api/v1'
              : 'http://10.0.2.2:5080/api/v1',
        );

  static String get cdnBaseUrl =>
      _get('CDN_BASE_URL', 'http://10.0.2.2:9000/artkids-media');

  static String get flavor => _get('FLAVOR', 'dev');

  static bool get enableMockOrders =>
      _get('ENABLE_MOCK_ORDERS', 'false') !=
      'false'; // Default to true if not explicitly false

  static bool get enableMockShop =>
      _get('ENABLE_MOCK_SHOP', 'false') !=
      'false'; // Default to true if not explicitly false

  static bool get enableMockCoursesProgress =>
      _get('ENABLE_MOCK_COURSES_PROGRESS', 'false') !=
      'false'; // Bật mock tiến độ theo khóa học

  static void validate() {
    assert(apiBaseUrl.isNotEmpty, 'API_BASE_URL is required');
  }
}
