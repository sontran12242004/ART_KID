import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../data/creature_3d_assets.dart';
import 'animated_creature_widget.dart';

/// Hiển thị animation 2D (AnimatedCreatureWidget) hoặc model 3D (model_viewer_plus)
///
/// - Nếu có URL model 3D GLB → hiển thị ModelViewer 3D với auto-rotate + camera controls
/// - Nếu không có model 3D → fallback AnimatedCreatureWidget (emoji di chuyển + sparkles)
class CreatureAnimationPlayer extends StatelessWidget {
  const CreatureAnimationPlayer({
    super.key,
    required this.animalType,
    this.assetInfo,
  });

  final String animalType;
  final CreatureAssetInfo? assetInfo;

  @override
  Widget build(BuildContext context) {
    final asset = assetInfo ?? Creature3dAssets.getAsset(animalType);

    if (asset.has3d) {
      return _build3dViewer(asset);
    } else {
      return _build2dAnimation(asset);
    }
  }

  /// Model 3D viewer bằng model_viewer_plus (WebView-based)
  Widget _build3dViewer(CreatureAssetInfo asset) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(asset.color).withValues(alpha: 0.05),
              Color(asset.color).withValues(alpha: 0.15),
            ],
          ),
        ),
        child: ModelViewer(
          src: asset.glbUrl!,
          alt: 'Mô hình 3D ${asset.nameVi}',
          autoRotate: true,
          autoRotateDelay: 0,
          rotationPerSecond: '30deg',
          cameraControls: true,
          disableZoom: false,
          animationName: null, // Tự động chạy animation đầu tiên nếu có
          autoPlay: true,
          backgroundColor: Colors.transparent,
          cameraOrbit: '0deg 75deg 105%',
          minCameraOrbit: 'auto auto 50%',
          maxCameraOrbit: 'auto auto 200%',
          shadowIntensity: 1,
          shadowSoftness: 0.8,
          interactionPrompt: InteractionPrompt.auto,
          interactionPromptThreshold: 500,
        ),
      ),
    );
  }

  /// Animated 2D fallback — emoji di chuyển + sparkles
  Widget _build2dAnimation(CreatureAssetInfo asset) {
    return SizedBox.expand(
      child: AnimatedCreatureWidget(
        emoji: asset.emoji,
        creatureColor: Color(asset.color),
        displayName: asset.nameVi,
      ),
    );
  }
}
