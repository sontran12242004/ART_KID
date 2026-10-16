import 'package:dio/dio.dart';

import '../models/kit_delivery_model.dart';
import '../../domain/entities/child_progress_report.dart';
import '../../domain/entities/course_progress.dart';

abstract class ParentDashboardDataSource {
  Future<List<KitDeliveryModel>> getKitDeliveries(String parentId);
  Future<ChildProgressReport> getChildProgress(String childId);
  Future<List<CourseProgress>> getChildCoursesProgress(String childId);
  Future<void> updateKidPin({required String parentId, required String newPin});
}

class ParentDashboardDataSourceImpl implements ParentDashboardDataSource {
  ParentDashboardDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<KitDeliveryModel>> getKitDeliveries(String parentId) async {
    final response = await _dio.get<List<dynamic>>(
      '/parent/fulfillments',
      queryParameters: {'parent_id': parentId},
    );
    return (response.data ?? [])
        .map((item) => KitDeliveryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChildProgressReport> getChildProgress(String childId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/parent/children/$childId/progress-report',
    );
    final data = response.data ?? {};
    return ChildProgressReport(
      childId: childId,
      completedLessonsCount: data['completed_lessons_count'] as int? ?? 0,
      totalArtworksCount: data['total_artworks_count'] as int? ?? 0,
      totalBadgesCount: data['total_badges_count'] as int? ?? 0,
      learningMinutesThisWeek: data['learning_minutes_this_week'] as int? ?? 0,
    );
  }

  @override
  Future<List<CourseProgress>> getChildCoursesProgress(String childId) async {
    final response = await _dio.get<List<dynamic>>(
      '/children/$childId/courses-progress',
    );
    final data = response.data ?? [];
    return data
        .map((item) => CourseProgress.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateKidPin({
    required String parentId,
    required String newPin,
  }) async {
    await _dio.put(
      '/auth/kid-pin',
      data: {'parent_id': parentId, 'new_pin': newPin},
    );
  }
}
