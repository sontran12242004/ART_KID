import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/drawing_submission_model.dart';

abstract class DrawingRemoteDataSource {
  Future<DrawingSubmissionModel> submitDrawing({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
  });
}

class DrawingRemoteDataSourceImpl implements DrawingRemoteDataSource {
  DrawingRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<DrawingSubmissionModel> submitDrawing({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
  }) async {
    final formData = FormData.fromMap({
      'lesson_id': lessonId,
      'child_id': childId,
      'image': MultipartFile.fromBytes(
        Uint8List.fromList(pngBytes),
        filename: 'drawing_${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.kidSubmitDrawing,
      data: formData,
    );

    return DrawingSubmissionModel.fromJson(response.data ?? {});
  }
}
