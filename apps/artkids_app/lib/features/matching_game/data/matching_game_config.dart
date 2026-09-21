import '../domain/animal.dart';
import '../domain/picture_set.dart';

/// Cấu hình tọa độ % của một ô hình bóng gỗ trên bức tranh nền
class SlotConfig {
  final Animal animal;

  /// Tọa độ cạnh trái tính theo tỉ lệ chiều rộng ảnh (0.0 -> 1.0)
  final double leftPercent;

  /// Tọa độ cạnh trên tính theo tỉ lệ chiều cao ảnh (0.0 -> 1.0)
  final double topPercent;

  /// Chiều rộng khung hình bóng gỗ tính theo tỉ lệ chiều rộng ảnh (0.0 -> 1.0)
  final double widthPercent;

  /// Chiều cao khung hình bóng gỗ tính theo tỉ lệ chiều cao ảnh (0.0 -> 1.0)
  final double heightPercent;

  const SlotConfig({
    required this.animal,
    required this.leftPercent,
    required this.topPercent,
    required this.widthPercent,
    required this.heightPercent,
  });

  /// Đường dẫn asset sticker tương ứng
  String get stickerAssetPath => animal.stickerAssetPath;
}

/// Bảng cấu hình trò chơi ghép tranh con vật ArtKids
class MatchingGameConfig {
  MatchingGameConfig._();

  /// Đường dẫn các âm thanh hiệu ứng
  static const String audioPop = 'assets/audio/pop.wav';
  static const String audioSuccess = 'assets/audio/success_chime.wav';
  static const String audioCelebration = 'assets/audio/celebration.wav';

  /// Danh sách các bộ tranh có thể chọn chơi
  static const List<PictureSet> pictureSets = [
    PictureSet(
      id: 'living_room',
      title: 'Phòng Khách Ấm Cúng',
      description: 'Vẽ và ghép 3 bạn mèo, cún và chim nhỏ vào phòng khách',
      thumbnailAsset: 'assets/images/matching_game/living_room_bg.png',
      backgroundAsset: 'assets/images/matching_game/living_room_bg.png',
      bgAspectRatio: 1024.0 / 562.0,
      slots: [
        // 1. Mèo con nằm bên trái sàn/thảm
        SlotConfig(
          animal: Animal.cat,
          leftPercent: 0.3770,
          topPercent: 0.7544,
          widthPercent: 0.1230,
          heightPercent: 0.2384,
        ),

        // 2. Chó beagle nằm trên thảm đỏ giữa phòng
        SlotConfig(
          animal: Animal.dog,
          leftPercent: 0.5332,
          topPercent: 0.7028,
          widthPercent: 0.1836,
          heightPercent: 0.2331,
        ),

        // 3. Chú chim đậu trên bậu cửa/kệ bên phải
        SlotConfig(
          animal: Animal.bird,
          leftPercent: 0.7734,
          topPercent: 0.6975,
          widthPercent: 0.1777,
          heightPercent: 0.2598,
        ),
      ],
    ),
  ];

  /// Lấy bộ tranh theo `id`, nếu không tìm thấy sẽ trả về bộ tranh đầu tiên
  static PictureSet getPictureSet(String id) {
    return pictureSets.firstWhere(
      (set) => set.id == id,
      orElse: () => pictureSets.first,
    );
  }

  // Tương thích ngược với các widget hiện có
  static String get livingRoomBgPath => pictureSets.first.backgroundAsset;
  static double get bgAspectRatio => pictureSets.first.bgAspectRatio;
  static List<SlotConfig> get slots => pictureSets.first.slots;

  static SlotConfig slotFor(Animal animal) {
    return slots.firstWhere((s) => s.animal == animal);
  }
}
