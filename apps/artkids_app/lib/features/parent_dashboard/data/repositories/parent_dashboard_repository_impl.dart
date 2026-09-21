import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';
import '../../../courses/domain/entities/course.dart';
import '../../domain/entities/child_progress_report.dart';
import '../../domain/entities/course_progress.dart';
import '../../domain/entities/kit_delivery.dart';
import '../../domain/repositories/parent_dashboard_repository.dart';
import '../datasources/parent_dashboard_datasource.dart';

class ParentDashboardRepositoryImpl implements ParentDashboardRepository {
  ParentDashboardRepositoryImpl(this._dataSource);

  final ParentDashboardDataSource _dataSource;

  @override
  Future<List<KitDelivery>> getKitDeliveries(String parentId) async {
    try {
      final deliveries = await _dataSource.getKitDeliveries(parentId);
      if (deliveries.isNotEmpty) {
        return deliveries;
      }
    } catch (e) {
      debugPrint('[ParentDashboardRepository] Lỗi kết nối đơn hàng học cụ ($e). Dùng dữ liệu mẫu offline.');
    }
    return _defaultKitDeliveries;
  }

  @override
  Future<ChildProgressReport> getChildProgress(String childId) async {
    try {
      final report = await _dataSource.getChildProgress(childId);
      return report;
    } catch (e) {
      debugPrint('[ParentDashboardRepository] Lỗi kết nối báo cáo tiến độ ($e). Dùng dữ liệu mẫu offline.');
    }
    return _defaultChildProgressReport(childId);
  }

  @override
  Future<List<CourseProgress>> getChildCoursesProgress(String childId) async {
    // Kiểm tra cờ mock data của project
    if (EnvConfig.enableMockCoursesProgress) {
      debugPrint('[ParentDashboardRepository] Sử dụng mock tiến độ khóa học cho bé $childId');
      return _getMockChildCoursesProgress(childId);
    }

    try {
      final list = await _dataSource.getChildCoursesProgress(childId);
      if (list.isNotEmpty) {
        return list;
      }
    } catch (e) {
      debugPrint('[ParentDashboardRepository] Lỗi kết nối tiến độ khóa học ($e). Dùng dữ liệu mẫu offline.');
    }
    return _getMockChildCoursesProgress(childId);
  }

  @override
  Future<void> updateKidPin({required String parentId, required String newPin}) async {
    try {
      await _dataSource.updateKidPin(parentId: parentId, newPin: newPin);
    } catch (e) {
      debugPrint('[ParentDashboardRepository] updateKidPin offline fallback: $e');
    }
  }

  static const List<KitDelivery> _defaultKitDeliveries = [
    KitDelivery(
      id: 'del_001',
      orderId: 'ORD-2026-8921',
      kitName: 'Hộp Học Cụ Cọ Vẽ & Bảng Màu Pha Nước ArtKids',
      trackingNumber: 'VNPOST-884920194',
      status: 'shipping',
      estimatedDeliveryDate: '18/09/2026',
      carrier: 'VNPost Nhanh',
    ),
    KitDelivery(
      id: 'del_002',
      orderId: 'ORD-2026-7734',
      kitName: 'Bộ Dựng Hình Khối & Đất Nặn Tạo Hình 3D Cao Cấp',
      trackingNumber: 'GHN-993821045',
      status: 'delivered',
      estimatedDeliveryDate: '10/09/2026',
      carrier: 'Giao Hàng Nhanh (GHN)',
    ),
  ];

  static ChildProgressReport _defaultChildProgressReport(String childId) {
    return ChildProgressReport(
      childId: childId,
      completedLessonsCount: 12,
      totalArtworksCount: 24,
      totalBadgesCount: 8,
      learningMinutesThisWeek: 185,
      latestCreatures: const ['creature_cat', 'creature_dragon', 'creature_rocket'],
    );
  }

  /// Mock data tiến độ theo từng bé, hỗ trợ multi-child chuẩn xác
  static List<CourseProgress> _getMockChildCoursesProgress(String childId) {
    final now = DateTime.now();

    // Trường hợp bé mới chưa học khóa nào (test trạng thái rỗng)
    if (childId == 'child-empty' || childId == 'new-child') {
      return const [];
    }

    // Trường hợp bé thứ 2 với số lượng khóa học khác
    if (childId == 'child-2') {
      return [
        CourseProgress(
          courseId: 'course_1_basic_lines',
          courseTitle: 'Nét Cọ Khởi Đầu - Bé Học Nét & Khối Cơ Bản',
          courseThumbnail: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400',
          totalLessons: 10,
          completedLessons: 4,
          lastLearnedAt: now.subtract(const Duration(hours: 3)),
          status: CourseProgressStatus.inProgress,
          course: const Course(
            id: 'course_1_basic_lines',
            title: 'Nét Cọ Khởi Đầu - Bé Học Nét & Khối Cơ Bản',
            description: 'Làm quen nét vẽ tự nhiên và vòng tròn diệu kỳ',
          ),
        ),
        CourseProgress(
          courseId: 'course_5_creature_ai',
          courseTitle: 'Sáng Tạo Sinh Vật Huyền Bí Với AI',
          courseThumbnail: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=400',
          totalLessons: 6,
          completedLessons: 1,
          lastLearnedAt: now.subtract(const Duration(days: 2)),
          status: CourseProgressStatus.inProgress,
          course: const Course(
            id: 'course_5_creature_ai',
            title: 'Sáng Tạo Sinh Vật Huyền Bí Với AI',
            description: 'Vẽ nét tranh và hô biến thành sinh vật 3D sống động cùng AI',
          ),
        ),
      ];
    }

    // Mặc định (child-1 và các bé đang học): 4 khóa học đa dạng trạng thái
    return [
      CourseProgress(
        courseId: 'course_2_cute_animals',
        courseTitle: 'Vương Quốc Động Vật Đáng Yêu',
        courseThumbnail: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=400',
        totalLessons: 12,
        completedLessons: 8,
        // Học gần nhất sáng nay
        lastLearnedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        status: CourseProgressStatus.inProgress,
        course: const Course(
          id: 'course_2_cute_animals',
          title: 'Vương Quốc Động Vật Đáng Yêu',
          description: 'Học cách vẽ các bạn thú cưng quen thuộc: mèo lười, cún con...',
        ),
      ),
      CourseProgress(
        courseId: 'course_1_basic_lines',
        courseTitle: 'Nét Cọ Khởi Đầu - Bé Học Nét & Khối Cơ Bản',
        courseThumbnail: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400',
        totalLessons: 10,
        completedLessons: 10,
        // Học gần nhất hôm qua
        lastLearnedAt: now.subtract(const Duration(days: 1, hours: 3)),
        status: CourseProgressStatus.completed,
        course: const Course(
          id: 'course_1_basic_lines',
          title: 'Nét Cọ Khởi Đầu - Bé Học Nét & Khối Cơ Bản',
          description: 'Làm quen với các nét vẽ tự nhiên, vòng tròn diệu kỳ',
        ),
      ),
      CourseProgress(
        courseId: 'course_3_color_magic',
        courseTitle: 'Phù Thủy Sắc Màu & Nghệ Thuật Pha Màu',
        courseThumbnail: 'https://images.unsplash.com/photo-1547891654-e66ed7ebb968?w=400',
        totalLessons: 14,
        completedLessons: 3,
        // Học gần nhất 3 ngày trước
        lastLearnedAt: now.subtract(const Duration(days: 3, hours: 5)),
        status: CourseProgressStatus.inProgress,
        course: const Course(
          id: 'course_3_color_magic',
          title: 'Phù Thủy Sắc Màu & Nghệ Thuật Pha Màu',
          description: 'Cảm thụ màu sắc, bí kíp pha màu tương phản',
        ),
      ),
      CourseProgress(
        courseId: 'course_4_landscape_nature',
        courseTitle: 'Họa Sĩ Nhí Khám Phá Thiên Nhiên',
        courseThumbnail: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=400',
        totalLessons: 8,
        completedLessons: 0,
        // Chưa bắt đầu, chưa có thời điểm học
        lastLearnedAt: null,
        status: CourseProgressStatus.notStarted,
        course: const Course(
          id: 'course_4_landscape_nature',
          title: 'Họa Sĩ Nhí Khám Phá Thiên Nhiên',
          description: 'Kỹ thuật phối cảnh cơ bản, vẽ cây cối, dòng sông...',
        ),
      ),
    ];
  }
}
