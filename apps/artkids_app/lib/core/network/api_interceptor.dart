import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interceptor: gắn JWT, child session token, xử lý 401
class ApiInterceptor extends Interceptor {
  ApiInterceptor(this.ref);
  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: đọc token từ secure storage / auth provider
    // options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: refresh token, logout on 401
    handler.next(err);
  }
}
