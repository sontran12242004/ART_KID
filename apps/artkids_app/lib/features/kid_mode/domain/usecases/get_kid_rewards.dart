import '../entities/kid_reward.dart';
import '../repositories/kid_mode_repository.dart';

class GetKidRewardsUseCase {
  const GetKidRewardsUseCase(this._repository);

  final KidModeRepository _repository;

  Future<List<KidReward>> call(String childId) =>
      _repository.getRewards(childId);
}
