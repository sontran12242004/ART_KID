import '../../domain/entities/child_profile.dart';

class ChildProfileModel extends ChildProfile {
  const ChildProfileModel({
    required super.id,
    required super.parentId,
    required super.nickname,
    required super.age,
    super.avatarUrl,
    super.totalPoints = 0,
    super.badgeCount = 0,
  });

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id'] as String,
      parentId:
          json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      nickname: json['nickname'] as String,
      age: json['age'] as int,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      totalPoints:
          json['total_points'] as int? ?? json['totalPoints'] as int? ?? 0,
      badgeCount:
          json['badge_count'] as int? ?? json['badgeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'nickname': nickname,
      'age': age,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'badge_count': badgeCount,
    };
  }
}
