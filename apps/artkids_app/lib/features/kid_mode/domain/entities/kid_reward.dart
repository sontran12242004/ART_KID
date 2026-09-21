import 'package:equatable/equatable.dart';

class KidReward extends Equatable {
  const KidReward({
    required this.id,
    required this.title,
    required this.iconName,
    required this.unlockedAt,
    this.description = '',
  });

  final String id;
  final String title;
  final String iconName;
  final DateTime unlockedAt;
  final String description;

  @override
  List<Object?> get props => [id, title, iconName, unlockedAt, description];
}
