import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/achievement_badge.dart';
import '../providers/kid_badges_notifier.dart';
import '../widgets/badge_card_widget.dart';
import '../widgets/badge_detail_dialog.dart';

/// Màn hình Bộ sưu tập 20 Huy Hiệu Thành Tích của bé — Kid Mode
class KidBadgesScreen extends ConsumerWidget {
  const KidBadgesScreen({super.key, this.childId = 'current-child'});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kidBadgesNotifierProvider);
    final notifier = ref.read(kidBadgesNotifierProvider.notifier);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9E6), Color(0xFFFFFDF5), Color(0xFFF7FDFD)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 32,
                        color: Color(0xFF1687A7),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Huy Hiệu Của Bé',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F3B46),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    // Nút hỗ trợ / thông tin
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 26,
                        color: Color(0xFF556E74),
                      ),
                      onPressed: () => _showCollectionInfo(context),
                    ),
                  ],
                ),
              ),

              // Bảng Thống Kê Tổng Quan (Sao + Huy Hiệu)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Cột Sao
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${state.totalStars}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Ngôi Sao Tích Lũy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(width: 1, height: 40, color: Colors.white30),

                        // Cột Huy Hiệu
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${state.unlockedCount} / ${state.totalCount}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Huy Hiệu Đã Đạt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.military_tech_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Thanh tiến trình hoàn thành bộ sưu tập
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.overallProgressRatio,
                        minHeight: 8,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bé đã mở khóa ${(state.overallProgressRatio * 100).toInt()}% bộ sưu tập 20 Huy Hiệu! 🚀',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Filter Chips Thanh cuộn ngang
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: BadgeFilterTab.values.map((tab) {
                    final isSelected = state.currentTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(tab.label),
                        selectedColor: const Color(0xFF1687A7),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4C6E76),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF1687A7)
                                : const Color(0xFFE2EFEF),
                            width: 1.2,
                          ),
                        ),
                        onSelected: (_) => notifier.setFilterTab(tab),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Lưới hiển thị 20 Huy Hiệu
              Expanded(
                child: state.filteredBadges.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              size: 64,
                              color: Color(0xFFB0BEC5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có huy hiệu nào trong mục "${state.currentTab.label}"',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78909C),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: state.filteredBadges.length,
                        itemBuilder: (context, index) {
                          final badge = state.filteredBadges[index];
                          return BadgeCardWidget(
                            badge: badge,
                            onTap: () {
                              BadgeDetailDialog.show(
                                context,
                                badge: badge,
                                onUnlockDemo: () {
                                  notifier.unlockBadge(badge.id);
                                  _showUnlockToast(context, badge);
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockToast(BuildContext context, AchievementBadge badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1A52A8),
        content: Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 Mở Khóa Thành Công!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Bé đã đạt huy hiệu "${badge.title}" (+25 Sao)',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFB800),
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Hệ Thống 20 Huy Hiệu'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ArtKids vinh danh các cột mốc sáng tạo hội họa của bé qua 20 Huy Hiệu:',
              style: TextStyle(fontSize: 14, color: Color(0xFF33555D)),
            ),
            SizedBox(height: 10),
            Text(
              '🌱 Thói Quen Vẽ: Rèn luyện tính kiên trì, chuỗi ngày vẽ tranh liên tục.',
            ),
            SizedBox(height: 6),
            Text(
              '🌟 Thành Tích Cọ Vẽ: Điểm thưởng sao từ các tác phẩm xuất sắc.',
            ),
            SizedBox(height: 6),
            Text(
              '🎨 Kỹ Thuật Vẽ: Pha màu, dựng hình khối, phác thảo tốc độ, vẽ & ghép tranh.',
            ),
            SizedBox(height: 6),
            Text(
              '👑 Đại Sứ Hội Họa: Danh hiệu cao quý nhất khi thu thập đủ 15 huy hiệu!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
