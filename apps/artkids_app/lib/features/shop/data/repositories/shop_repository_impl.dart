import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/shop_remote_datasource.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this.remote);
  final ShopRemoteDataSource remote;
  @override
  Future<List<SubscriptionPlan>> getPlans() => remote.getPlans();
  @override
  Future<void> checkout({required String planId}) =>
      remote.checkout(planId: planId);
}
