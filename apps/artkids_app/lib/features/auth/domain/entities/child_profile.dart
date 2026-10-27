import 'package:equatable/equatable.dart';

/// COPPA: chỉ nickname + age, không lưu PII nhạy cảm của trẻ em
class ChildProfile extends Equatable {
  const ChildProfile({
    required this.id,
    required this.nickname,
    this.parentId = '',
    this.age = 6,
    this.birthYear = 2020,
    this.avatarUrl,
    this.totalPoints = 0,
    this.badgeCount = 0,
  });

  final String id;
  final String parentId;
  final String nickname;
  final int age;
  final int birthYear;
  final String? avatarUrl;
  final int totalPoints;
  final int badgeCount;

  int get points => totalPoints;

  @override
  List<Object?> get props => [
    id,
    parentId,
    nickname,
    age,
    birthYear,
    avatarUrl,
    totalPoints,
    badgeCount,
  ];
}
