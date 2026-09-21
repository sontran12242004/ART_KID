import '../entities/child_progress_report.dart';
import '../entities/kit_delivery.dart';
import '../repositories/parent_dashboard_repository.dart';

class GetKitDeliveriesUseCase {
  const GetKitDeliveriesUseCase(this._repository);

  final ParentDashboardRepository _repository;

  Future<List<KitDelivery>> call(String parentId) =>
      _repository.getKitDeliveries(parentId);
}

class GetChildProgressUseCase {
  const GetChildProgressUseCase(this._repository);

  final ParentDashboardRepository _repository;

  Future<ChildProgressReport> call(String childId) =>
      _repository.getChildProgress(childId);
}

class UpdateKidPinUseCase {
  const UpdateKidPinUseCase(this._repository);

  final ParentDashboardRepository _repository;

  Future<void> call({required String parentId, required String newPin}) =>
      _repository.updateKidPin(parentId: parentId, newPin: newPin);
}
