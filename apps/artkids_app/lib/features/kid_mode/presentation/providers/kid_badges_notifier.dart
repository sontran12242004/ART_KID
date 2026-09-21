import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/achievement_badge.dart';

enum BadgeFilterTab {
  all('Tất Cả (20)'),
  unlocked('Đã Đạt'),
  locked('Chưa Đạt'),
  habit('Thói Quen Vẽ'),
  skill('Kỹ Thuật Vẽ'),
  achievement('Thành Tích Cọ Vẽ');

  final String label;
  const BadgeFilterTab(this.label);
}

class KidBadgesState {
  final List<AchievementBadge> badges;
  final BadgeFilterTab currentTab;
  final int totalStars;
  final AchievementBadge? newlyUnlockedBadge;

  const KidBadgesState({
    required this.badges,
    this.currentTab = BadgeFilterTab.all,
    this.totalStars = 145,
    this.newlyUnlockedBadge,
  });

  int get unlockedCount => badges.where((b) => b.isUnlocked).length;
  int get totalCount => badges.length;
  double get overallProgressRatio =>
      totalCount > 0 ? unlockedCount / totalCount : 0.0;

  List<AchievementBadge> get filteredBadges {
    return switch (currentTab) {
      BadgeFilterTab.all => badges,
      BadgeFilterTab.unlocked => badges.where((b) => b.isUnlocked).toList(),
      BadgeFilterTab.locked => badges.where((b) => !b.isUnlocked).toList(),
      BadgeFilterTab.habit =>
        badges.where((b) => b.category == BadgeCategory.habit).toList(),
      BadgeFilterTab.skill =>
        badges.where((b) => b.category == BadgeCategory.skill).toList(),
      BadgeFilterTab.achievement => badges
          .where((b) =>
              b.category == BadgeCategory.achievement ||
              b.category == BadgeCategory.special)
          .toList(),
    };
  }

  KidBadgesState copyWith({
    List<AchievementBadge>? badges,
    BadgeFilterTab? currentTab,
    int? totalStars,
    AchievementBadge? newlyUnlockedBadge,
    bool clearNewlyUnlocked = false,
  }) {
    return KidBadgesState(
      badges: badges ?? this.badges,
      currentTab: currentTab ?? this.currentTab,
      totalStars: totalStars ?? this.totalStars,
      newlyUnlockedBadge: clearNewlyUnlocked
          ? null
          : (newlyUnlockedBadge ?? this.newlyUnlockedBadge),
    );
  }
}

class KidBadgesNotifier extends StateNotifier<KidBadgesState> {
  KidBadgesNotifier()
      : super(const KidBadgesState(badges: AchievementBadge.all20Badges));

  void setFilterTab(BadgeFilterTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void unlockBadge(String id) {
    final updatedList = state.badges.map((b) {
      if (b.id == id && !b.isUnlocked) {
        final unlocked = b.copyWith(
          isUnlocked: true,
          currentProgress: b.maxProgress,
          unlockedAt: DateTime.now(),
        );
        return unlocked;
      }
      return b;
    }).toList();

    final justUnlocked = updatedList.firstWhere(
      (b) => b.id == id,
      orElse: () => state.badges.first,
    );

    // Tự động kiểm tra mở khóa "Đại Sứ Toàn Năng" (#20) nếu đạt đủ 15 huy hiệu
    final unlockedCountWithout20 = updatedList
        .where((b) => b.id != 'badge_20_grandmaster' && b.isUnlocked)
        .length;

    final finalList = updatedList.map((b) {
      if (b.id == 'badge_20_grandmaster') {
        return b.copyWith(
          currentProgress: unlockedCountWithout20,
          isUnlocked: unlockedCountWithout20 >= 15,
          unlockedAt: unlockedCountWithout20 >= 15 ? DateTime.now() : null,
        );
      }
      return b;
    }).toList();

    state = state.copyWith(
      badges: finalList,
      totalStars: state.totalStars + 25,
      newlyUnlockedBadge: justUnlocked,
    );
  }

  void updateProgress(String id, int delta) {
    final updatedList = state.badges.map((b) {
      if (b.id == id && !b.isUnlocked) {
        final newProgress =
            (b.currentProgress + delta).clamp(0, b.maxProgress);
        final isNowUnlocked = newProgress >= b.maxProgress;
        return b.copyWith(
          currentProgress: newProgress,
          isUnlocked: isNowUnlocked,
          unlockedAt: isNowUnlocked ? DateTime.now() : null,
        );
      }
      return b;
    }).toList();

    state = state.copyWith(badges: updatedList);
  }

  void clearCelebration() {
    state = state.copyWith(clearNewlyUnlocked: true);
  }
}

final kidBadgesNotifierProvider =
    StateNotifierProvider<KidBadgesNotifier, KidBadgesState>((ref) {
  return KidBadgesNotifier();
});
