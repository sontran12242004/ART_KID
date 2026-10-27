import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../connected/presentation/widgets.dart';
import '../../../connected/data/connected_api.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/animal.dart';
import '../../domain/matching_game_progress.dart';
import '../providers/drawing_provider.dart';
import '../providers/matching_game_progress_provider.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/drawing_canvas.dart';

/// Màn hình vẽ tự do ngón tay cho các con vật trong bộ tranh
class DrawingScreen extends ConsumerStatefulWidget {
  final String pictureSetId;

  const DrawingScreen({super.key, this.pictureSetId = 'living_room'});

  @override
  ConsumerState<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends ConsumerState<DrawingScreen> {
  final GlobalKey<DrawingCanvasState> _canvasKey =
      GlobalKey<DrawingCanvasState>();
  bool _showRewardOverlay = false;
  Animal? _justRewardedAnimal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentDrawingState = ref.read(drawingProvider);
      // Nếu bộ tranh trong state khác với pictureSetId của route, khởi tạo lại
      if (currentDrawingState.pictureSetId != widget.pictureSetId) {
        final progress = ref
            .read(matchingGameProgressProvider)
            .getProgress(widget.pictureSetId);
        ref
            .read(drawingProvider.notifier)
            .initialize(widget.pictureSetId, resumeProgress: progress);
      }
    });
  }

  Future<void> _onFinishDrawing() async {
    if (_saving || _canvasKey.currentState?.hasDrawn != true) return;
    final child = ref.read(authProvider).selectedChild;
    if (child == null) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final consents =
          (await dio.get('/children/${child.id}/consents')).data as List;
      if (!consents.any(
        (c) => c['purpose'] == 'data_processing' && c['revokedAt'] == null,
      )) {
        if (!mounted) return;
        if (!await confirm(
          context,
          'Lưu bản vẽ của bé',
          'Phụ huynh đồng ý lưu bản vẽ của bé trong tài khoản?',
        )) {
          return;
        }
        await dio.post(
          '/auth/consent',
          data: {
            'childId': child.id,
            'purpose': 'data_processing',
            'policyVersion': '2026-01',
          },
        );
      }
      if (!mounted) return;
      final bytes = await _canvasKey.currentState!.exportPng();
      final media = await dio.post(
        '/media/upload',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: 'canvas.png'),
          'kind': 'drawing',
          'childId': child.id,
        }),
      );
      await dio.post(
        '/kid/submissions',
        data: {'childId': child.id, 'imageAssetId': media.data['id']},
      );
      ref.invalidate(apiDataProvider);
      if (!mounted) return;
      final drawingNotifier = ref.read(drawingProvider.notifier);
      final rewardedAnimal = drawingNotifier.completeCurrentAnimal();
      final updatedState = ref.read(drawingProvider);

      // Lưu ngay tiến trình dở dang vào Hive sau khi hoàn thành 1 con vật
      ref
          .read(matchingGameProgressProvider.notifier)
          .saveProgress(
            MatchingGameProgress(
              pictureSetId: widget.pictureSetId,
              currentStep: GamePhase.drawing,
              currentAnimalIndex: updatedState.currentAnimalIndex,
              unlockedStickers: updatedState.unlockedStickers,
              matchedAnimals: const [],
              lastUpdatedAt: DateTime.now(),
            ),
          );

      setState(() {
        _justRewardedAnimal = rewardedAnimal;
        _showRewardOverlay = true;
      });
    } catch (e) {
      if (mounted) toast(context, apiError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onOverlayDismissed() {
    setState(() {
      _showRewardOverlay = false;
    });

    final drawingState = ref.read(drawingProvider);

    // Nếu bé đã hoàn thành vẽ tất cả con vật, chuyển sang giai đoạn ghép tranh
    if (drawingState.isAllDrawn) {
      // Cập nhật trạng thái dở dang sang phase matching trước khi chuyển trang
      ref
          .read(matchingGameProgressProvider.notifier)
          .saveProgress(
            MatchingGameProgress(
              pictureSetId: widget.pictureSetId,
              currentStep: GamePhase.matching,
              currentAnimalIndex: drawingState.currentAnimalIndex,
              unlockedStickers: drawingState.unlockedStickers,
              matchedAnimals: const [],
              lastUpdatedAt: DateTime.now(),
            ),
          );

      context.go('/matching-game/match/${widget.pictureSetId}');
    } else {
      // Chuyển sang con tiếp theo và cập nhật lại tiến trình
      ref.read(drawingProvider.notifier).advanceToNextAnimal();
      final nextState = ref.read(drawingProvider);

      ref
          .read(matchingGameProgressProvider.notifier)
          .saveProgress(
            MatchingGameProgress(
              pictureSetId: widget.pictureSetId,
              currentStep: GamePhase.drawing,
              currentAnimalIndex: nextState.currentAnimalIndex,
              unlockedStickers: nextState.unlockedStickers,
              matchedAnimals: const [],
              lastUpdatedAt: DateTime.now(),
            ),
          );

      _canvasKey.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingProvider);
    final sequence = drawingState.sequence;
    final totalSteps = drawingState.totalAnimals;
    final currentAnimal = drawingState.currentAnimal;
    final stepNumber = (drawingState.currentAnimalIndex + 1).clamp(
      1,
      totalSteps,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Nút quay về màn chọn tranh + Thanh tiến trình
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Nút quay về màn hình chọn tranh
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF264653),
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RoutePaths.matchingGame);
                          }
                        },
                      ),
                      const SizedBox(width: 12),

                      // Thanh tiến trình các con vật
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(totalSteps, (index) {
                            final animal = sequence[index];
                            final isDone = drawingState.unlockedStickers
                                .contains(animal);
                            final isCurrent =
                                index == drawingState.currentAnimalIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? const Color(0xFF06D6A0)
                                    : (isCurrent
                                          ? const Color(0xFFFFD166)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFFE76F51)
                                      : Colors.black12,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    animal == Animal.cat
                                        ? '🐱'
                                        : animal == Animal.dog
                                        ? '🐶'
                                        : '🐦',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  if (isDone) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ),
                      ),

                      // Huy hiệu bước
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Bước $stepNumber/$totalSteps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lời gợi ý vẽ con vật hiện tại
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(
                          0xFFFFD166,
                        ).withValues(alpha: 0.3),
                        child: Text(
                          currentAnimal == Animal.cat
                              ? '🐱'
                              : currentAnimal == Animal.dog
                              ? '🐶'
                              : '🐦',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentAnimal.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: KidUiConstants.textDark,
                              ),
                            ),
                            Text(
                              currentAnimal.drawingPrompt,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C757D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vùng Canvas vẽ bằng ngón tay
                Expanded(
                  child: DrawingCanvas(
                    key: _canvasKey,
                    onFinish: _onFinishDrawing,
                  ),
                ),
              ],
            ),

            // Overlay chúc mừng nhận sticker ngắn sau mỗi lượt vẽ
            if (_showRewardOverlay)
              CelebrationOverlay(
                isGrandCelebration: false,
                rewardedAnimal: _justRewardedAnimal,
                onDismiss: _onOverlayDismissed,
              ),
            if (_saving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
