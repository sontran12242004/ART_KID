import '../entities/subscription_plan.dart';
import '../repositories/shop_repository.dart';

class GetSubscriptionPlansUseCase {
  const GetSubscriptionPlansUseCase(this._repository);

  final ShopRepository _repository;

  Future<List<SubscriptionPlan>> call() => _repository.getPlans();
}

class CheckoutSubscriptionUseCase {
  const CheckoutSubscriptionUseCase(this._repository);

  final ShopRepository _repository;

  Future<void> call({required String planId}) =>
      _repository.checkout(planId: planId);
}
