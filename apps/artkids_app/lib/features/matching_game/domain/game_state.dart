import 'package:equatable/equatable.dart';
import 'animal.dart';

/// Trạng thái của tiến trình vẽ các con vật trong một bộ tranh
class DrawingProgressState extends Equatable {
  /// Thứ tự mặc định: Mèo -> Chó -> Chim
  static const List<Animal> defaultSequence = [
    Animal.cat,
    Animal.dog,
    Animal.bird,
  ];

  /// Mã bộ tranh đang vẽ
  final String pictureSetId;

  /// Danh sách con vật theo thứ tự vẽ của bộ tranh
  final List<Animal> sequence;

  /// Thứ tự con vật hiện tại đang vẽ (0 -> sequence.length - 1)
  final int currentAnimalIndex;

  /// Danh sách các con vật bé đã vẽ xong và mở khóa sticker
  final List<Animal> unlockedStickers;

  const DrawingProgressState({
    this.pictureSetId = 'living_room',
    this.sequence = defaultSequence,
    this.currentAnimalIndex = 0,
    this.unlockedStickers = const [],
  });

  /// Con vật hiện tại bé đang vẽ
  Animal get currentAnimal =>
      sequence[currentAnimalIndex.clamp(0, sequence.length - 1)];

  /// Tổng số con vật cần vẽ trong bộ tranh
  int get totalAnimals => sequence.length;

  /// Kiểm tra bé đã hoàn thành vẽ tất cả con vật hay chưa
  bool get isAllDrawn => unlockedStickers.length >= sequence.length;

  DrawingProgressState copyWith({
    String? pictureSetId,
    List<Animal>? sequence,
    int? currentAnimalIndex,
    List<Animal>? unlockedStickers,
  }) {
    return DrawingProgressState(
      pictureSetId: pictureSetId ?? this.pictureSetId,
      sequence: sequence ?? this.sequence,
      currentAnimalIndex: currentAnimalIndex ?? this.currentAnimalIndex,
      unlockedStickers: unlockedStickers ?? this.unlockedStickers,
    );
  }

  @override
  List<Object?> get props => [
    pictureSetId,
    sequence,
    currentAnimalIndex,
    unlockedStickers,
  ];
}

/// Trạng thái của màn hình ghép tranh kéo-thả
class MatchingGameState extends Equatable {
  /// Mã bộ tranh đang ghép
  final String pictureSetId;

  /// Danh sách con vật cần ghép trong bộ tranh
  final List<Animal> targets;

  /// Tập hợp các con vật bé đã kéo vào đúng ô bóng gỗ
  final Set<Animal> matchedAnimals;

  /// Con vật vừa mới ghép đúng (dùng để kích hoạt animation hiệu ứng)
  final Animal? lastMatchedAnimal;

  const MatchingGameState({
    this.pictureSetId = 'living_room',
    this.targets = DrawingProgressState.defaultSequence,
    this.matchedAnimals = const {},
    this.lastMatchedAnimal,
  });

  /// Tổng số con vật cần ghép
  int get totalTargets => targets.length;

  /// Đã ghép đúng tất cả con vật hay chưa
  bool get isAllMatched => matchedAnimals.length >= totalTargets;

  /// Kiểm tra 1 con vật đã được ghép đúng chưa
  bool isMatched(Animal animal) => matchedAnimals.contains(animal);

  MatchingGameState copyWith({
    String? pictureSetId,
    List<Animal>? targets,
    Set<Animal>? matchedAnimals,
    Animal? lastMatchedAnimal,
  }) {
    return MatchingGameState(
      pictureSetId: pictureSetId ?? this.pictureSetId,
      targets: targets ?? this.targets,
      matchedAnimals: matchedAnimals ?? this.matchedAnimals,
      lastMatchedAnimal: lastMatchedAnimal,
    );
  }

  @override
  List<Object?> get props => [
    pictureSetId,
    targets,
    matchedAnimals,
    lastMatchedAnimal,
  ];
}
