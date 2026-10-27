import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService {
  VoiceGuidanceService() {
    _initTts();
  }

  final FlutterTts _tts = FlutterTts();
  bool _isReady = false;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('vi-VN');
      await _tts.setSpeechRate(0.45); // Slower, friendlier rate for children
      await _tts.setPitch(
        1.2,
      ); // Slightly higher pitch for cute friendly kid guide voice
      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!_isReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final voiceGuidanceServiceProvider = Provider<VoiceGuidanceService>((ref) {
  return VoiceGuidanceService();
});
