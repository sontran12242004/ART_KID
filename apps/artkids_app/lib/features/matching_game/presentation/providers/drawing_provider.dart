import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/matching_game_config.dart';
import '../../domain/animal.dart';
import '../../domain/game_state.dart';
import '../../domain/matching_game_progress.dart';

/// StateNotifier quản lý tiến trình vẽ các con vật của bé
class DrawingNotifier extends StateNotifier<DrawingProgressState> {
  DrawingNotifier() : super(const DrawingProgressState());

  /// Khởi tạo hoặc khôi phục tiến trình vẽ cho một bộ tranh
  void initialize(String pictureSetId, {MatchingGameProgress? resumeProgress}) {
    final pictureSet = MatchingGameConfig.getPictureSet(pictureSetId);
    final sequence = pictureSet.slots.map((s) => s.animal).toList();

    if (resumeProgress != null) {
      state = DrawingProgressState(
        pictureSetId: pictureSetId,
        sequence: sequence,
        currentAnimalIndex: resumeProgress.currentAnimalIndex,
        unlockedStickers: resumeProgress.unlockedStickers,
      );
    } else {
      state = DrawingProgressState(
        pictureSetId: pictureSetId,
        sequence: sequence,
        currentAnimalIndex: 0,
        unlockedStickers: const [],
      );
    }
  }

  /// Bé hoàn thành bài vẽ con vật hiện tại:
  /// - Thêm sticker vào danh sách unlocked
  /// - Trả về con vật vừa hoàn thành để kích hoạt hiệu ứng thưởng
  Animal completeCurrentAnimal() {
    final animal = state.currentAnimal;
    final updatedUnlocked = List<Animal>.from(state.unlockedStickers);
    if (!updatedUnlocked.contains(animal)) {
      updatedUnlocked.add(animal);
    }

    state = state.copyWith(
      unlockedStickers: updatedUnlocked,
    );
    return animal;
  }

  /// Chuyển sang con vật tiếp theo (nếu còn)
  void advanceToNextAnimal() {
    if (state.currentAnimalIndex < state.totalAnimals - 1) {
      state = state.copyWith(
        currentAnimalIndex: state.currentAnimalIndex + 1,
      );
    }
  }

  /// Đặt lại toàn bộ tiến trình khi bé bấm "Chơi lại"
  void reset() {
    state = DrawingProgressState(
      pictureSetId: state.pictureSetId,
      sequence: state.sequence,
      currentAnimalIndex: 0,
      unlockedStickers: const [],
    );
  }
}

/// Provider cung cấp trạng thái tiến trình vẽ của bé
final drawingProvider =
    StateNotifierProvider<DrawingNotifier, DrawingProgressState>((ref) {
  return DrawingNotifier();
});
