import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/shop_remote_datasource.dart';
import '../../data/repositories/shop_repository_impl.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/shop_repository.dart';

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ShopRemoteDataSourceImpl(dio);
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final remote = ref.watch(shopRemoteDataSourceProvider);
  return ShopRepositoryImpl(remote);
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  return repo.getPlans();
});
