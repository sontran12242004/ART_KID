import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Uses a separate HTTP client so application bearer tokens never reach storage.
class LectureVideoUploader {
  LectureVideoUploader()
    : _cloud = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(minutes: 3),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

  final Dio _cloud;

  Future<void> upload({
    required XFile file,
    required Map<String, dynamic> session,
    required CancelToken cancelToken,
    required void Function(double progress) onProgress,
  }) async {
    final total = await file.length();
    final upload = Map<String, dynamic>.from(session['upload']);
    final fields = Map<String, dynamic>.from(upload['fields']);
    final chunkSize = (session['chunkBytes'] as num).toInt();
    final uploadId =
        '${DateTime.now().microsecondsSinceEpoch}-${math.Random.secure().nextInt(1 << 30)}';
    for (var start = 0; start < total; start += chunkSize) {
      if (cancelToken.isCancelled) {
        throw cancelToken.cancelError!;
      }
      final end = math.min(start + chunkSize, total);
      final builder = BytesBuilder(copy: false);
      await for (final bytes in file.openRead(start, end)) {
        builder.add(bytes);
      }
      final chunk = builder.takeBytes();
      final response = await _cloud.post<dynamic>(
        upload['uploadUrl'] as String,
        data: FormData.fromMap({
          ...fields,
          'file': MultipartFile.fromBytes(chunk, filename: file.name),
        }),
        options: Options(
          headers: total > chunkSize
              ? {
                  'Content-Range': 'bytes $start-${end - 1}/$total',
                  'X-Unique-Upload-Id': uploadId,
                }
              : null,
        ),
        cancelToken: cancelToken,
        onSendProgress: (sent, count) => onProgress(
          (start + (end - start) * (count > 0 ? sent / count : 0)) / total,
        ),
      );
      if (end == total) {
        final result = response.data;
        if (result is! Map ||
            result['public_id'] != fields['public_id'] ||
            result['done'] == false) {
          throw StateError('Chưa xác nhận được video đã tải lên. Hãy thử lại.');
        }
      }
    }
    onProgress(1);
  }

  void dispose() => _cloud.close(force: true);
}
