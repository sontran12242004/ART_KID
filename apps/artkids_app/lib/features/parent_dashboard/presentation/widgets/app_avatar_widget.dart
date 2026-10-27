import 'package:flutter/material.dart';

import '../../domain/entities/avatar_preset.dart';

/// Widget hiển thị Avatar đa năng cho phụ huynh & trẻ em với hiệu ứng bo tròn, viền gradient và icon chỉnh sửa
class AppAvatarWidget extends StatelessWidget {
  final String avatarId;
  final bool isChild;
  final double radius;
  final bool showEditBadge;
  final IconData? editBadgeIcon;
  final VoidCallback? onTap;

  const AppAvatarWidget({
    super.key,
    required this.avatarId,
    this.isChild = false,
    this.radius = 36,
    this.showEditBadge = false,
    this.editBadgeIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preset = AvatarPreset.findById(avatarId, isChild: isChild);
    final size = radius * 2;

    Widget avatarContent;
    if (preset.type == AvatarType.asset && preset.assetPath != null) {
      avatarContent = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(radius * 0.18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              preset.secondaryColor.withValues(alpha: 0.55),
              Colors.white,
            ],
          ),
        ),
        child: Image.asset(preset.assetPath!, fit: BoxFit.contain),
      );
    } else {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [preset.primaryColor, preset.secondaryColor],
          ),
        ),
        child: Center(
          child: Icon(
            preset.icon ?? Icons.person_rounded,
            color: Colors.white,
            size: radius * 1.05,
          ),
        ),
      );
    }

    final avatarWithFrame = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: radius > 30 ? 3.5 : 2.5),
        boxShadow: [
          BoxShadow(
            color: preset.primaryColor.withValues(alpha: 0.28),
            blurRadius: radius * 0.45,
            offset: Offset(0, radius * 0.18),
          ),
        ],
      ),
      child: ClipOval(child: avatarContent),
    );

    if (!showEditBadge && onTap == null) {
      return avatarWithFrame;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarWithFrame,
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(radius * 0.18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1687A7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  editBadgeIcon ?? Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: radius * 0.42,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
