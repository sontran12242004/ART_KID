import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_store.dart';

class ApiInterceptor extends Interceptor {
  ApiInterceptor(this.ref, this.dio);
  final Ref ref;
  final Dio dio;
  Future<void>? _refreshing;
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(sessionStoreProvider).accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  Future<void> _refresh() async {
    final previous = ref.read(sessionStoreProvider);
    if (previous.refreshToken == null) throw StateError('Phiên đã hết hạn.');
    final client = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    try {
      final response = await client.post(
        '/auth/refresh',
        data: {'refreshToken': previous.refreshToken},
      );
      if (ref.read(sessionStoreProvider).refreshToken !=
          previous.refreshToken) {
        throw StateError('Phiên đăng nhập đã thay đổi.');
      }
      ref
          .read(sessionStoreProvider.notifier)
          .accept(Map<String, dynamic>.from(response.data));
    } finally {
      client.close();
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final request = error.requestOptions;
    final session = ref.read(sessionStoreProvider);
    if (error.response?.statusCode == 401 &&
        session.refreshToken != null &&
        request.extra['retried'] != true &&
        ![
          '/auth/login',
          '/auth/register',
          '/auth/refresh',
        ].contains(request.path)) {
      try {
        final pending = _refreshing ??= _refresh();
        try {
          await pending;
        } finally {
          if (identical(_refreshing, pending)) _refreshing = null;
        }
        request.extra['retried'] = true;
        request.headers['Authorization'] =
            'Bearer ${ref.read(sessionStoreProvider).accessToken}';
        if (request.data is FormData) {
          request.data = (request.data as FormData).clone();
        }
        handler.resolve(await dio.fetch<dynamic>(request));
        return;
      } catch (_) {
        if (ref.read(sessionStoreProvider).userId == session.userId) {
          ref.read(sessionStoreProvider.notifier).clear();
        }
      }
    }
    final body = error.response?.data;
    String message;
    if (body is Map && body['errors'] is Map) {
      message = (body['errors'] as Map).values
          .expand((v) => v is List ? v : [v])
          .join('\n');
    } else if (body is Map && body['title'] is String) {
      message = body['title'] as String;
    } else {
      message = error.response == null
          ? 'Không kết nối được máy chủ. Vui lòng thử lại.'
          : 'Yêu cầu không thành công (${error.response?.statusCode}).';
    }
    handler.next(error.copyWith(message: message));
  }
}

String apiError(Object error) => error is DioException
    ? error.message ?? 'Không thể thực hiện yêu cầu.'
    : error.toString().replaceFirst('Exception: ', '');
