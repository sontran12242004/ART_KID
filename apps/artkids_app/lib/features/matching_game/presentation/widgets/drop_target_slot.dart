import 'package:flutter/material.dart';
import '../../data/game_audio_service.dart';
import '../../data/matching_game_config.dart';
import '../../domain/animal.dart';

/// Vùng đích ghép tranh cho từng hình bóng gỗ
/// Sử dụng Positioned theo tỉ lệ % dựa trên kích thước thực tế của ảnh nền
class DropTargetSlot extends StatelessWidget {
  final SlotConfig config;

  /// Chiều rộng thực tế của tranh nền sau khi layout
  final double bgWidth;

  /// Chiều cao thực tế của tranh nền sau khi layout
  final double bgHeight;

  /// Con vật này đã được ghép đúng chưa
  final bool isMatched;

  /// Callback khi ghép đúng
  final ValueChanged<Animal> onMatched;

  const DropTargetSlot({
    super.key,
    required this.config,
    required this.bgWidth,
    required this.bgHeight,
    required this.isMatched,
    required this.onMatched,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Tọa độ và kích thước pixel thực tế của hình bóng gỗ trên tranh
    final targetLeft = config.leftPercent * bgWidth;
    final targetTop = config.topPercent * bgHeight;
    final targetWidth = config.widthPercent * bgWidth;
    final targetHeight = config.heightPercent * bgHeight;

    // 2. Mở rộng vùng nhận DragTarget thêm 20% (10% mỗi phía)
    // giúp trẻ nhỏ dễ thả trúng mục tiêu khi thao tác bằng ngón tay
    final hitPaddingX = targetWidth * 0.10;
    final hitPaddingY = targetHeight * 0.10;

    final positionedLeft = targetLeft - hitPaddingX;
    final positionedTop = targetTop - hitPaddingY;
    final positionedWidth = targetWidth + (hitPaddingX * 2);
    final positionedHeight = targetHeight + (hitPaddingY * 2);

    return Positioned(
      left: positionedLeft,
      top: positionedTop,
      width: positionedWidth,
      height: positionedHeight,
      child: DragTarget<Animal>(
        // Chỉ chấp nhận nếu sticker đang kéo trùng khớp với con vật của ô này
        onWillAcceptWithDetails: (details) {
          return details.data == config.animal && !isMatched;
        },
        // Khi bé thả đúng sticker vào ô
        onAcceptWithDetails: (details) {
          GameAudioService.instance.playPop();
          onMatched(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isHoveringValid = candidateData.isNotEmpty &&
              candidateData.first == config.animal;

          return Center(
            child: Container(
              width: targetWidth,
              height: targetHeight,
              alignment: Alignment.center,
              // Hiệu ứng viền phát sáng khi bé đang rê đúng sticker lại gần ô
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isHoveringValid
                    ? Border.all(
                        color: const Color(0xFFFFD166),
                        width: 3.5,
                      )
                    : null,
                color: isHoveringValid
                    ? const Color(0xFFFFD166).withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isMatched
                    // Khi đã ghép đúng: hiển thị sticker dán đè chính xác lên hình bóng gỗ
                    ? Image.asset(
                        config.animal.stickerAssetPath,
                        key: ValueKey('matched_${config.animal.name}'),
                        width: targetWidth,
                        height: targetHeight,
                        fit: BoxFit.contain,
                      )
                    // Khi chưa ghép: để trống trong suốt để nhìn thấy hình bóng gỗ trên ảnh nền
                    : const SizedBox.shrink(key: ValueKey('empty_slot')),
              ),
            ),
          );
        },
      ),
    );
  }
}
