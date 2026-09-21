import 'package:flutter_test/flutter_test.dart';

import 'package:artkids_app/features/kid_mode/domain/entities/kid_reward.dart';
import 'package:artkids_app/features/kid_mode/domain/repositories/kid_mode_repository.dart';
import 'package:artkids_app/features/kid_mode/domain/usecases/get_kid_rewards.dart';

class FakeKidModeRepository implements KidModeRepository {
  @override
  Future<List<KidReward>> getRewards(String childId) async {
    return [
      KidReward(
        id: 'r1',
        title: 'Họa Sĩ Nhí',
        iconName: 'brush',
        unlockedAt: DateTime(2026, 9, 1),
        description: 'Vẽ bức tranh đầu tiên',
      ),
    ];
  }

  @override
  Future<int> getTotalPoints(String childId) async {
    return 150;
  }
}

void main() {
  group('GetKidRewardsUseCase', () {
    late GetKidRewardsUseCase useCase;
    late FakeKidModeRepository repository;

    setUp(() {
      repository = FakeKidModeRepository();
      useCase = GetKidRewardsUseCase(repository);
    });

    test('returns rewards for specified child', () async {
      final rewards = await useCase('child-123');

      expect(rewards, isNotEmpty);
      expect(rewards.first.title, 'Họa Sĩ Nhí');
      expect(rewards.first.iconName, 'brush');
    });
  });
}
