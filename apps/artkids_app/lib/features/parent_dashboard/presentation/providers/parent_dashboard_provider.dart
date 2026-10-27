import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/parent_dashboard_datasource.dart';
import '../../data/repositories/parent_dashboard_repository_impl.dart';
import '../../domain/entities/child_progress_report.dart';
import '../../domain/entities/course_progress.dart';
import '../../domain/entities/kit_delivery.dart';
import '../../domain/repositories/parent_dashboard_repository.dart';
import '../../domain/usecases/parent_dashboard_usecases.dart';

final parentDashboardDataSourceProvider = Provider<ParentDashboardDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return ParentDashboardDataSourceImpl(dio);
});

final parentDashboardRepositoryProvider = Provider<ParentDashboardRepository>((
  ref,
) {
  final ds = ref.watch(parentDashboardDataSourceProvider);
  return ParentDashboardRepositoryImpl(ds);
});

final updateKidPinUseCaseProvider = Provider<UpdateKidPinUseCase>((ref) {
  final repo = ref.watch(parentDashboardRepositoryProvider);
  return UpdateKidPinUseCase(repo);
});

final getKitDeliveriesUseCaseProvider = Provider<GetKitDeliveriesUseCase>((
  ref,
) {
  final repo = ref.watch(parentDashboardRepositoryProvider);
  return GetKitDeliveriesUseCase(repo);
});

final getChildProgressUseCaseProvider = Provider<GetChildProgressUseCase>((
  ref,
) {
  final repo = ref.watch(parentDashboardRepositoryProvider);
  return GetChildProgressUseCase(repo);
});

final kitDeliveriesProvider = FutureProvider.family<List<KitDelivery>, String>((
  ref,
  parentId,
) async {
  final repo = ref.watch(parentDashboardRepositoryProvider);
  return repo.getKitDeliveries(parentId);
});

final childProgressReportProvider =
    FutureProvider.family<ChildProgressReport, String>((ref, childId) async {
      final repo = ref.watch(parentDashboardRepositoryProvider);
      return repo.getChildProgress(childId);
    });

final childProgressProvider = childProgressReportProvider;

/// Provider cung cấp danh sách tiến độ theo từng khóa học cho bé tương ứng
final childCoursesProgressProvider =
    FutureProvider.family<List<CourseProgress>, String>((ref, childId) async {
      final repo = ref.watch(parentDashboardRepositoryProvider);
      return repo.getChildCoursesProgress(childId);
    });
