import '../entities/child_progress_report.dart';
import '../entities/course_progress.dart';
import '../entities/kit_delivery.dart';

abstract class ParentDashboardRepository {
  Future<List<KitDelivery>> getKitDeliveries(String parentId);
  Future<ChildProgressReport> getChildProgress(String childId);
  Future<List<CourseProgress>> getChildCoursesProgress(String childId);
  Future<void> updateKidPin({required String parentId, required String newPin});
}
