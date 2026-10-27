import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../data/matching_game_config.dart';
import '../../domain/matching_game_progress.dart';
import '../../domain/picture_set.dart';
import '../providers/drawing_provider.dart';
import '../providers/matching_game_progress_provider.dart';
import '../providers/matching_provider.dart';

/// Màn hình chọn bộ tranh để vẽ và ghép hình (Khởi đầu luồng /matching-game)
class PictureSelectionScreen extends ConsumerWidget {
  const PictureSelectionScreen({super.key});

  void _onSelectPicture(
    BuildContext context,
    WidgetRef ref,
    PictureSet pictureSet,
    MatchingGameProgress? progress,
  ) {
    if (progress == null) {
      // Chưa có tiến trình dở dang -> Bắt đầu vẽ từ đầu
      ref.read(drawingProvider.notifier).initialize(pictureSet.id);
      context.push('/matching-game/draw/${pictureSet.id}');
    } else {
      // Có tiến trình dở dang -> Hiển thị Dialog hỏi tiếp tục hay bắt đầu lại
      _showResumeDialog(context, ref, pictureSet, progress);
    }
  }

  void _showResumeDialog(
    BuildContext context,
    WidgetRef ref,
    PictureSet pictureSet,
    MatchingGameProgress progress,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isMatchingPhase = progress.currentStep == GamePhase.matching;
        final stepText = isMatchingPhase
            ? 'đang ở bước ghép tranh'
            : 'đã vẽ xong ${progress.unlockedStickers.length}/${pictureSet.totalAnimals} con vật';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFFFF9F1C),
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tiếp Tục Tranh Dở Dang?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bé ơi, bức tranh "${pictureSet.title}" $stepText.',
                style: const TextStyle(fontSize: 15, color: Color(0xFF264653)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bé muốn làm tiếp tranh đang dở hay bắt đầu lại từ đầu nhé?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          actions: [
            // Nút Bắt đầu lại từ đầu
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE76F51),
                side: const BorderSide(color: Color(0xFFE76F51), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Bắt đầu lại'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Xoá tiến trình cũ trong Hive
                await ref
                    .read(matchingGameProgressProvider.notifier)
                    .clearProgress(pictureSet.id);
                // Khởi tạo lại trạng thái trắng
                ref.read(drawingProvider.notifier).initialize(pictureSet.id);
                if (context.mounted) {
                  context.push('/matching-game/draw/${pictureSet.id}');
                }
              },
            ),

            // Nút Tiếp tục chơi
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Làm tiếp 🚀',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (isMatchingPhase) {
                  // Khôi phục trạng thái vẽ và ghép tranh, nhảy thẳng sang màn hình ghép
                  ref
                      .read(drawingProvider.notifier)
                      .initialize(pictureSet.id, resumeProgress: progress);
                  ref
                      .read(matchingProvider.notifier)
                      .initialize(
                        pictureSet.id,
                        restoredMatches: progress.matchedAnimals,
                      );
                  context.push('/matching-game/match/${pictureSet.id}');
                } else {
                  // Khôi phục lượt vẽ tiếp theo
                  ref
                      .read(drawingProvider.notifier)
                      .initialize(pictureSet.id, resumeProgress: progress);
                  context.push('/matching-game/draw/${pictureSet.id}');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(matchingGameProgressProvider);
    final pictureSets = MatchingGameConfig.pictureSets;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header thanh điều hướng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
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
                        context.go(RoutePaths.kidHome);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Chọn Tranh Ghép Hình 🎨',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: KidUiConstants.textDark,
                      ),
                    ),
                  ),

                  // Nút Bộ Sưu Tập Thành Tích
                  InkWell(
                    onTap: () => context.push(RoutePaths.matchingGameGallery),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD166),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFD62828),
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Bộ Sưu Tập',
                            style: TextStyle(
                              color: Color(0xFF264653),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (storageState.completedPictures.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE63946),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${storageState.completedPictures.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lời chào hướng dẫn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Text('🌟', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bé hãy chọn bức tranh yêu thích để bắt đầu vẽ và dán các bạn thú nhé!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF264653),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Danh sách các bộ tranh
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: pictureSets.length,
                itemBuilder: (context, index) {
                  final set = pictureSets[index];
                  final progress = storageState.getProgress(set.id);
                  final isDone = storageState.isCompleted(set.id);
                  final doneCount = storageState.completionCount(set.id);

                  return _buildPictureCard(
                    context: context,
                    ref: ref,
                    pictureSet: set,
                    progress: progress,
                    isDone: isDone,
                    doneCount: doneCount,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureCard({
    required BuildContext context,
    required WidgetRef ref,
    required PictureSet pictureSet,
    required MatchingGameProgress? progress,
    required bool isDone,
    required int doneCount,
  }) {
    final hasProgress = progress != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => _onSelectPicture(context, ref, pictureSet, progress),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ảnh preview của tranh kèm các nhãn trạng thái
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: pictureSet.bgAspectRatio,
                    child: Image.asset(
                      pictureSet.thumbnailAsset,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Lớp phủ bóng mờ nhẹ ở góc trên
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Nhãn trạng thái dở dang / đã hoàn thành
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        if (hasProgress)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9F1C),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  progress.currentStep == GamePhase.matching
                                      ? 'Đang ghép tranh'
                                      : 'Đang vẽ dở (${progress.unlockedStickers.length}/${pictureSet.totalAnimals})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isDone && !hasProgress)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06D6A0),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doneCount > 1
                                      ? 'Đã hoàn thành ($doneCount lần) ⭐'
                                      : 'Đã hoàn thành ⭐',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Nút Play tròn nổi bật ở giữa góc dưới
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF06D6A0,
                            ).withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),

              // Thông tin tên và danh sách con vật
              Padding(
                padding: const EdgeInsets.all(18),
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
                    const SizedBox(height: 6),
                    Text(
                      pictureSet.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hàng icon các con vật trong bộ tranh
                    Row(
                      children: [
                        const Text(
                          'Các bạn thú:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF264653),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...pictureSet.slots.map((s) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9EE),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Image.asset(
                              s.stickerAssetPath,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
