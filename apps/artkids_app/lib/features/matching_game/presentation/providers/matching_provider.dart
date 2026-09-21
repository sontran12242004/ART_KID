import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/matching_game_config.dart';
import '../../domain/animal.dart';
import '../../domain/game_state.dart';

/// StateNotifier quản lý trạng thái ghép tranh kéo-thả
class MatchingNotifier extends StateNotifier<MatchingGameState> {
  MatchingNotifier() : super(const MatchingGameState());

  /// Khởi tạo hoặc khôi phục trạng thái ghép tranh cho một bộ tranh
  void initialize(String pictureSetId, {List<Animal>? restoredMatches}) {
    final pictureSet = MatchingGameConfig.getPictureSet(pictureSetId);
    final targets = pictureSet.slots.map((s) => s.animal).toList();

    state = MatchingGameState(
      pictureSetId: pictureSetId,
      targets: targets,
      matchedAnimals: restoredMatches != null ? Set.from(restoredMatches) : const {},
      lastMatchedAnimal: null,
    );
  }

  /// Xử lý khi bé thả đúng con vật vào ô bóng gỗ tương ứng
  bool matchAnimal(Animal animal) {
    if (state.matchedAnimals.contains(animal)) {
      return false; // Đã ghép trước đó
    }

    final updated = Set<Animal>.from(state.matchedAnimals)..add(animal);
    state = state.copyWith(
      matchedAnimals: updated,
      lastMatchedAnimal: animal,
    );
    return true;
  }

  /// Đặt lại trạng thái màn hình ghép tranh khi bé bấm "Chơi lại"
  void reset() {
    state = MatchingGameState(
      pictureSetId: state.pictureSetId,
      targets: state.targets,
      matchedAnimals: const {},
      lastMatchedAnimal: null,
    );
  }
}

/// Provider cung cấp trạng thái ghép tranh
final matchingProvider =
    StateNotifierProvider<MatchingNotifier, MatchingGameState>((ref) {
  return MatchingNotifier();
});
