import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/network/gemini_service.dart';
import '../../data/creature_3d_assets.dart';
import '../providers/creature_provider.dart';
import '../widgets/creature_animation_player.dart';
import '../widgets/creature_audio_player.dart';

/// Màn hình hiển thị con vật 3D/2D sau khi AI nhận diện thành công.
///
/// Hỗ trợ 2 modes:
/// 1. **AI Generated**: nhận `GeminiAnalysisResult` qua GoRouter extra
///    → hiển thị model 3D + thông tin con vật ngay lập tức
/// 2. **From Collection**: nhận `creatureId` → load từ API
///    → hiển thị con vật đã lưu trong bộ sưu tập
class CreatureViewerScreen extends ConsumerWidget {
  const CreatureViewerScreen({
    super.key,
    required this.creatureId,
    this.analysisResult,
  });

  final String creatureId;

  /// Kết quả phân tích AI — nếu có, hiển thị trực tiếp không cần load từ API
  final GeminiAnalysisResult? analysisResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (analysisResult != null) {
      return _buildFromAiResult(context, analysisResult!);
    }

    // Fallback: load từ API theo creatureId (bộ sưu tập)
    final creatureAsync = ref.watch(creatureDetailProvider(creatureId));
    return creatureAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFFFF9EE),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: KidUiConstants.primaryKid,
                strokeWidth: 5,
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải con vật...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFFFF9EE),
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😔', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Không tải được con vật: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(creatureDetailProvider(creatureId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
      data: (creature) {
        final asset = Creature3dAssets.getAsset(creature.animalType);
        return _buildViewerScaffold(
          context: context,
          animalType: creature.animalType,
          displayName: asset.nameVi,
          cheeringMessage: null,
          funFact: null,
          asset: asset,
          creatureId: creature.id,
        );
      },
    );
  }

  /// Build từ kết quả AI (sau khi bé vẽ + gửi thành công)
  Widget _buildFromAiResult(BuildContext context, GeminiAnalysisResult result) {
    final asset = Creature3dAssets.getAsset(result.animalType);
    return _buildViewerScaffold(
      context: context,
      animalType: result.animalType,
      displayName: result.displayName,
      cheeringMessage: result.cheeringMessage,
      funFact: result.funFact,
      asset: asset,
      creatureId: null,
    );
  }

  Widget _buildViewerScaffold({
    required BuildContext context,
    required String animalType,
    required String displayName,
    String? cheeringMessage,
    String? funFact,
    required CreatureAssetInfo asset,
    String? creatureId,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header với nút back + tên con vật
            _buildHeader(context, displayName, asset),

            // Khung hiển thị 3D/2D con vật — ưu tiên độ rộng tối đa để con vật di chuyển rộng rãi
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Color(asset.color).withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CreatureAnimationPlayer(
                      animalType: animalType,
                      assetInfo: asset,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Thông tin con vật (lời khen + fun fact)
            Expanded(
              flex: 4,
              child: _buildInfoSection(
                context,
                displayName: displayName,
                cheeringMessage: cheeringMessage,
                funFact: funFact,
                asset: asset,
                creatureId: creatureId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header gradient với emoji + tên con vật
  Widget _buildHeader(
    BuildContext context,
    String displayName,
    CreatureAssetInfo asset,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Nút back
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(asset.color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Color(asset.color),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Emoji + tên con vật
          Text(
            asset.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: KidUiConstants.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Badge 3D nếu có model 3D
          if (asset.has3d)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(asset.color),
                    Color(asset.color).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '3D',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Phần thông tin bên dưới: lời khen, fun fact, nút phát âm thanh
  Widget _buildInfoSection(
    BuildContext context, {
    required String displayName,
    String? cheeringMessage,
    String? funFact,
    required CreatureAssetInfo asset,
    String? creatureId,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lời khen ngợi từ AI
          if (cheeringMessage != null && cheeringMessage.isNotEmpty)
            _buildInfoCard(
              icon: '🎉',
              title: 'AI nói gì?',
              content: cheeringMessage.replaceAll('"', '').trim(),
              color: KidUiConstants.primaryKid,
            ),

          if (funFact != null && funFact.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: '💡',
              title: 'Bạn có biết?',
              content: funFact.replaceAll('"', '').trim(),
              color: KidUiConstants.secondaryKid,
            ),
          ],

          const SizedBox(height: 12),

          // Row nút hành động
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nút phát âm thanh
              if (creatureId != null)
                CreatureAudioPlayer(creatureId: creatureId),

              // Nút vẽ lại
              _buildActionButton(
                context: context,
                icon: Icons.brush_rounded,
                label: 'Vẽ lại',
                color: KidUiConstants.primaryKid,
                onTap: () => Navigator.of(context).pop(),
              ),

              // Nút chia sẻ (placeholder)
              _buildActionButton(
                context: context,
                icon: Icons.share_rounded,
                label: 'Chia sẻ',
                color: const Color(0xFF6C5CE7),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng chia sẻ sắp ra mắt! 🚀'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Card thông tin (lời khen, fun fact)
  Widget _buildInfoCard({
    required String icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 18,
              color: KidUiConstants.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Nút hành động tròn
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
