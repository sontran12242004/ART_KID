import '../entities/subscription_plan.dart';

abstract class ShopRepository {
  Future<List<SubscriptionPlan>> getPlans();
  Future<void> checkout({required String planId});
}
