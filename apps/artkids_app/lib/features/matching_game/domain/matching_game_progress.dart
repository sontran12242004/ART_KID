import 'package:hive/hive.dart';
import 'animal.dart';

/// Giai đoạn hiện tại của tiến trình dở dang
@HiveType(typeId: 21)
enum GamePhase {
  @HiveField(0)
  drawing,

  @HiveField(1)
  matching,
}

/// Model lưu trữ tiến trình dở dang của một bộ tranh (để có thể resume)
@HiveType(typeId: 20)
class MatchingGameProgress {
  /// Mã bộ tranh (ví dụ: 'living_room')
  @HiveField(0)
  final String pictureSetId;

  /// Đang ở giai đoạn nào: vẽ hay ghép tranh
  @HiveField(1)
  final GamePhase currentStep;

  /// Thứ tự con vật đang vẽ (0, 1, 2) nếu đang ở giai đoạn vẽ
  @HiveField(2)
  final int currentAnimalIndex;

  /// Danh sách con vật bé đã vẽ xong và nhận sticker
  @HiveField(3)
  final List<Animal> unlockedStickers;

  /// Danh sách con vật bé đã kéo ghép đúng vào ô trên tranh
  @HiveField(4)
  final List<Animal> matchedAnimals;

  /// Thời điểm cập nhật tiến trình gần nhất
  @HiveField(5)
  final DateTime lastUpdatedAt;

  const MatchingGameProgress({
    required this.pictureSetId,
    required this.currentStep,
    required this.currentAnimalIndex,
    required this.unlockedStickers,
    required this.matchedAnimals,
    required this.lastUpdatedAt,
  });

  MatchingGameProgress copyWith({
    String? pictureSetId,
    GamePhase? currentStep,
    int? currentAnimalIndex,
    List<Animal>? unlockedStickers,
    List<Animal>? matchedAnimals,
    DateTime? lastUpdatedAt,
  }) {
    return MatchingGameProgress(
      pictureSetId: pictureSetId ?? this.pictureSetId,
      currentStep: currentStep ?? this.currentStep,
      currentAnimalIndex: currentAnimalIndex ?? this.currentAnimalIndex,
      unlockedStickers: unlockedStickers ?? this.unlockedStickers,
      matchedAnimals: matchedAnimals ?? this.matchedAnimals,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pictureSetId': pictureSetId,
      'currentStep': currentStep.name,
      'currentAnimalIndex': currentAnimalIndex,
      'unlockedStickers': unlockedStickers.map((a) => a.name).toList(),
      'matchedAnimals': matchedAnimals.map((a) => a.name).toList(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory MatchingGameProgress.fromMap(Map<dynamic, dynamic> map) {
    return MatchingGameProgress(
      pictureSetId: map['pictureSetId'] as String? ?? '',
      currentStep: (map['currentStep'] as String?) == 'matching'
          ? GamePhase.matching
          : GamePhase.drawing,
      currentAnimalIndex: map['currentAnimalIndex'] as int? ?? 0,
      unlockedStickers: ((map['unlockedStickers'] as List?) ?? [])
          .map(
            (e) => Animal.values.firstWhere(
              (a) => a.name == e.toString(),
              orElse: () => Animal.cat,
            ),
          )
          .toList(),
      matchedAnimals: ((map['matchedAnimals'] as List?) ?? [])
          .map(
            (e) => Animal.values.firstWhere(
              (a) => a.name == e.toString(),
              orElse: () => Animal.cat,
            ),
          )
          .toList(),
      lastUpdatedAt:
          DateTime.tryParse(map['lastUpdatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// TypeAdapter cho MatchingGameProgress để lưu bền vững trong Hive
class MatchingGameProgressAdapter extends TypeAdapter<MatchingGameProgress> {
  @override
  final int typeId = 20;

  @override
  MatchingGameProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final stepVal = fields[1];
    final GamePhase step;
    if (stepVal is GamePhase) {
      step = stepVal;
    } else if (stepVal is String && stepVal == 'matching') {
      step = GamePhase.matching;
    } else {
      step = GamePhase.drawing;
    }

    final rawUnlocked = fields[3] as List? ?? [];
    final unlocked = rawUnlocked.map((e) {
      if (e is Animal) return e;
      return Animal.values.firstWhere(
        (a) => a.name == e.toString(),
        orElse: () => Animal.cat,
      );
    }).toList();

    final rawMatched = fields[4] as List? ?? [];
    final matched = rawMatched.map((e) {
      if (e is Animal) return e;
      return Animal.values.firstWhere(
        (a) => a.name == e.toString(),
        orElse: () => Animal.cat,
      );
    }).toList();

    return MatchingGameProgress(
      pictureSetId: fields[0] as String? ?? '',
      currentStep: step,
      currentAnimalIndex: fields[2] as int? ?? 0,
      unlockedStickers: unlocked,
      matchedAnimals: matched,
      lastUpdatedAt: fields[5] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, MatchingGameProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.pictureSetId)
      ..writeByte(1)
      ..write(obj.currentStep.name)
      ..writeByte(2)
      ..write(obj.currentAnimalIndex)
      ..writeByte(3)
      ..write(obj.unlockedStickers.map((a) => a.name).toList())
      ..writeByte(4)
      ..write(obj.matchedAnimals.map((a) => a.name).toList())
      ..writeByte(5)
      ..write(obj.lastUpdatedAt);
  }
}
