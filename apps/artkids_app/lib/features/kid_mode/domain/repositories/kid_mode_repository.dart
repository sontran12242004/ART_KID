import '../entities/kid_reward.dart';

abstract class KidModeRepository {
  Future<List<KidReward>> getRewards(String childId);
  Future<int> getTotalPoints(String childId);
}
