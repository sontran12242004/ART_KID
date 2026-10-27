import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// HTTP boundary fixture: repositories still serialize and parse real API shapes.
class FixtureAdapter implements HttpClientAdapter {
  FixtureAdapter(this.respond);
  final ResponseBody Function(RequestOptions request) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
Dio fixtureDio(ResponseBody Function(RequestOptions request) respond) =>
    Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
      ..httpClientAdapter = FixtureAdapter(respond);
