import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses();
  Future<List<LessonModel>> getLessons(String courseId);
  Future<void> updateProgress({required String childId, required String lessonId, required int percent});
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  CourseRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CourseModel>> getCourses() async {
    final response = await _dio.get<List<dynamic>>(ApiConstants.courses);
    return (response.data ?? [])
        .map((item) => CourseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LessonModel>> getLessons(String courseId) async {
    final response = await _dio.get<List<dynamic>>('${ApiConstants.courses}/$courseId/lessons');
    return (response.data ?? [])
        .map((item) => LessonModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateProgress({
    required String childId,
    required String lessonId,
    required int percent,
  }) async {
    await _dio.post(ApiConstants.progress, data: {
      'child_id': childId,
      'lesson_id': lessonId,
      'percent': percent,
    });
  }
}
