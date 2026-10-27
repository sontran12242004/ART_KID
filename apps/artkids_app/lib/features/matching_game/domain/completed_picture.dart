import 'package:hive/hive.dart';

/// Model lưu trữ lịch sử một lần hoàn thành bộ tranh (Gallery thành tích)
@HiveType(typeId: 22)
class CompletedPicture {
  /// Mã định danh của bản ghi hoàn thành (thường là timestamp dạng chuỗi)
  @HiveField(0)
  final String id;

  /// Mã bộ tranh (ví dụ: 'living_room')
  @HiveField(1)
  final String pictureSetId;

  /// Tên bộ tranh tại thời điểm hoàn thành
  @HiveField(2)
  final String pictureTitle;

  /// Thời điểm hoàn thành
  @HiveField(3)
  final DateTime completedAt;

  /// Ảnh đại diện hoặc ảnh nền của bức tranh
  @HiveField(4)
  final String thumbnailAsset;

  const CompletedPicture({
    required this.id,
    required this.pictureSetId,
    required this.pictureTitle,
    required this.completedAt,
    required this.thumbnailAsset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pictureSetId': pictureSetId,
      'pictureTitle': pictureTitle,
      'completedAt': completedAt.toIso8601String(),
      'thumbnailAsset': thumbnailAsset,
    };
  }

  factory CompletedPicture.fromMap(Map<dynamic, dynamic> map) {
    return CompletedPicture(
      id: map['id'] as String? ?? '',
      pictureSetId: map['pictureSetId'] as String? ?? '',
      pictureTitle: map['pictureTitle'] as String? ?? 'Bức tranh hoàn thành',
      completedAt:
          DateTime.tryParse(map['completedAt'] as String? ?? '') ??
          DateTime.now(),
      thumbnailAsset: map['thumbnailAsset'] as String? ?? '',
    );
  }
}

/// TypeAdapter cho CompletedPicture
class CompletedPictureAdapter extends TypeAdapter<CompletedPicture> {
  @override
  final int typeId = 22;

  @override
  CompletedPicture read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return CompletedPicture(
      id: fields[0] as String? ?? '',
      pictureSetId: fields[1] as String? ?? '',
      pictureTitle: fields[2] as String? ?? 'Bức tranh hoàn thành',
      completedAt: fields[3] as DateTime? ?? DateTime.now(),
      thumbnailAsset: fields[4] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, CompletedPicture obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pictureSetId)
      ..writeByte(2)
      ..write(obj.pictureTitle)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.thumbnailAsset);
  }
}
