import '../data/matching_game_config.dart';

/// Mô hình thông tin một bộ tranh trong trò chơi ghép tranh con vật
class PictureSet {
  /// Mã định danh duy nhất của bộ tranh (ví dụ: 'living_room')
  final String id;

  /// Tên hiển thị thân thiện (ví dụ: "Phòng khách ấm cúng")
  final String title;

  /// Mô tả ngắn cho bé
  final String description;

  /// Đường dẫn ảnh đại diện nhỏ hiển thị trên card chọn tranh
  final String thumbnailAsset;

  /// Đường dẫn ảnh nền đầy đủ hiển thị ở màn hình ghép tranh
  final String backgroundAsset;

  /// Tỉ lệ khung hình (width / height) của ảnh nền gốc
  final double bgAspectRatio;

  /// Danh sách các vùng hình bóng gỗ cần ghép con vật
  final List<SlotConfig> slots;

  const PictureSet({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailAsset,
    required this.backgroundAsset,
    this.bgAspectRatio = 1024.0 / 562.0,
    required this.slots,
  });

  /// Tổng số con vật cần ghép trong bộ tranh này
  int get totalAnimals => slots.length;
}
