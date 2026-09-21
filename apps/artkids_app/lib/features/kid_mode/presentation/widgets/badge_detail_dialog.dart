import 'package:flutter/material.dart';

import '../../domain/entities/achievement_badge.dart';
import 'badge_3d_viewer_widget.dart';

/// Hộp thoại hiển thị chi tiết 1 trong 20 Huy Hiệu ArtKids
class BadgeDetailDialog extends StatelessWidget {
  final AchievementBadge badge;
  final VoidCallback? onUnlockDemo;

  const BadgeDetailDialog({
    super.key,
    required this.badge,
    this.onUnlockDemo,
  });

  static void show(
    BuildContext context, {
    required AchievementBadge badge,
    VoidCallback? onUnlockDemo,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => BadgeDetailDialog(
        badge: badge,
        onUnlockDemo: onUnlockDemo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Nội dung card chính
          Container(
            margin: const EdgeInsets.only(top: 48),
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: badge.isUnlocked
                    ? badge.primaryColor.withValues(alpha: 0.6)
                    : const Color(0xFFE2EFEF),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.isUnlocked
                      ? badge.primaryColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Số thứ tự & Phân loại
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Huy Hiệu #${badge.order}',
                        style: TextStyle(
                          color: badge.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge.category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge.category.label,
                        style: TextStyle(
                          color: badge.category.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tên Huy Hiệu
                Text(
                  '${badge.emoji} ${badge.title}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F3B46),
                  ),
                ),
                const SizedBox(height: 6),

                // Nhãn 3D xoay vòng tròn nếu có model GLB
                if (badge.modelGlbPath != null) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.threed_rotation_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Model 3D ${badge.title} (Xoay 360°)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Trạng thái đã đạt / chưa đạt
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.isUnlocked
                          ? '✨ Đã Mở Khóa Thành Công'
                          : '🔒 Đang Trong Tiến Trình',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badge.isUnlocked
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF546E7A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Khung Điều Kiện Đạt Được
                _buildInfoBox(
                  icon: Icons.flag_rounded,
                  iconColor: const Color(0xFF1687A7),
                  title: 'Điều Kiện Đạt Được',
                  content: badge.condition,
                  bgColor: const Color(0xFFF1F8F9),
                  borderColor: const Color(0xFF70C1B3).withValues(alpha: 0.6),
                ),

                const SizedBox(height: 10),

                // Khung Ý Nghĩa / Mục Đích
                _buildInfoBox(
                  icon: Icons.lightbulb_rounded,
                  iconColor: const Color(0xFFF39C12),
                  title: 'Ý Nghĩa & Mục Đích',
                  content: badge.meaning,
                  bgColor: const Color(0xFFFFFDF5),
                  borderColor: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                ),

                const SizedBox(height: 16),

                // Tiến trình
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tiến Độ Hoàn Thành',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF33555D),
                          ),
                        ),
                        Text(
                          badge.isUnlocked
                              ? '${badge.maxProgress}/${badge.maxProgress} (100%)'
                              : '${badge.currentProgress}/${badge.maxProgress}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: badge.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: badge.progressRatio,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFECEFF1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          badge.isUnlocked
                              ? const Color(0xFF00B894)
                              : badge.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Hàng nút bấm
                Row(
                  children: [
                    if (!badge.isUnlocked && onUnlockDemo != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1687A7),
                            side: const BorderSide(
                              color: Color(0xFF1687A7),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.lock_open_rounded, size: 18),
                          label: const Text(
                            'Mở Khóa Thử',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onUnlockDemo!();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: badge.isUnlocked
                              ? const Color(0xFF1A52A8)
                              : const Color(0xFF556E74),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 3,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          badge.isUnlocked ? 'Tuyệt Vời! 🌟' : 'Đã Hiểu',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vòng tròn Icon huy hiệu nổi trên cùng (hoặc Model 3D GLB xoay tròn)
          Positioned(
            top: 0,
            child: badge.modelGlbPath != null
                ? Badge3DViewerWidget(
                    modelGlbPath: badge.modelGlbPath!,
                    size: 104,
                    isCompact: false,
                    interactive: true,
                    glowColor: badge.primaryColor,
                    title: badge.title,
                    fallbackIcon: badge.icon,
                    emoji: badge.emoji,
                  )
                : Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: badge.isUnlocked
                            ? [badge.primaryColor, badge.secondaryColor]
                            : [const Color(0xFF90A4AE), const Color(0xFFCFD8DC)],
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 4.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (badge.isUnlocked
                                  ? badge.primaryColor
                                  : Colors.black)
                              .withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        badge.emoji,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
