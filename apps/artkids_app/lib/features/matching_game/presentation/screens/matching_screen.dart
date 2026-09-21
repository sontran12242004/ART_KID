import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../data/matching_game_config.dart';
import '../../domain/animal.dart';
import '../../domain/matching_game_progress.dart';
import '../providers/drawing_provider.dart';
import '../providers/matching_game_progress_provider.dart';
import '../providers/matching_provider.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/draggable_sticker.dart';
import '../widgets/drop_target_slot.dart';

/// Màn hình ghép tranh kéo-thả: bé kéo các sticker vào đúng ô bóng gỗ
class MatchingScreen extends ConsumerStatefulWidget {
  final String pictureSetId;

  const MatchingScreen({
    super.key,
    this.pictureSetId = 'living_room',
  });

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchingState = ref.read(matchingProvider);
      // Nếu pictureSetId khác với state hiện tại, khởi tạo lại
      if (matchingState.pictureSetId != widget.pictureSetId) {
        final progress = ref
            .read(matchingGameProgressProvider)
            .getProgress(widget.pictureSetId);
        ref.read(matchingProvider.notifier).initialize(
              widget.pictureSetId,
              restoredMatches: progress?.matchedAnimals,
            );
      }
    });
  }

  void _onAnimalMatched(Animal animal) {
    ref.read(matchingProvider.notifier).matchAnimal(animal);

    final drawingState = ref.read(drawingProvider);
    final matchingState = ref.read(matchingProvider);
    final pictureSet = MatchingGameConfig.getPictureSet(widget.pictureSetId);

    // Lưu ngay tiến trình kéo thả dở dang vào Hive sau mỗi lần thả đúng
    ref.read(matchingGameProgressProvider.notifier).saveProgress(
          MatchingGameProgress(
            pictureSetId: widget.pictureSetId,
            currentStep: GamePhase.matching,
            currentAnimalIndex: drawingState.currentAnimalIndex,
            unlockedStickers: drawingState.unlockedStickers,
            matchedAnimals: matchingState.matchedAnimals.toList(),
            lastUpdatedAt: DateTime.now(),
          ),
        );

    // Khi ghép đúng toàn bộ các con vật trong bộ tranh
    if (matchingState.isAllMatched) {
      // Ghi nhận vào Gallery lịch sử tranh hoàn thiện và tự động xoá tiến trình dở dang
      ref.read(matchingGameProgressProvider.notifier).recordCompletion(
            pictureSetId: widget.pictureSetId,
            pictureTitle: pictureSet.title,
            thumbnailAsset: pictureSet.thumbnailAsset,
          );
    }
  }

  void _onReplay() {
    // Reset toàn bộ state trong cả drawing_provider và matching_provider
    ref.read(drawingProvider.notifier).reset();
    ref.read(matchingProvider.notifier).reset();

    // Điều hướng quay lại màn hình vẽ bắt đầu từ con vật đầu tiên của bộ tranh này
    context.go('/matching-game/draw/${widget.pictureSetId}');
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingProvider);
    final matchingState = ref.watch(matchingProvider);
    final pictureSet = MatchingGameConfig.getPictureSet(widget.pictureSetId);

    // Danh sách sticker bé đã mở khóa ở màn vẽ (nếu vào thẳng thì lấy danh sách con vật của bộ tranh)
    final availableStickers = drawingState.unlockedStickers.isNotEmpty
        ? drawingState.unlockedStickers
        : pictureSet.slots.map((s) => s.animal).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thanh Header: Nút quay về + Tiêu đề
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Color(0xFF264653)),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RoutePaths.matchingGame);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pictureSet.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: KidUiConstants.textDark,
                              ),
                            ),
                            const Text(
                              'Kéo từng bạn thú vào đúng ô bóng gỗ nhé!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C757D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Điểm số đã ghép
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFBE0B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${matchingState.matchedAnimals.length}/${pictureSet.totalAnimals} ⭐',
                          style: const TextStyle(
                            color: Color(0xFF264653),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vùng tranh nền phòng khách với LayoutBuilder tính kích thước thực tế
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final targetRatio = pictureSet.bgAspectRatio;
                        double bgWidth = constraints.maxWidth;
                        double bgHeight = bgWidth / targetRatio;

                        if (bgHeight > constraints.maxHeight) {
                          bgHeight = constraints.maxHeight;
                          bgWidth = bgHeight * targetRatio;
                        }

                        return Center(
                          child: Container(
                            width: bgWidth,
                            height: bgHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // Tranh nền
                                  Image.asset(
                                    pictureSet.backgroundAsset,
                                    width: bgWidth,
                                    height: bgHeight,
                                    fit: BoxFit.fill,
                                  ),

                                  // Các Vùng DropTarget đặt chính xác theo tọa độ %
                                  ...pictureSet.slots.map((slot) {
                                    return DropTargetSlot(
                                      key: ValueKey('slot_${slot.animal.name}'),
                                      config: slot,
                                      bgWidth: bgWidth,
                                      bgHeight: bgHeight,
                                      isMatched: matchingState
                                          .isMatched(slot.animal),
                                      onMatched: _onAnimalMatched,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Khay Sticker của bé đặt ở dưới
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thanh tay cầm khay
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Hàng ngang các sticker Draggable
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: availableStickers.map((animal) {
                          return DraggableSticker(
                            key: ValueKey('drag_${animal.name}'),
                            animal: animal,
                            isMatched: matchingState.isMatched(animal),
                            size: 86,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Khi ghép đúng cả 3 con: Kích hoạt hiệu ứng ăn mừng lớn toàn màn hình
            if (matchingState.isAllMatched)
              CelebrationOverlay(
                isGrandCelebration: true,
                onReplay: _onReplay,
              ),
          ],
        ),
      ),
    );
  }
}
