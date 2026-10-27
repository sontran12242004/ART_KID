import 'package:dio/dio.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses();
  Future<List<LessonModel>> getLessons(String courseId);
  Future<void> updateProgress({
    required String childId,
    required String lessonId,
    required int percent,
  });
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  CourseRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CourseModel>> getCourses() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.courses,
      queryParameters: {'pageSize': 100},
    );
    return apiList(
      response.data,
    ).map((item) => CourseModel.fromJson(apiMap(item))).toList();
  }

  @override
  Future<List<LessonModel>> getLessons(String courseId) async {
    final response = await _dio.get<List<dynamic>>(
      '${ApiConstants.courses}/$courseId/lessons',
    );
    return (response.data ?? [])
        .map((item) => LessonModel.fromJson(apiMap(item)))
        .toList();
  }

  @override
  Future<void> updateProgress({
    required String childId,
    required String lessonId,
    required int percent,
  }) async {
    await _dio.post(
      ApiConstants.progress,
      data: {
        'childId': childId,
        'lessonId': lessonId,
        'status': percent >= 100 ? 'completed' : 'in_progress',
      },
    );
  }
}
