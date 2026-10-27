import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Widget hiển thị và điều khiển Model 3D GLB cho Huy Hiệu (xoay vòng tròn liên tục)
class Badge3DViewerWidget extends StatefulWidget {
  final String modelGlbPath;
  final double size;
  final bool isCompact;
  final bool interactive;
  final Color glowColor;
  final String? title;
  final IconData? fallbackIcon;
  final String? emoji;

  const Badge3DViewerWidget({
    super.key,
    required this.modelGlbPath,
    this.size = 70,
    this.isCompact = false,
    this.interactive = true,
    this.glowColor = const Color(0xFFF1C40F),
    this.title,
    this.fallbackIcon,
    this.emoji,
  });

  @override
  State<Badge3DViewerWidget> createState() => _Badge3DViewerWidgetState();
}

class _Badge3DViewerWidgetState extends State<Badge3DViewerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vòng hào quang sáng phía sau
          Container(
            width: widget.size * 0.9,
            height: widget.size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.45),
                  blurRadius: widget.size * 0.35,
                  spreadRadius: widget.size * 0.05,
                ),
              ],
            ),
          ),

          // Hiển thị ModelViewer 3D trên Android / iOS / Web
          if (_isSupportedPlatform)
            _buildModelViewer()
          else
            _build3DFallbackAnimation(),

          // Nhãn 3D nhỏ góc dưới nếu ở chế độ compact
          if (widget.isCompact)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Text(
                  '3D',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelViewer() {
    Widget viewer = ModelViewer(
      src: widget.modelGlbPath,
      alt: 'Mô hình 3D ${widget.title ?? "Huy hiệu"}',
      autoRotate: true,
      autoRotateDelay: 0,
      rotationPerSecond: '50deg', // Tự động xoay tròn đều đặn
      cameraControls: !widget.isCompact && widget.interactive,
      disableZoom: widget.isCompact,
      autoPlay: true,
      backgroundColor: Colors.transparent,
      cameraOrbit: '0deg 75deg 105%',
      minCameraOrbit: 'auto auto 70%',
      maxCameraOrbit: 'auto auto 180%',
      shadowIntensity: 0.8,
      shadowSoftness: 0.6,
      interactionPrompt: InteractionPrompt.none,
    );

    // Ở chế độ compact (trong thẻ card), khóa thao tác touch để không cản trở việc cuộn GridView
    if (widget.isCompact) {
      viewer = IgnorePointer(child: viewer);
    }

    return ClipOval(child: viewer);
  }

  /// Animation 3D Fallback (xoay trục Y trong không gian 3D) nếu không chạy WebView
  Widget _build3DFallbackAnimation() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final angle = _rotationController.value * 2 * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective 3D
            ..rotateY(angle),
          child: Container(
            width: widget.size * 0.85,
            height: widget.size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.glowColor.withValues(alpha: 0.3),
                  widget.glowColor.withValues(alpha: 0.8),
                  widget.glowColor,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: widget.emoji != null
                  ? Text(
                      widget.emoji!,
                      style: TextStyle(fontSize: widget.size * 0.45),
                    )
                  : Icon(
                      widget.fallbackIcon ?? Icons.star_rounded,
                      size: widget.size * 0.55,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
