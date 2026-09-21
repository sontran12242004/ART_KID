import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentProfileState {
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final String parentAvatarId;
  final String childNickname;
  final int childAge;
  final int childBirthYear;
  final String childInterests;
  final String childAvatarId;
  final String currentCourseTitle;
  final bool notificationsEnabled;
  final bool dailyDrawingReminder;

  const ParentProfileState({
    this.parentName = 'Chị Mai Anh',
    this.parentEmail = 'maianh.parent@artkids.vn',
    this.parentPhone = '0988 123 456',
    this.parentAvatarId = 'parent_mom_art',
    this.childNickname = 'Bé Bo',
    this.childAge = 6,
    this.childBirthYear = 2020,
    this.childInterests = 'Động vật & Cổ tích',
    this.childAvatarId = 'child_cat',
    this.currentCourseTitle = 'Khóa Nét Vẽ Sáng Tạo',
    this.notificationsEnabled = true,
    this.dailyDrawingReminder = true,
  });

  ParentProfileState copyWith({
    String? parentName,
    String? parentEmail,
    String? parentPhone,
    String? parentAvatarId,
    String? childNickname,
    int? childAge,
    int? childBirthYear,
    String? childInterests,
    String? childAvatarId,
    String? currentCourseTitle,
    bool? notificationsEnabled,
    bool? dailyDrawingReminder,
  }) {
    return ParentProfileState(
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      parentAvatarId: parentAvatarId ?? this.parentAvatarId,
      childNickname: childNickname ?? this.childNickname,
      childAge: childAge ?? this.childAge,
      childBirthYear: childBirthYear ?? this.childBirthYear,
      childInterests: childInterests ?? this.childInterests,
      childAvatarId: childAvatarId ?? this.childAvatarId,
      currentCourseTitle: currentCourseTitle ?? this.currentCourseTitle,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      dailyDrawingReminder:
          dailyDrawingReminder ?? this.dailyDrawingReminder,
    );
  }
}

class ParentProfileNotifier extends StateNotifier<ParentProfileState> {
  ParentProfileNotifier() : super(const ParentProfileState());

  void setParentAvatar(String avatarId) {
    state = state.copyWith(parentAvatarId: avatarId);
  }

  void setChildAvatar(String avatarId) {
    state = state.copyWith(childAvatarId: avatarId);
  }

  void updateParentInfo({
    required String name,
    required String email,
    required String phone,
  }) {
    state = state.copyWith(
      parentName: name,
      parentEmail: email,
      parentPhone: phone,
    );
  }

  void updateChildInfo({
    required String nickname,
    required int age,
    required int birthYear,
    required String interests,
  }) {
    state = state.copyWith(
      childNickname: nickname,
      childAge: age,
      childBirthYear: birthYear,
      childInterests: interests,
    );
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleReminder(bool value) {
    state = state.copyWith(dailyDrawingReminder: value);
  }

  void saveAll({
    required String parentName,
    required String parentEmail,
    required String parentPhone,
    required String parentAvatarId,
    required String childNickname,
    required int childAge,
    required int childBirthYear,
    required String childInterests,
    required String childAvatarId,
    required bool notificationsEnabled,
    required bool dailyDrawingReminder,
  }) {
    state = state.copyWith(
      parentName: parentName,
      parentEmail: parentEmail,
      parentPhone: parentPhone,
      parentAvatarId: parentAvatarId,
      childNickname: childNickname,
      childAge: childAge,
      childBirthYear: childBirthYear,
      childInterests: childInterests,
      childAvatarId: childAvatarId,
      notificationsEnabled: notificationsEnabled,
      dailyDrawingReminder: dailyDrawingReminder,
    );
  }
}

final parentProfileProvider =
    StateNotifierProvider<ParentProfileNotifier, ParentProfileState>((ref) {
  return ParentProfileNotifier();
});
