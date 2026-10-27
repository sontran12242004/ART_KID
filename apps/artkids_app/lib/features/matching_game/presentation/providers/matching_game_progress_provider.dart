import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/completed_picture.dart';
import '../../domain/matching_game_progress.dart';
import '../../data/matching_game_config.dart';

final gameSyncErrorProvider = StateProvider<String?>((ref) => null);

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

class MatchingGameProgressNotifier extends StateNotifier<MatchingStorageState> {
  MatchingGameProgressNotifier(this.dio, this.childId, this.report)
    : super(const MatchingStorageState()) {
    loadAll();
  }
  final Dio dio;
  final String? childId;
  final void Function(String?) report;
  Future<void> _pending = Future.value();
  Future<void> _queue(Future<void> Function() work) {
    final task = _pending.then((_) async {
      if (!mounted || childId == null) return;
      try {
        await work();
        if (mounted) report(null);
      } catch (e) {
        if (mounted) report(apiError(e));
      }
    });
    _pending = task;
    return task;
  }

  Future<void> loadAll() => _queue(() async {
    final data = await dio.get('/children/$childId/gallery?pageSize=100');
    final progress = <String, MatchingGameProgress>{};
    for (final set in MatchingGameConfig.pictureSets) {
      final value = (await dio.get('/children/$childId/game/${set.id}')).data;
      if (value != null) progress[set.id] = MatchingGameProgress.fromMap(value);
    }
    if (mounted) {
      state = MatchingStorageState(
        inProgressMap: progress,
        completedPictures: [
          for (final p in data.data) CompletedPicture.fromMap(p),
        ],
      );
    }
  });
  Future<void> saveProgress(MatchingGameProgress progress) => _queue(() async {
    final value = (await dio.put(
      '/children/$childId/game/${progress.pictureSetId}',
      data: progress.toMap(),
    )).data;
    if (mounted) {
      state = state.copyWith(
        inProgressMap: {
          ...state.inProgressMap,
          progress.pictureSetId: MatchingGameProgress.fromMap(value),
        },
      );
    }
  });
  Future<void> clearProgress(String id) => _queue(() async {
    await dio.put(
      '/children/$childId/game/$id',
      data: {
        'currentStep': 'drawing',
        'currentAnimalIndex': 0,
        'unlockedStickers': [],
        'matchedAnimals': [],
      },
    );
    if (mounted) {
      final updated = {...state.inProgressMap}..remove(id);
      state = state.copyWith(inProgressMap: updated);
    }
  });
  Future<void> recordCompletion({
    required String pictureSetId,
    required String pictureTitle,
    required String thumbnailAsset,
  }) => _queue(() async {
    final value = (await dio.post(
      '/children/$childId/game/$pictureSetId/complete',
    )).data;
    final completed = CompletedPicture.fromMap(value);
    if (mounted) {
      final updated = {...state.inProgressMap}..remove(pictureSetId);
      state = MatchingStorageState(
        inProgressMap: updated,
        completedPictures: [
          completed,
          ...state.completedPictures.where((p) => p.id != completed.id),
        ],
      );
    }
  });
}

final matchingGameProgressProvider =
    StateNotifierProvider<MatchingGameProgressNotifier, MatchingStorageState>((
      ref,
    ) {
      final id = ref.watch(authProvider.select((s) => s.selectedChild?.id));
      return MatchingGameProgressNotifier(
        ref.watch(dioProvider),
        id,
        (error) => ref.read(gameSyncErrorProvider.notifier).state = error,
      );
    });
