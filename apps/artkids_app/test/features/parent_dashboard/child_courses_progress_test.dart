import 'package:artkids_app/features/parent_dashboard/data/datasources/parent_dashboard_datasource.dart';
import 'package:artkids_app/features/parent_dashboard/data/models/kit_delivery_model.dart';
import 'package:artkids_app/features/parent_dashboard/data/repositories/parent_dashboard_repository_impl.dart';
import 'package:artkids_app/features/parent_dashboard/domain/entities/child_progress_report.dart';
import 'package:artkids_app/features/parent_dashboard/domain/entities/course_progress.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDataSource implements ParentDashboardDataSource {
  @override
  Future<List<CourseProgress>> getChildCoursesProgress(String childId) async =>
      [];

  @override
  Future<ChildProgressReport> getChildProgress(String childId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<KitDeliveryModel>> getKitDeliveries(String parentId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateKidPin({
    required String parentId,
    required String newPin,
  }) async {}
}

void main() {
  group('CourseProgress Entity & Calculation Tests', () {
    test('Tính đúng progressPercent và progressPercentageInt', () {
      // 8/12 bài học
      final progress1 = CourseProgress(
        courseId: 'c1',
        courseTitle: 'Khóa 1',
        totalLessons: 12,
        completedLessons: 8,
        status: CourseProgressStatus.inProgress,
      );
      expect((progress1.progressPercent * 100).round(), 67);
      expect(progress1.progressPercentageInt, 67);

      // 10/10 bài học (hoàn thành)
      final progress2 = CourseProgress(
        courseId: 'c2',
        courseTitle: 'Khóa 2',
        totalLessons: 10,
        completedLessons: 10,
        status: CourseProgressStatus.completed,
      );
      expect(progress2.progressPercent, 1.0);
      expect(progress2.progressPercentageInt, 100);

      // 0/8 bài học (chưa bắt đầu)
      final progress3 = CourseProgress(
        courseId: 'c3',
        courseTitle: 'Khóa 3',
        totalLessons: 8,
        completedLessons: 0,
        status: CourseProgressStatus.notStarted,
      );
      expect(progress3.progressPercent, 0.0);
      expect(progress3.progressPercentageInt, 0);

      // Edge case: totalLessons = 0
      final progress0 = CourseProgress(
        courseId: 'c0',
        courseTitle: 'Khóa 0',
        totalLessons: 0,
        completedLessons: 0,
        status: CourseProgressStatus.notStarted,
      );
      expect(progress0.progressPercent, 0.0);
      expect(progress0.progressPercentageInt, 0);
    });

    test(
      'CourseProgressStatus.fromString nhận diện đúng tiếng Việt và enum name',
      () {
        expect(
          CourseProgressStatus.fromString('Đang học'),
          CourseProgressStatus.inProgress,
        );
        expect(
          CourseProgressStatus.fromString('inProgress'),
          CourseProgressStatus.inProgress,
        );
        expect(
          CourseProgressStatus.fromString('Hoàn thành'),
          CourseProgressStatus.completed,
        );
        expect(
          CourseProgressStatus.fromString('completed'),
          CourseProgressStatus.completed,
        );
        expect(
          CourseProgressStatus.fromString('Chưa bắt đầu'),
          CourseProgressStatus.notStarted,
        );
        expect(
          CourseProgressStatus.fromString('notStarted'),
          CourseProgressStatus.notStarted,
        );
        expect(
          CourseProgressStatus.fromString(null),
          CourseProgressStatus.notStarted,
        );
      },
    );

    test('Chuyển đổi toJson và fromJson bảo toàn dữ liệu', () {
      final now = DateTime(2026, 9, 17, 8, 30);
      final item = CourseProgress(
        courseId: 'c_test',
        courseTitle: 'Khóa Kiểm Thử',
        courseThumbnail: 'https://example.com/thumb.jpg',
        totalLessons: 15,
        completedLessons: 6,
        lastLearnedAt: now,
        status: CourseProgressStatus.inProgress,
      );

      final json = item.toJson();
      final parsed = CourseProgress.fromJson(json);

      expect(parsed.courseId, item.courseId);
      expect(parsed.courseTitle, item.courseTitle);
      expect(parsed.totalLessons, 15);
      expect(parsed.completedLessons, 6);
      expect(parsed.status, CourseProgressStatus.inProgress);
      expect(parsed.lastLearnedAt, now);
    });
  });

  test('empty server progress remains empty for each child', () async {
    final repo = ParentDashboardRepositoryImpl(_FakeDataSource());
    expect(await repo.getChildCoursesProgress('child-1'), isEmpty);
    expect(await repo.getChildCoursesProgress('child-2'), isEmpty);
  });
}
