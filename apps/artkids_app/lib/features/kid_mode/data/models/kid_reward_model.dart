import '../../domain/entities/kid_reward.dart';

class KidRewardModel extends KidReward {
  const KidRewardModel({
    required super.id,
    required super.title,
    required super.iconName,
    required super.unlockedAt,
    super.description = '',
  });

  factory KidRewardModel.fromJson(Map<String, dynamic> json) {
    return KidRewardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      iconName: json['icon_name'] as String? ?? json['iconName'] as String? ?? 'star',
      unlockedAt: DateTime.tryParse(json['unlocked_at'] as String? ?? '') ?? DateTime.now(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon_name': iconName,
      'unlocked_at': unlockedAt.toIso8601String(),
      'description': description,
    };
  }
}
