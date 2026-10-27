import 'package:flutter/material.dart';

import '../../domain/entities/achievement_badge.dart';
import 'badge_3d_viewer_widget.dart';

/// Card huy hiệu dạng 3D medal hiển thị trong lưới huy hiệu của bé
class BadgeCardWidget extends StatelessWidget {
  final AchievementBadge badge;
  final VoidCallback onTap;

  const BadgeCardWidget({super.key, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: badge.isUnlocked
                ? badge.primaryColor.withValues(alpha: 0.5)
                : const Color(0xFFE2EFEF),
            width: badge.isUnlocked ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: badge.isUnlocked
                  ? badge.primaryColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header card: Số thứ tự + Tag trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badge.isUnlocked
                        ? badge.primaryColor.withValues(alpha: 0.14)
                        : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${badge.order}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badge.isUnlocked
                          ? badge.primaryColor
                          : const Color(0xFF78909C),
                    ),
                  ),
                ),
                if (badge.isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32),
                          size: 12,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Đã Đạt',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFB0BEC5),
                    size: 16,
                  ),
              ],
            ),

            // Icon/Emoji huy hiệu trung tâm dạng 3D (hoặc Model 3D GLB xoay tròn)
            if (badge.modelGlbPath != null)
              Badge3DViewerWidget(
                modelGlbPath: badge.modelGlbPath!,
                size: 68,
                isCompact: true,
                glowColor: badge.primaryColor,
                title: badge.title,
                fallbackIcon: badge.icon,
                emoji: badge.emoji,
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng hào quang sáng nếu đã mở khóa
                  if (badge.isUnlocked)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badge.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                  // Vòng huy hiệu chính
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: badge.isUnlocked
                            ? [badge.primaryColor, badge.secondaryColor]
                            : [
                                const Color(0xFFECEFF1),
                                const Color(0xFFCFD8DC),
                              ],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (badge.isUnlocked
                                      ? badge.primaryColor
                                      : Colors.black)
                                  .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        badge.emoji,
                        style: TextStyle(
                          fontSize: 32,
                          color: badge.isUnlocked ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Tên Huy Hiệu
            Column(
              children: [
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: badge.isUnlocked
                        ? const Color(0xFF0F3B46)
                        : const Color(0xFF78909C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.condition,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: badge.isUnlocked
                        ? const Color(0xFF556E74)
                        : const Color(0xFF90A4AE),
                    height: 1.2,
                  ),
                ),
              ],
            ),

            // Thanh tiến trình
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: badge.progressRatio,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFECEFF1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      badge.isUnlocked
                          ? const Color(0xFF00B894)
                          : badge.primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  badge.isUnlocked
                      ? 'Hoàn thành'
                      : '${badge.currentProgress}/${badge.maxProgress}',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: badge.isUnlocked
                        ? const Color(0xFF00B894)
                        : const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
