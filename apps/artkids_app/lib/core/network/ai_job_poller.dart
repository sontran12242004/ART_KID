import 'dart:async';

import 'package:dio/dio.dart';

/// Poll trạng thái AI job: pending → processing → done | failed
enum AiJobStatus { pending, processing, done, failed }

class AiJobPoller {
  AiJobPoller(this._dio);

  final Dio _dio;
  static const _pollInterval = Duration(seconds: 2);
  static const _maxAttempts = 60;

  Stream<AiJobStatus> pollSubmissionStatus(String submissionId) async* {
    for (var i = 0; i < _maxAttempts; i++) {
      // TODO: gọi GET /kid/submissions/{id}/status
      final response = await _dio.get<Map<String, dynamic>>(
        '/kid/submissions/$submissionId/status',
      );
      final status = response.data?['status'] as String? ?? 'pending';
      yield _parseStatus(status);
      if (status == 'done' || status == 'failed') break;
      await Future<void>.delayed(_pollInterval);
    }
  }

  AiJobStatus _parseStatus(String raw) => switch (raw) {
        'processing' => AiJobStatus.processing,
        'done' => AiJobStatus.done,
        'failed' => AiJobStatus.failed,
        _ => AiJobStatus.pending,
      };
}
