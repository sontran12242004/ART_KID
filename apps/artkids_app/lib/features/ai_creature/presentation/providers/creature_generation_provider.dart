import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/gemini_service.dart';
import '../../data/creature_3d_assets.dart';

/// Trạng thái của luồng sinh creature
enum CreatureGenStatus {
  idle,
  analyzing,     // Đang gửi ảnh cho Gemini phân tích
  generatingModel, // Đang chuẩn bị model 3D/2D
  ready,         // Sẵn sàng hiển thị
  error,
}

/// State chứa kết quả phân tích AI + thông tin model
class CreatureGenState {
  const CreatureGenState({
    this.status = CreatureGenStatus.idle,
    this.analysisResult,
    this.assetInfo,
    this.errorMessage,
  });

  final CreatureGenStatus status;
  final GeminiAnalysisResult? analysisResult;
  final CreatureAssetInfo? assetInfo;
  final String? errorMessage;

  bool get isLoading =>
      status == CreatureGenStatus.analyzing ||
      status == CreatureGenStatus.generatingModel;

  bool get hasResult =>
      status == CreatureGenStatus.ready && analysisResult != null;

  bool get has3dModel => assetInfo?.has3d ?? false;

  CreatureGenState copyWith({
    CreatureGenStatus? status,
    GeminiAnalysisResult? analysisResult,
    CreatureAssetInfo? assetInfo,
    String? errorMessage,
  }) {
    return CreatureGenState(
      status: status ?? this.status,
      analysisResult: analysisResult ?? this.analysisResult,
      assetInfo: assetInfo ?? this.assetInfo,
      errorMessage: errorMessage,
    );
  }
}

/// Quản lý luồng: nhận ảnh → gọi Gemini → map asset → sẵn sàng hiển thị
class CreatureGenNotifier extends StateNotifier<CreatureGenState> {
  CreatureGenNotifier(this._geminiService) : super(const CreatureGenState());

  final GeminiService _geminiService;

  /// Phân tích ảnh vẽ của bé và chuẩn bị model con vật
  Future<GeminiAnalysisResult?> analyzeAndGenerate(Uint8List imageBytes) async {
    state = state.copyWith(
      status: CreatureGenStatus.analyzing,
      errorMessage: null,
    );

    try {
      GeminiAnalysisResult result;

      // Nếu mock mode → trả kết quả giả lập để demo
      if (EnvConfig.enableMockAi) {
        await Future.delayed(const Duration(seconds: 2));
        result = const GeminiAnalysisResult(
          animalType: 'cat',
          displayName: 'Bé Mèo Tinh Nghịch',
          cheeringMessage: 'Woa! Bé vẽ mèo đẹp quá! 🎉 Cô mèo này trông rất đáng yêu!',
          suggestedAnimationId: 'cat_play',
          funFact: 'Mèo có thể xoay tai 180 độ để nghe mọi âm thanh xung quanh!',
          rawResponse: 'mock',
        );
      } else {
        // Gọi Gemini Vision API thật
        result = await _geminiService.analyzeDrawing(
          imageBytes: imageBytes,
          mimeType: 'image/png',
        );
      }

      // Chuẩn bị model 3D/2D
      state = state.copyWith(status: CreatureGenStatus.generatingModel);

      // Simulate loading model (trong thực tế model_viewer tự load từ URL)
      await Future.delayed(const Duration(milliseconds: 500));

      final assetInfo = Creature3dAssets.getAsset(result.animalType);

      state = CreatureGenState(
        status: CreatureGenStatus.ready,
        analysisResult: result,
        assetInfo: assetInfo,
      );

      return result;
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        final serverMsg = e.response?.data?['error']?['message'] ?? e.response?.data;
        msg = 'Mã ${e.response?.statusCode}: ${serverMsg ?? e.message}';
      }
      state = CreatureGenState(
        status: CreatureGenStatus.error,
        errorMessage: 'Ôi! AI chưa nhận ra con vật. Bé thử vẽ lại nhé! 🎨\n($msg)',
      );
      return null;
    }
  }

  /// Reset về trạng thái ban đầu
  void reset() {
    state = const CreatureGenState();
  }
}

/// Provider cho creature generation flow
final creatureGenProvider =
    StateNotifierProvider<CreatureGenNotifier, CreatureGenState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return CreatureGenNotifier(geminiService);
});
