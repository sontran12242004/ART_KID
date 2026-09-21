import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../domain/completed_picture.dart';
import '../../domain/matching_game_progress.dart';

/// State quản lý danh sách tiến trình dở dang và lịch sử hoàn thành tranh
class MatchingStorageState {
  /// Map lưu tiến trình dở dang theo pictureSetId
  final Map<String, MatchingGameProgress> inProgressMap;

  /// Danh sách toàn bộ tranh đã hoàn thiện (sắp xếp theo thời gian gần nhất)
  final List<CompletedPicture> completedPictures;

  const MatchingStorageState({
    this.inProgressMap = const {},
    this.completedPictures = const [],
  });

  /// Kiểm tra xem 1 bộ tranh có đang bị bỏ dở giữa chừng hay không
  bool hasProgress(String pictureSetId) =>
      inProgressMap.containsKey(pictureSetId);

  /// Lấy bản ghi tiến trình dở dang của bộ tranh
  MatchingGameProgress? getProgress(String pictureSetId) =>
      inProgressMap[pictureSetId];

  /// Kiểm tra bộ tranh đã từng được hoàn thành ít nhất 1 lần chưa
  bool isCompleted(String pictureSetId) =>
      completedPictures.any((p) => p.pictureSetId == pictureSetId);

  /// Đếm số lần hoàn thành của bộ tranh
  int completionCount(String pictureSetId) =>
      completedPictures.where((p) => p.pictureSetId == pictureSetId).length;

  MatchingStorageState copyWith({
    Map<String, MatchingGameProgress>? inProgressMap,
    List<CompletedPicture>? completedPictures,
  }) {
    return MatchingStorageState(
      inProgressMap: inProgressMap ?? this.inProgressMap,
      completedPictures: completedPictures ?? this.completedPictures,
    );
  }
}

/// Notifier quản lý đọc, ghi và xóa dữ liệu Hive cho Matching Game
class MatchingGameProgressNotifier
    extends StateNotifier<MatchingStorageState> {
  MatchingGameProgressNotifier() : super(const MatchingStorageState()) {
    loadAll();
  }

  Box<MatchingGameProgress> get _progressBox =>
      Hive.box<MatchingGameProgress>(HiveBoxes.matchingProgress);

  Box<CompletedPicture> get _completedBox =>
      Hive.box<CompletedPicture>(HiveBoxes.completedPictures);

  /// Đọc toàn bộ dữ liệu từ Hive khi khởi tạo
  void loadAll() {
    try {
      final progressMap = <String, MatchingGameProgress>{};
      for (final key in _progressBox.keys) {
        final item = _progressBox.get(key);
        if (item != null) {
          progressMap[item.pictureSetId] = item;
        }
      }

      final completedList = _completedBox.values.toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      state = MatchingStorageState(
        inProgressMap: progressMap,
        completedPictures: completedList,
      );
    } catch (e) {
      debugPrint('MatchingGameProgressNotifier loadAll error: $e');
    }
  }

  /// Lưu hoặc cập nhật tiến trình dở dang vào Hive
  Future<void> saveProgress(MatchingGameProgress progress) async {
    try {
      await _progressBox.put(progress.pictureSetId, progress);
      final updated = Map<String, MatchingGameProgress>.from(state.inProgressMap)
        ..[progress.pictureSetId] = progress;
      state = state.copyWith(inProgressMap: updated);
    } catch (e) {
      debugPrint('saveProgress error: $e');
    }
  }

  /// Xóa tiến trình dở dang khỏi Hive (khi bé bấm bắt đầu lại từ đầu hoặc hoàn thành xong)
  Future<void> clearProgress(String pictureSetId) async {
    try {
      await _progressBox.delete(pictureSetId);
      final updated = Map<String, MatchingGameProgress>.from(state.inProgressMap)
        ..remove(pictureSetId);
      state = state.copyWith(inProgressMap: updated);
    } catch (e) {
      debugPrint('clearProgress error: $e');
    }
  }

  /// Ghi nhận 1 lần hoàn thành tranh vào Gallery thành tích
  Future<void> recordCompletion({
    required String pictureSetId,
    required String pictureTitle,
    required String thumbnailAsset,
  }) async {
    try {
      final id = '${pictureSetId}_${DateTime.now().millisecondsSinceEpoch}';
      final completed = CompletedPicture(
        id: id,
        pictureSetId: pictureSetId,
        pictureTitle: pictureTitle,
        completedAt: DateTime.now(),
        thumbnailAsset: thumbnailAsset,
      );

      // Lưu vào Hive box (không ghi đè mà lưu thành từng bản ghi thành tích)
      await _completedBox.put(id, completed);

      // Đồng thời xoá tiến trình dở dang vì đã hoàn thiện
      await clearProgress(pictureSetId);

      final updatedList = [completed, ...state.completedPictures];
      state = state.copyWith(completedPictures: updatedList);
    } catch (e) {
      debugPrint('recordCompletion error: $e');
    }
  }
}

/// Provider cung cấp trạng thái tiến trình và thành tích tranh ghép
final matchingGameProgressProvider =
    StateNotifierProvider<MatchingGameProgressNotifier, MatchingStorageState>(
        (ref) {
  return MatchingGameProgressNotifier();
});
