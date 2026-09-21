import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../data/matching_game_config.dart';
import '../../domain/completed_picture.dart';
import '../providers/matching_game_progress_provider.dart';

/// Màn hình Bộ Sưu Tập thành tích các tranh bé đã hoàn thiện
class CompletedGalleryScreen extends ConsumerWidget {
  const CompletedGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(matchingGameProgressProvider);
    final completedList = storageState.completedPictures;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const Expanded(
                    child: Text(
                      'Bộ Sưu Tập Của Bé 🏆',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: KidUiConstants.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBE0B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${completedList.length} Tranh ⭐',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF264653),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung chính
            Expanded(
              child: completedList.isEmpty
                  ? _buildEmptyState(context)
                  : _buildGalleryList(context, completedList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166).withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 64,
                color: Color(0xFFE76F51),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bé Chưa Có Bức Tranh Nào!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy cùng bắt đầu vẽ và ghép các bạn thú vào tranh để sưu tầm thật nhiều huy hiệu nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text(
                'Đi Ghép Tranh Ngay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.go(RoutePaths.matchingGame),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryList(
    BuildContext context,
    List<CompletedPicture> completedList,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      itemCount: completedList.length,
      itemBuilder: (context, index) {
        final item = completedList[index];
        final pictureSet = MatchingGameConfig.getPictureSet(item.pictureSetId);
        final dateStr = dateFormat.format(item.completedAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tranh nền đã ghép đầy đủ các sticker vào vị trí
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = width / pictureSet.bgAspectRatio;

                    return SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          // Ảnh nền
                          Image.asset(
                            pictureSet.backgroundAsset,
                            width: width,
                            height: height,
                            fit: BoxFit.fill,
                          ),

                          // Dán toàn bộ sticker của các slot lên tranh
                          ...pictureSet.slots.map((slot) {
                            return Positioned(
                              left: slot.leftPercent * width,
                              top: slot.topPercent * height,
                              width: slot.widthPercent * width,
                              height: slot.heightPercent * height,
                              child: Image.asset(
                                slot.stickerAssetPath,
                                fit: BoxFit.contain,
                              ),
                            );
                          }),

                          // Huy hiệu cúp vàng ở góc phải
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB703),
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Thông tin ngày hoàn thành
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.pictureTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: KidUiConstants.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Hoàn Hảo! 🌟',
                          style: TextStyle(
                            color: Color(0xFF06D6A0),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
