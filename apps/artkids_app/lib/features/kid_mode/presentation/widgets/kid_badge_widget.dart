import 'package:flutter/material.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../domain/entities/kid_reward.dart';

/// Huy hiệu / Badge hiển thị trong Kid Mode — icon to, màu sắc tươi
class KidBadgeWidget extends StatelessWidget {
  const KidBadgeWidget({
    super.key,
    this.title,
    this.iconName,
    this.isUnlocked = true,
    this.reward,
  });

  final String? title;
  final String? iconName;
  final bool isUnlocked;
  final KidReward? reward;

  @override
  Widget build(BuildContext context) {
    final displayTitle = reward?.title ?? title ?? 'Huy Hiệu';
    final displayIcon = reward?.iconName ?? iconName ?? 'military_tech';
    final unlocked = reward != null ? true : isUnlocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: KidUiConstants.largeTouchTarget,
          height: KidUiConstants.largeTouchTarget,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? KidUiConstants.secondaryKid : Colors.grey.shade300,
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: KidUiConstants.secondaryKid.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            _resolveIcon(displayIcon),
            size: 36,
            color: unlocked ? Colors.white : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: unlocked ? KidUiConstants.textKid : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  IconData _resolveIcon(String name) {
    return switch (name) {
      'star' => Icons.star,
      'brush' => Icons.brush,
      'pets' => Icons.pets,
      'palette' => Icons.palette,
      'trophy' => Icons.emoji_events,
      'fire' => Icons.local_fire_department,
      'diamond' => Icons.diamond,
      'rocket' => Icons.rocket_launch,
      _ => Icons.military_tech,
    };
  }
}
