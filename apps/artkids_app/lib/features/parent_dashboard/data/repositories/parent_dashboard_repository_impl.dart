import '../../domain/entities/child_progress_report.dart';
import '../../domain/entities/course_progress.dart';
import '../../domain/entities/kit_delivery.dart';
import '../../domain/repositories/parent_dashboard_repository.dart';
import '../datasources/parent_dashboard_datasource.dart';

class ParentDashboardRepositoryImpl implements ParentDashboardRepository {
  ParentDashboardRepositoryImpl(this.remote);
  final ParentDashboardDataSource remote;
  @override
  Future<List<KitDelivery>> getKitDeliveries(String parentId) =>
      remote.getKitDeliveries(parentId);
  @override
  Future<ChildProgressReport> getChildProgress(String childId) =>
      remote.getChildProgress(childId);
  @override
  Future<List<CourseProgress>> getChildCoursesProgress(String childId) =>
      remote.getChildCoursesProgress(childId);
  @override
  Future<void> updateKidPin({
    required String parentId,
    required String newPin,
  }) => remote.updateKidPin(parentId: parentId, newPin: newPin);
}
