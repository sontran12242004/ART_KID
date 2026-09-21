import '../../domain/entities/kid_reward.dart';
import '../../domain/repositories/kid_mode_repository.dart';
import '../datasources/kid_mode_remote_datasource.dart';

class KidModeRepositoryImpl implements KidModeRepository {
  KidModeRepositoryImpl(this._remoteDataSource);

  final KidModeRemoteDataSource _remoteDataSource;

  @override
  Future<List<KidReward>> getRewards(String childId) =>
      _remoteDataSource.getRewards(childId);

  @override
  Future<int> getTotalPoints(String childId) =>
      _remoteDataSource.getTotalPoints(childId);
}
