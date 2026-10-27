import 'package:flutter/material.dart';
import '../../data/game_audio_service.dart';
import '../../domain/animal.dart';

/// Widget bọc `Draggable<Animal>` cho từng sticker trong khay đồ chơi
class DraggableSticker extends StatelessWidget {
  final Animal animal;

  /// True nếu con vật này đã được ghép đúng vào ô trên tranh
  final bool isMatched;

  /// Kích thước hiển thị trong khay
  final double size;

  const DraggableSticker({
    super.key,
    required this.animal,
    this.isMatched = false,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu con vật đã ghép đúng vào tranh, ẩn khỏi khay (hoặc hiện slot trống)
    if (isMatched) {
      return SizedBox(
        width: size,
        height: size + 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF06D6A0),
                size: 36,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              animal.displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Draggable<Animal>(
      data: animal,
      onDragStarted: () {
        GameAudioService.instance.playPop();
      },
      // Hiển thị sticker khi đang được ngón tay kéo đi
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(
          scale: 1.15,
          child: Container(
            width: size * 1.2,
            height: size * 1.2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(animal.stickerAssetPath, fit: BoxFit.contain),
          ),
        ),
      ),
      // Ô mờ giữ chỗ tại khay khi bé đang cầm sticker kéo đi
      childWhenDragging: SizedBox(
        width: size,
        height: size + 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.25,
              child: Image.asset(
                animal.stickerAssetPath,
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              animal.displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      // Hiển thị bình thường tại khay
      child: SizedBox(
        width: size,
        height: size + 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(animal.stickerAssetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            Text(
              animal.displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF264653),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
