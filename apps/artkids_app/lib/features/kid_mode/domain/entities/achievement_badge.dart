import 'package:flutter/material.dart';

enum BadgeCategory {
  habit('Thói Quen Vẽ', Icons.alarm_on_rounded, Color(0xFF4ECDC4)),
  achievement(
    'Thành Tích Cọ Vẽ',
    Icons.military_tech_rounded,
    Color(0xFFFFB800),
  ),
  skill('Kỹ Thuật Vẽ', Icons.brush_rounded, Color(0xFF6C5CE7)),
  special('Đại Sứ Hội Họa', Icons.workspace_premium_rounded, Color(0xFFFF6B6B));

  final String label;
  final IconData icon;
  final Color color;
  const BadgeCategory(this.label, this.icon, this.color);
}

/// Model dữ liệu 20 Huy Hiệu Thành Tích chuẩn hóa 100% chuyên sâu về Hội Họa & Vẽ Tranh ArtKids
class AchievementBadge {
  final int order;
  final String id;
  final String title;
  final String emoji;
  final IconData icon;
  final String condition;
  final String meaning;
  final BadgeCategory category;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isUnlocked;
  final int currentProgress;
  final int maxProgress;
  final DateTime? unlockedAt;
  final String? modelGlbPath;

  const AchievementBadge({
    required this.order,
    required this.id,
    required this.title,
    required this.emoji,
    required this.icon,
    required this.condition,
    required this.meaning,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.maxProgress = 1,
    this.unlockedAt,
    this.modelGlbPath,
  });

  double get progressRatio =>
      maxProgress > 0 ? (currentProgress / maxProgress).clamp(0.0, 1.0) : 0.0;

  AchievementBadge copyWith({
    bool? isUnlocked,
    int? currentProgress,
    DateTime? unlockedAt,
    String? modelGlbPath,
  }) {
    return AchievementBadge(
      order: order,
      id: id,
      title: title,
      emoji: emoji,
      icon: icon,
      condition: condition,
      meaning: meaning,
      category: category,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      maxProgress: maxProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      modelGlbPath: modelGlbPath ?? this.modelGlbPath,
    );
  }

  /// Danh sách 20 Huy Hiệu chuẩn hóa 100% về Vẽ Tranh & Nghệ Thuật của ArtKids
  static const List<AchievementBadge> all20Badges = [
    // 1. Mầm Non Khởi Đầu (Có Model 3D GLB mầm cây xoay vòng tròn)
    AchievementBadge(
      order: 1,
      id: 'badge_1_seed',
      title: 'Mầm Non Khởi Đầu',
      emoji: '🌱',
      icon: Icons.spa_rounded,
      condition: 'Hoàn thành bài học vẽ hoặc tác phẩm tranh đầu tiên',
      meaning: 'Khen ngợi nét cọ khởi đầu đầy tự tin của bé',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFF2ECC71),
      secondaryColor: Color(0xFFA8E6CF),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
      modelGlbPath: 'assets/models/Mamnonkhoidau.glb',
    ),

    // 2. Ngôi Sao Chăm Chỉ (Có Model 3D GLB xoay vòng tròn)
    AchievementBadge(
      order: 2,
      id: 'badge_2_star_streak',
      title: 'Ngôi Sao Chăm Chỉ',
      emoji: '⭐',
      icon: Icons.star_rounded,
      condition: 'Đăng nhập và hoàn thành ít nhất 1 bức tranh 3 ngày liên tiếp',
      meaning: 'Tạo thói quen cầm cọ và luyện vẽ mỗi ngày',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFFF1C40F),
      secondaryColor: Color(0xFFFFEAA7),
      isUnlocked: true,
      currentProgress: 3,
      maxProgress: 3,
      modelGlbPath: 'assets/models/Ngoisaochamchi.glb',
    ),

    // 3. Chiến Binh Bền Bỉ
    AchievementBadge(
      order: 3,
      id: 'badge_3_warrior',
      title: 'Chiến Binh Bền Bỉ',
      emoji: '🔥',
      icon: Icons.local_fire_department_rounded,
      condition: 'Duy trì chuỗi ngày vẽ tranh liên tục trong 7 ngày',
      meaning: 'Giữ vững ngọn lửa đam mê và kiên trì sáng tạo hội họa',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFFE67E22),
      secondaryColor: Color(0xFFFAB1A0),
      isUnlocked: true,
      currentProgress: 7,
      maxProgress: 7,
    ),

    // 4. Bậc Thầy Kiên Trì
    AchievementBadge(
      order: 4,
      id: 'badge_4_master_patience',
      title: 'Bậc Thầy Kiên Trì',
      emoji: '🏆',
      icon: Icons.emoji_events_rounded,
      condition: 'Hoàn thành chuỗi 30 ngày vẽ tranh sáng tạo không gián đoạn',
      meaning: 'Rèn luyện tính kỷ luật và phong cách họa sĩ chuyên nghiệp',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFFCD7F32),
      secondaryColor: Color(0xFFE0A96D),
      isUnlocked: false,
      currentProgress: 12,
      maxProgress: 30,
    ),

    // 5. Nét Vẽ Hoàn Hảo
    AchievementBadge(
      order: 5,
      id: 'badge_5_perfect_score',
      title: 'Nét Vẽ Hoàn Hảo',
      emoji: '💯',
      icon: Icons.verified_rounded,
      condition:
          'Đạt điểm đánh giá tuyệt đối 100% trong một thử thách nét vẽ & phối màu',
      meaning: 'Khuyến khích sự tỉ mỉ và độ chuẩn xác của nét vẽ',
      category: BadgeCategory.achievement,
      primaryColor: Color(0xFFE74C3C),
      secondaryColor: Color(0xFFFF7675),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
    ),

    // 6. Siêu Sao Tích Lũy
    AchievementBadge(
      order: 6,
      id: 'badge_6_accumulate_star',
      title: 'Siêu Sao Tích Lũy',
      emoji: '🌟',
      icon: Icons.stars_rounded,
      condition: 'Tích lũy đạt mốc 100 Ngôi sao từ các tác phẩm tranh vẽ',
      meaning: 'Cột mốc điểm thưởng ghi nhận năng khiếu hội họa',
      category: BadgeCategory.achievement,
      primaryColor: Color(0xFFFFB300),
      secondaryColor: Color(0xFFFFD54F),
      isUnlocked: true,
      currentProgress: 100,
      maxProgress: 100,
    ),

    // 7. Kho Báu Sắc Màu (Có Model 3D GLB rương kho báu màu sắc xoay vòng tròn)
    AchievementBadge(
      order: 7,
      id: 'badge_7_treasure',
      title: 'Kho Báu Sắc Màu',
      emoji: '🎨',
      icon: Icons.palette_rounded,
      condition: 'Tích lũy đạt mốc 500 Ngôi sao từ các bộ sưu tập tranh',
      meaning: 'Bộ sưu tập ngôi sao danh giá của họa sĩ tài năng',
      category: BadgeCategory.achievement,
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFFFFF176),
      isUnlocked: true,
      currentProgress: 500,
      maxProgress: 500,
      modelGlbPath: 'assets/models/Khobausacmau.glb',
    ),

    // 8. Tốc Họa Tài Ba
    AchievementBadge(
      order: 8,
      id: 'badge_8_speed',
      title: 'Tốc Họa Tài Ba',
      emoji: '⚡',
      icon: Icons.bolt_rounded,
      condition:
          'Hoàn thành bức tranh phác thảo tốc độ dưới thời gian quy định với điểm tối đa',
      meaning: 'Rèn luyện phản xạ nét vẽ nhanh, tự tin và dứt khoát',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFFF39C12),
      secondaryColor: Color(0xFFFFE082),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
    ),

    // 9. Cú Đêm Hội Họa (Có Model 3D GLB cú đêm xoay vòng tròn)
    AchievementBadge(
      order: 9,
      id: 'badge_9_night_owl',
      title: 'Cú Đêm Hội Họa',
      emoji: '🦉',
      icon: Icons.nights_stay_rounded,
      condition: 'Hoàn thành một bức tranh vào khung giờ tối (19h - 20h30)',
      meaning: 'Thói quen thư giãn cùng sắc màu và nghệ thuật trước giờ ngủ',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFF3F51B5),
      secondaryColor: Color(0xFF9FA8DA),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
      modelGlbPath: 'assets/models/Cudemhoihoa.glb',
    ),

    // 10. Họa Sĩ Sớm Mai (Có Model 3D GLB chú ong họa sĩ xoay vòng tròn)
    AchievementBadge(
      order: 10,
      id: 'badge_10_morning_bee',
      title: 'Họa Sĩ Sớm Mai',
      emoji: '🐝',
      icon: Icons.wb_sunny_rounded,
      condition:
          'Hoàn thành một bức vẽ vào buổi sáng cuối tuần (trước 9h sáng)',
      meaning:
          'Khởi đầu ngày mới tràn đầy năng lượng cùng nguồn cảm hứng vẽ tranh',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFFFCC80),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
      modelGlbPath: 'assets/models/Hoasisommai.glb',
    ),

    // 11. Phù Thủy Pha Màu (Có Model 3D GLB vạc pha màu ma thuật xoay vòng tròn)
    AchievementBadge(
      order: 11,
      id: 'badge_11_color_wizard',
      title: 'Phù Thủy Pha Màu',
      emoji: '🌈',
      icon: Icons.gradient_rounded,
      condition:
          'Hoàn thành 10 bài học về phối màu, sắc độ và pha màu tương phản',
      meaning: 'Nắm vững kỹ năng cảm thụ màu sắc và phối màu nghệ thuật',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFF00ACC1),
      secondaryColor: Color(0xFF80DEEA),
      isUnlocked: true,
      currentProgress: 10,
      maxProgress: 10,
      modelGlbPath: 'assets/models/Phuthuyphamau.glb',
    ),

    // 12. Bậc Thầy Hình Khối (Sửa chuẩn chủ đề vẽ thay cho Chữ số)
    AchievementBadge(
      order: 12,
      id: 'badge_12_shape_master',
      title: 'Bậc Thầy Hình Khối',
      emoji: '🔷',
      icon: Icons.category_rounded,
      condition:
          'Hoàn thành 10 bài tập dựng hình khối cơ bản (tròn, vuông, khối 3D)',
      meaning: 'Xây dựng nền tảng tạo hình và dựng bố cục tranh vẽ vững chắc',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFF43A047),
      secondaryColor: Color(0xFFA5D6A7),
      isUnlocked: false,
      currentProgress: 4,
      maxProgress: 10,
    ),

    // 13. Khám Phá Thiên Hà Tranh (Có Model 3D GLB tên lửa vũ trụ xoay vòng tròn)
    AchievementBadge(
      order: 13,
      id: 'badge_13_space_explorer',
      title: 'Khám Phá Thiên Hà Tranh',
      emoji: '🚀',
      icon: Icons.rocket_launch_rounded,
      condition: 'Mở khóa toàn bộ các bài vẽ trong một chương/chủ đề hội họa',
      meaning: 'Thúc đẩy hoàn thành trọn vẹn lộ trình học vẽ bài bản',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFF8E24AA),
      secondaryColor: Color(0xFFCE93D8),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
      modelGlbPath: 'assets/models/Khamphathienhatranh.glb',
    ),

    // 14. Không Ngại Thử Thách (Có Model 3D GLB khiên dũng cảm xoay vòng tròn)
    AchievementBadge(
      order: 14,
      id: 'badge_14_brave_shield',
      title: 'Không Ngại Thử Thách',
      emoji: '🛡️',
      icon: Icons.shield_rounded,
      condition:
          'Vượt qua bài vẽ thử thách ở cấp độ Khó (nhiều chi tiết & phối cảnh)',
      meaning: 'Dạy bé tự tin, không sợ các bức tranh phức tạp',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFF455A64),
      secondaryColor: Color(0xFF90A4AE),
      isUnlocked: true,
      currentProgress: 1,
      maxProgress: 1,
      modelGlbPath: 'assets/models/Khongngaithuthach.glb',
    ),

    // 15. Bàn Tay Khéo Léo (Có Model 3D GLB bàn tay nghệ thuật xoay vòng tròn)
    AchievementBadge(
      order: 15,
      id: 'badge_15_crafty_hands',
      title: 'Bàn Tay Khéo Léo',
      emoji: '🖌️',
      icon: Icons.brush_rounded,
      condition:
          'Hoàn thành tất cả các bài tập vẽ nét tự do và ghép tranh kéo-thả',
      meaning: 'Rèn luyện kỹ năng vận động tinh và sự khéo léo của đôi tay',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFFEC407A),
      secondaryColor: Color(0xFFF48FB1),
      isUnlocked: true,
      currentProgress: 5,
      maxProgress: 5,
      modelGlbPath: 'assets/models/Bantaykheoleo.glb',
    ),

    // 16. Dũng Cảm Phối Lại
    AchievementBadge(
      order: 16,
      id: 'badge_16_brave_fix',
      title: 'Dũng Cảm Phối Lại',
      emoji: '🔄',
      icon: Icons.change_circle_rounded,
      condition:
          'Vẽ lại hoặc tô màu lại bức tranh chưa ưng ý để đạt điểm tuyệt đối ở lần sau',
      meaning:
          'Tinh thần kiên trì, học hỏi từ nét vẽ cũ và hoàn thiện tác phẩm',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFF00B0FF),
      secondaryColor: Color(0xFF80D8FF),
      isUnlocked: false,
      currentProgress: 0,
      maxProgress: 1,
    ),

    // 17. Nhà Thám Hiểm Phong Cách (Có Model 3D GLB thám hiểm phong cách xoay vòng tròn)
    AchievementBadge(
      order: 17,
      id: 'badge_17_navigator',
      title: 'Nhà Thám Hiểm Phong Cách',
      emoji: '🧭',
      icon: Icons.explore_rounded,
      condition:
          'Dùng thử ít nhất 5 chất liệu & phong cách vẽ khác nhau trên app (Màu nước, Chì, Sơn dầu, Pixel, AI)',
      meaning:
          'Khuyến khích khám phá đa dạng phong cách hội họa và công nghệ AI',
      category: BadgeCategory.skill,
      primaryColor: Color(0xFF8D6E63),
      secondaryColor: Color(0xFFBCAAA4),
      isUnlocked: true,
      currentProgress: 5,
      maxProgress: 5,
      modelGlbPath: 'assets/models/Nhathamhiemphongcach.glb',
    ),

    // 18. Chuyên Cần Cuối Tuần
    AchievementBadge(
      order: 18,
      id: 'badge_18_weekend_champ',
      title: 'Chuyên Cần Cuối Tuần',
      emoji: '🎈',
      icon: Icons.celebration_rounded,
      condition: 'Hoàn thành tác phẩm tranh vẽ trong cả Thứ 7 và Chủ Nhật',
      meaning: 'Duy trì niềm say mê sáng tác tranh vẽ vào dịp cuối tuần',
      category: BadgeCategory.habit,
      primaryColor: Color(0xFFFF5252),
      secondaryColor: Color(0xFFFF8A80),
      isUnlocked: false,
      currentProgress: 1,
      maxProgress: 2,
    ),

    // 19. Tái Hiện Siêu Phàm
    AchievementBadge(
      order: 19,
      id: 'badge_19_super_memory',
      title: 'Tái Hiện Siêu Phàm',
      emoji: '🧠',
      icon: Icons.psychology_rounded,
      condition:
          'Hoàn thành bài vẽ ký họa từ trí nhớ đạt điểm tuyệt đối mà không cần nhìn tranh mẫu',
      meaning:
          'Khuyến khích khả năng ghi nhớ hình ảnh và tư duy không gian thị giác',
      category: BadgeCategory.achievement,
      primaryColor: Color(0xFF7C4DFF),
      secondaryColor: Color(0xFFB388FF),
      isUnlocked: false,
      currentProgress: 0,
      maxProgress: 1,
    ),

    // 20. Đại Sứ Hội Họa Toàn Năng (Có Model 3D GLB vương miện đại sứ hoàng gia xoay vòng tròn)
    AchievementBadge(
      order: 20,
      id: 'badge_20_grandmaster',
      title: 'Đại Sứ Hội Họa Toàn Năng',
      emoji: '👑',
      icon: Icons.workspace_premium_rounded,
      condition: 'Thu thập đủ 15 huy hiệu hội họa bất kỳ khác trong danh sách',
      meaning: 'Danh hiệu nghệ thuật danh giá nhất hệ thống ArtKids',
      category: BadgeCategory.special,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFFE57F),
      isUnlocked: true,
      currentProgress: 15,
      maxProgress: 15,
      modelGlbPath: 'assets/models/Daisuhoihoatoannang.glb',
    ),
  ];
}
