import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../data/game_audio_service.dart';
import '../../domain/animal.dart';

/// Overlay chúc mừng dùng chung cho cả 2 màn hình:
/// - Chế độ nhẹ: Sau mỗi lần vẽ xong 1 con vật, hiện sticker nhận được + pháo giấy ngắn.
/// - Chế độ lớn (Grand Celebration): Khi bé ghép đúng cả 3 sticker vào tranh phòng khách,
///   hiện cúp vàng + mưa pháo giấy rực rỡ + nút "Chơi lại".
class CelebrationOverlay extends StatefulWidget {
  /// True nếu là hiệu ứng toàn màn hình khi hoàn thành toàn bộ game
  final bool isGrandCelebration;

  /// Con vật vừa vẽ xong (dùng cho chế độ vẽ)
  final Animal? rewardedAnimal;

  /// Callback khi hiệu ứng ngắn kết thúc (tự động chuyển bước)
  final VoidCallback? onDismiss;

  /// Callback khi bé bấm nút "Chơi lại" ở màn hình ăn mừng lớn
  final VoidCallback? onReplay;

  const CelebrationOverlay({
    super.key,
    this.isGrandCelebration = false,
    this.rewardedAnimal,
    this.onDismiss,
    this.onReplay,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: Duration(seconds: widget.isGrandCelebration ? 4 : 2),
    );

    // Kích hoạt pháo giấy & âm thanh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      if (widget.isGrandCelebration) {
        GameAudioService.instance.playCelebration();
      } else {
        GameAudioService.instance.playSuccess();
      }
    });

    // Nếu là chế độ vẽ ngắn, tự động đóng sau 2.2 giây
    if (!widget.isGrandCelebration) {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && widget.onDismiss != null) {
          widget.onDismiss!();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Lớp phủ nền mờ
        Container(
          color: Colors.black.withValues(
            alpha: widget.isGrandCelebration ? 0.65 : 0.45,
          ),
        ),

        // Nguồn pháo giấy
        Align(
          alignment: widget.isGrandCelebration
              ? Alignment.topCenter
              : Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: widget.isGrandCelebration ? pi / 2 : -pi / 2,
            blastDirectionality: widget.isGrandCelebration
                ? BlastDirectionality.explosive
                : BlastDirectionality.directional,
            emissionFrequency: widget.isGrandCelebration ? 0.08 : 0.04,
            numberOfParticles: widget.isGrandCelebration ? 40 : 20,
            gravity: 0.15,
            shouldLoop: widget.isGrandCelebration,
            colors: const [
              Color(0xFFFF595E),
              Color(0xFFFFCA3A),
              Color(0xFF8AC926),
              Color(0xFF1982C4),
              Color(0xFF6A4C93),
            ],
          ),
        ),

        // Nội dung popup chúc mừng
        Center(
          child: widget.isGrandCelebration
              ? _buildGrandCelebrationCard(context)
              : _buildSingleAnimalRewardCard(context),
        ),
      ],
    );
  }

  /// Card chúc mừng khi nhận được 1 sticker sau khi vẽ
  Widget _buildSingleAnimalRewardCard(BuildContext context) {
    final animal = widget.rewardedAnimal;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 BÉ GIỎI QUÁ! 🎉',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFFD62828),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              animal?.rewardMessage ?? 'Bé nhận được 1 sticker mới!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF264653),
              ),
            ),
            const SizedBox(height: 16),

            // Ảnh sticker vừa nhận được
            if (animal != null)
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD166), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.5),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Image.asset(
                  animal.stickerAssetPath,
                  fit: BoxFit.contain,
                ),
              ),

            const SizedBox(height: 16),
            const Text(
              'Đang chuẩn bị sticker tiếp theo...',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card chúc mừng toàn màn hình khi ghép đúng cả 3 con vật
  Widget _buildGrandCelebrationCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF6E5)],
          ),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFFFD166), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Biểu tượng vương miện / cúp
            const Text('🏆 ⭐ 🌟', style: TextStyle(fontSize: 38)),
            const SizedBox(height: 6),
            const Text(
              'HOÀN THÀNH XUẤT SẮC!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE76F51),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bé đã vẽ và ghép đúng cả 3 bạn thú vào căn phòng khách xinh đẹp rồi!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF264653),
              ),
            ),
            const SizedBox(height: 18),

            // Hàng 3 sticker tỏa sáng
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStickerBadge(Animal.cat),
                const SizedBox(width: 12),
                _buildMiniStickerBadge(Animal.dog),
                const SizedBox(width: 12),
                _buildMiniStickerBadge(Animal.bird),
              ],
            ),
            const SizedBox(height: 24),

            // Nút "Chơi Lại" nổi bật to bản cho trẻ em
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06D6A0),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFF06D6A0).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: const Icon(Icons.replay_rounded, size: 28),
                label: const Text(
                  'Chơi Lại Nào!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: widget.onReplay,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStickerBadge(Animal animal) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFBE0B), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: Image.asset(animal.stickerAssetPath, fit: BoxFit.contain),
    );
  }
}
