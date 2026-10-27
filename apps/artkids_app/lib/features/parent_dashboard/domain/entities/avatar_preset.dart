import 'package:flutter/material.dart';

enum AvatarType { asset, icon }

class AvatarPreset {
  final String id;
  final String name;
  final String description;
  final bool isForChild;
  final AvatarType type;
  final String? assetPath;
  final IconData? icon;
  final Color primaryColor;
  final Color secondaryColor;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.isForChild,
    required this.type,
    this.assetPath,
    this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Danh sách avatar phụ huynh
  static const List<AvatarPreset> parentPresets = [
    AvatarPreset(
      id: 'parent_mom_art',
      name: 'Mẹ Yêu Nghệ Thuật',
      description: 'Dịu dàng và khích lệ bé sáng tạo',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.face_3_rounded,
      primaryColor: Color(0xFFFF758C),
      secondaryColor: Color(0xFFFF7EB3),
    ),
    AvatarPreset(
      id: 'parent_dad_art',
      name: 'Bố Đồng Hành',
      description: 'Cùng con khám phá thế giới màu sắc',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.face_6_rounded,
      primaryColor: Color(0xFF2980B9),
      secondaryColor: Color(0xFF6DD5FA),
    ),
    AvatarPreset(
      id: 'parent_palette',
      name: 'Phụ Huynh Sáng Tạo',
      description: 'Yêu thích hội họa và mỹ thuật',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.brush_rounded,
      primaryColor: Color(0xFF8E44AD),
      secondaryColor: Color(0xFFC39BD3),
    ),
    AvatarPreset(
      id: 'parent_guide',
      name: 'Mẹ Hướng Dẫn',
      description: 'Kiên nhẫn và đồng hành mỗi ngày',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.psychology_rounded,
      primaryColor: Color(0xFF00B894),
      secondaryColor: Color(0xFF55EFC4),
    ),
    AvatarPreset(
      id: 'parent_tech',
      name: 'Bố Công Nghệ & AI',
      description: 'Hướng dẫn bé làm quen AI an toàn',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.devices_other_rounded,
      primaryColor: Color(0xFF0984E3),
      secondaryColor: Color(0xFF74B9FF),
    ),
    AvatarPreset(
      id: 'parent_heart',
      name: 'Gia Đình Yêu Thương',
      description: 'Luôn lắng nghe và thấu hiểu bé',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.favorite_rounded,
      primaryColor: Color(0xFFE17055),
      secondaryColor: Color(0xFFFAB1A0),
    ),
    AvatarPreset(
      id: 'parent_star',
      name: 'Phụ Huynh Tận Tâm',
      description: 'Tự hào về từng nét vẽ của con',
      isForChild: false,
      type: AvatarType.icon,
      icon: Icons.stars_rounded,
      primaryColor: Color(0xFFF39C12),
      secondaryColor: Color(0xFFF1C40F),
    ),
    AvatarPreset(
      id: 'parent_artkids',
      name: 'Đại Gia Đình ArtKids',
      description: 'Huy hiệu cộng đồng ArtKids 3D',
      isForChild: false,
      type: AvatarType.asset,
      assetPath: 'assets/images/app_logo_3d.png',
      primaryColor: Color(0xFF1687A7),
      secondaryColor: Color(0xFF70C1B3),
    ),
  ];

  /// Danh sách avatar bé
  static const List<AvatarPreset> childPresets = [
    AvatarPreset(
      id: 'child_cat',
      name: 'Mèo Vàng Tinh Nghịch',
      description: 'Nhanh nhẹn và đáng yêu',
      isForChild: true,
      type: AvatarType.asset,
      assetPath: 'assets/images/matching_game/sticker_cat.png',
      primaryColor: Color(0xFFFFB300),
      secondaryColor: Color(0xFFFFE082),
    ),
    AvatarPreset(
      id: 'child_dog',
      name: 'Cún Nâu Thân Thiện',
      description: 'Trung thành và luôn vui vẻ',
      isForChild: true,
      type: AvatarType.asset,
      assetPath: 'assets/images/matching_game/sticker_dog.png',
      primaryColor: Color(0xFF8D6E63),
      secondaryColor: Color(0xFFD7CCC8),
    ),
    AvatarPreset(
      id: 'child_bird',
      name: 'Chim Xanh Líu Lo',
      description: 'Tự do bay lượn trên bầu trời sắc màu',
      isForChild: true,
      type: AvatarType.asset,
      assetPath: 'assets/images/matching_game/sticker_bird.png',
      primaryColor: Color(0xFF03A9F4),
      secondaryColor: Color(0xFFB3E5FC),
    ),
    AvatarPreset(
      id: 'child_artkids',
      name: 'Họa Sĩ Nhí ArtKids',
      description: 'Nhà sáng tạo nhí tí hon',
      isForChild: true,
      type: AvatarType.asset,
      assetPath: 'assets/images/app_logo_3d.png',
      primaryColor: Color(0xFF1687A7),
      secondaryColor: Color(0xFF70C1B3),
    ),
    AvatarPreset(
      id: 'child_rocket',
      name: 'Phi Hành Gia Nhí',
      description: 'Khám phá vũ trụ và công nghệ AI',
      isForChild: true,
      type: AvatarType.icon,
      icon: Icons.rocket_launch_rounded,
      primaryColor: Color(0xFF6C5CE7),
      secondaryColor: Color(0xFFA29BFE),
    ),
    AvatarPreset(
      id: 'child_paint',
      name: 'Bé Yêu Bảng Màu',
      description: 'Thích vẽ tranh và pha trộn màu sắc',
      isForChild: true,
      type: AvatarType.icon,
      icon: Icons.palette_rounded,
      primaryColor: Color(0xFFFF7675),
      secondaryColor: Color(0xFFFAB1A0),
    ),
    AvatarPreset(
      id: 'child_dino',
      name: 'Khủng Long Tí Hon',
      description: 'Mạnh mẽ và ham học hỏi',
      isForChild: true,
      type: AvatarType.icon,
      icon: Icons.cruelty_free_rounded,
      primaryColor: Color(0xFF00B894),
      secondaryColor: Color(0xFF55EFC4),
    ),
    AvatarPreset(
      id: 'child_magic',
      name: 'Kỳ Lân Phép Thuật',
      description: 'Thế giới cổ tích diệu kỳ',
      isForChild: true,
      type: AvatarType.icon,
      icon: Icons.auto_awesome_rounded,
      primaryColor: Color(0xFF9B59B6),
      secondaryColor: Color(0xFFE8DAEF),
    ),
  ];

  static AvatarPreset findById(String id, {bool isChild = false}) {
    final list = isChild ? childPresets : parentPresets;
    final otherList = isChild ? parentPresets : childPresets;

    for (final preset in list) {
      if (preset.id == id) return preset;
    }
    for (final preset in otherList) {
      if (preset.id == id) return preset;
    }

    return isChild ? childPresets.first : parentPresets.first;
  }
}
