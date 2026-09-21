import 'dart:math';

import 'package:flutter/material.dart';

/// Fallback animation 2D — hiển thị con vật di chuyển, tung tăng nhảy nhót
/// trong toàn bộ khung hình rộng rãi khi không có model 3D GLB.
///
/// Hỗ trợ:
/// - Mở rộng tối đa toàn bộ chiều ngang & chiều dọc của stage.
/// - Con vật tự do chạy qua lại khắp sân chơi và tự động quay mặt theo hướng di chuyển.
/// - Bé có thể chạm (tap) vào bất kỳ vị trí nào trên sân để con vật chạy đến và nhảy cẫng lên!
class AnimatedCreatureWidget extends StatefulWidget {
  const AnimatedCreatureWidget({
    super.key,
    required this.emoji,
    required this.creatureColor,
    this.displayName,
  });

  final String emoji;
  final Color creatureColor;
  final String? displayName;

  @override
  State<AnimatedCreatureWidget> createState() => _AnimatedCreatureWidgetState();
}

class _AnimatedCreatureWidgetState extends State<AnimatedCreatureWidget>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final AnimationController _bounceController;
  late final AnimationController _sparkleController;

  final _random = Random();
  Offset _targetOffset = Offset.zero;
  Offset _startOffset = Offset.zero;
  bool _facingRight = true;

  @override
  void initState() {
    super.initState();

    // Animation di chuyển qua lại
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Animation nhảy nhót (bounce)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    // Animation hạt lấp lánh (sparkles)
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startNewMove();
  }

  void _startNewMove() {
    _startOffset = _targetOffset;
    // Biên độ di chuyển rộng: -0.36 .. 0.36 của chiều rộng stage (~72% toàn màn hình)
    final nextX = (_random.nextDouble() - 0.5) * 0.72;
    // Biên độ thẳng đứng vừa vặn: -0.15 .. 0.15
    final nextY = (_random.nextDouble() - 0.5) * 0.30;

    _targetOffset = Offset(nextX, nextY);
    if (mounted) {
      setState(() {
        _facingRight = _targetOffset.dx >= _startOffset.dx;
      });
    }

    _moveController.duration = Duration(milliseconds: 2200 + _random.nextInt(1200));
    _moveController.forward(from: 0).then((_) {
      if (mounted) _startNewMove();
    });
  }

  /// Khi bé chạm vào màn hình, con vật chạy nhanh đến vị trí chạm
  void _handleTap(Offset localPos, double areaWidth, double areaHeight) {
    final currentPos =
        Offset.lerp(_startOffset, _targetOffset, _moveController.value) ?? Offset.zero;
    _startOffset = currentPos;

    final targetX =
        ((localPos.dx - areaWidth / 2) / areaWidth).clamp(-0.38, 0.38);
    final targetY =
        ((localPos.dy - areaHeight / 2) / areaHeight).clamp(-0.25, 0.20);

    _targetOffset = Offset(targetX, targetY);
    setState(() {
      _facingRight = _targetOffset.dx >= _startOffset.dx;
    });

    _moveController.duration = const Duration(milliseconds: 900);
    _moveController.forward(from: 0).then((_) {
      if (mounted) _startNewMove();
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _bounceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mergedListenable = Listenable.merge([
      _moveController,
      _bounceController,
      _sparkleController,
    ]);

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.creatureColor.withValues(alpha: 0.08),
              widget.creatureColor.withValues(alpha: 0.02),
              Colors.white,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final areaWidth = constraints.maxWidth;
            final areaHeight = constraints.maxHeight;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handleTap(details.localPosition, areaWidth, areaHeight),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Sân cỏ trang trí nhẹ nhàng phía đáy
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF81C784).withValues(alpha: 0.18),
                            const Color(0xFF66BB6A).withValues(alpha: 0.35),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.elliptical(320, 36),
                        ),
                      ),
                    ),
                  ),

                  // Gợi ý tương tác dễ thương cho bé
                  Positioned(
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👆 ', style: TextStyle(fontSize: 14)),
                          Text(
                            'Chạm vào sân khấu để gọi bạn nhé!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF636E72),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Con vật và các hạt lấp lánh di chuyển
                  AnimatedBuilder(
                    animation: mergedListenable,
                    builder: (context, _) {
                      final progress = _moveController.value;
                      final currentOffset =
                          Offset.lerp(_startOffset, _targetOffset, progress) ??
                              Offset.zero;
                      final bounceValue = Tween<double>(begin: 0, end: -24)
                          .animate(CurvedAnimation(
                            parent: _bounceController,
                            curve: Curves.easeInOut,
                          ))
                          .value;
                      final sparklePhase = _sparkleController.value;

                      return Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          // Hạt lấp lánh (Sparkles & Stars)
                          ..._buildSparkles(
                            currentOffset,
                            sparklePhase,
                            areaWidth,
                            areaHeight,
                          ),

                          // Con vật chính
                          Transform.translate(
                            offset: Offset(
                              currentOffset.dx * areaWidth,
                              currentOffset.dy * areaHeight + bounceValue,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Bóng đổ co giãn theo độ nảy
                                Transform.scale(
                                  scaleX: 1.0 + (bounceValue.abs() / 50),
                                  scaleY: 0.35,
                                  child: Container(
                                    width: 75,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Emoji con vật (có hiệu ứng lật hướng đi)
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..scale(_facingRight ? 1.0 : -1.0, 1.0),
                                  child: Text(
                                    widget.emoji,
                                    style: const TextStyle(
                                      fontSize: 90,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSparkles(
    Offset baseOffset,
    double phase,
    double areaWidth,
    double areaHeight,
  ) {
    final sparkles = <Widget>[];
    const sparkleEmojis = ['✨', '⭐', '🌟', '💖', '🎶', '💫'];

    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi + phase * 2 * pi;
      final radius = 70.0 + sin(phase * pi * 2 + i) * 35;
      final opacity =
          (0.25 + 0.75 * sin(phase * pi * 2 + i * 1.5)).clamp(0.0, 1.0);

      sparkles.add(
        Transform.translate(
          offset: Offset(
            baseOffset.dx * areaWidth + cos(angle) * radius,
            baseOffset.dy * areaHeight + sin(angle) * radius - 15,
          ),
          child: Opacity(
            opacity: opacity,
            child: Text(
              sparkleEmojis[i % sparkleEmojis.length],
              style: TextStyle(
                fontSize: 18 + sin(phase * pi + i) * 6,
              ),
            ),
          ),
        ),
      );
    }

    return sparkles;
  }
}
