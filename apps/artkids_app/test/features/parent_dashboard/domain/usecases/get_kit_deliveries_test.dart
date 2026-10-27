import 'package:flutter_test/flutter_test.dart';

import 'package:artkids_app/features/parent_dashboard/domain/entities/child_progress_report.dart';
import 'package:artkids_app/features/parent_dashboard/domain/entities/course_progress.dart';
import 'package:artkids_app/features/parent_dashboard/domain/entities/kit_delivery.dart';
import 'package:artkids_app/features/parent_dashboard/domain/repositories/parent_dashboard_repository.dart';
import 'package:artkids_app/features/parent_dashboard/domain/usecases/parent_dashboard_usecases.dart';

class FakeParentDashboardRepository implements ParentDashboardRepository {
  @override
  Future<List<KitDelivery>> getKitDeliveries(String parentId) async {
    return const [
      KitDelivery(
        id: 'kit-1',
        orderId: 'order-101',
        kitName: 'Hộp Màu & Giấy Vẽ Khám Phá Rừng Xanh',
        trackingNumber: 'VNPOST-888999',
        carrier: 'VNPost Nhanh',
        status: 'shipping',
        estimatedDeliveryDate: '15/09/2026',
      ),
    ];
  }

  @override
  Future<ChildProgressReport> getChildProgress(String childId) async {
    return ChildProgressReport(
      childId: childId,
      completedLessonsCount: 5,
      totalArtworksCount: 8,
      totalBadgesCount: 4,
      learningMinutesThisWeek: 120,
    );
  }

  @override
  Future<List<CourseProgress>> getChildCoursesProgress(String childId) async {
    return const [];
  }

  @override
  Future<void> updateKidPin({
    required String parentId,
    required String newPin,
  }) async {}
}

void main() {
  group('GetKitDeliveriesUseCase', () {
    late GetKitDeliveriesUseCase useCase;
    late FakeParentDashboardRepository repository;

    setUp(() {
      repository = FakeParentDashboardRepository();
      useCase = GetKitDeliveriesUseCase(repository);
    });

    test('returns deliveries with tracking information', () async {
      final deliveries = await useCase('parent-1');

      expect(deliveries.length, 1);
      expect(deliveries.first.status, 'shipping');
      expect(deliveries.first.trackingNumber, 'VNPOST-888999');
    });
  });
}
