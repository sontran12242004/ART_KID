import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/kid_mode_remote_datasource.dart';
import '../../data/repositories/kid_mode_repository_impl.dart';
import '../../domain/entities/kid_reward.dart';
import '../../domain/repositories/kid_mode_repository.dart';
import '../../domain/usecases/get_kid_rewards.dart';
import '../../../../core/network/dio_client.dart';

final kidModeRemoteDataSourceProvider = Provider<KidModeRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioClientProvider);
  return KidModeRemoteDataSourceImpl(dio);
});

final kidModeRepositoryProvider = Provider<KidModeRepository>((ref) {
  final dataSource = ref.watch(kidModeRemoteDataSourceProvider);
  return KidModeRepositoryImpl(dataSource);
});

final getKidRewardsUseCaseProvider = Provider<GetKidRewardsUseCase>((ref) {
  final repository = ref.watch(kidModeRepositoryProvider);
  return GetKidRewardsUseCase(repository);
});

/// Provider nạp danh sách huy hiệu của bé
final kidRewardsProvider = FutureProvider.family<List<KidReward>, String>((
  ref,
  childId,
) async {
  final useCase = ref.watch(getKidRewardsUseCaseProvider);
  return useCase(childId);
});

/// Provider tính tổng điểm sao của bé
final kidPointsProvider = FutureProvider.family<int, String>((
  ref,
  childId,
) async {
  final repository = ref.watch(kidModeRepositoryProvider);
  return repository.getTotalPoints(childId);
});
