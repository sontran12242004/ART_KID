import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'matching_game_config.dart';

/// Dịch vụ phát âm thanh hiệu ứng cho mini-game
class GameAudioService {
  GameAudioService._();
  static final GameAudioService instance = GameAudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// Phát âm thanh "bốp" nhẹ khi nhấc/thả sticker
  Future<void> playPop() async {
    await _playAsset(MatchingGameConfig.audioPop);
  }

  /// Phát âm thanh chuông mừng khi bé vẽ xong 1 con vật
  Future<void> playSuccess() async {
    await _playAsset(MatchingGameConfig.audioSuccess);
  }

  /// Phát nhạc ăn mừng lớn khi hoàn thành ghép cả 3 con vật
  Future<void> playCelebration() async {
    await _playAsset(MatchingGameConfig.audioCelebration);
  }

  Future<void> _playAsset(String assetPath) async {
    try {
      if (_player.playing) {
        await _player.stop();
      }
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      debugPrint('GameAudioService - không thể phát audio: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
