import 'package:dio/dio.dart';
import '../../../../core/network/api_json.dart';

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
    final response = await _dio.get<List<dynamic>>('/fulfillment/shipments');
    return (response.data ?? [])
        .map((item) => KitDeliveryModel.fromJson(apiMap(item)))
        .toList();
  }

  @override
  Future<ChildProgressReport> getChildProgress(String childId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/children/$childId/dashboard',
    );
    final data = apiMap(response.data ?? {});
    return ChildProgressReport(
      childId: childId,
      completedLessonsCount: data['completed_lessons_count'] as int? ?? 0,
      totalArtworksCount: data['total_artworks_count'] as int? ?? 0,
      totalBadgesCount: data['total_badges_count'] as int? ?? 0,
      learningMinutesThisWeek: ((data['learningSeconds'] as num? ?? 0) / 60)
          .floor(),
    );
  }

  @override
  Future<List<CourseProgress>> getChildCoursesProgress(String childId) async {
    final response = await _dio.get<List<dynamic>>(
      '/courses/progress',
      queryParameters: {'childId': childId},
    );
    final data = response.data ?? [];
    return data.map((item) => CourseProgress.fromJson(apiMap(item))).toList();
  }

  @override
  Future<void> updateKidPin({
    required String parentId,
    required String newPin,
  }) async {
    throw UnsupportedError(
      'Đổi PIN trong Cài đặt tài khoản và nhập mật khẩu để xác nhận.',
    );
  }
}
