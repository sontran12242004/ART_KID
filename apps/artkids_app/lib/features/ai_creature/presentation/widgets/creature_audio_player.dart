import 'package:flutter/material.dart';

/// Phát âm thanh đặc trưng loài — just_audio
class CreatureAudioPlayer extends StatelessWidget {
  const CreatureAudioPlayer({super.key, required this.creatureId});

  final String creatureId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 64,
      icon: const Icon(Icons.volume_up),
      onPressed: () {
        // TODO: just_audio play từ CDN URL
      },
    );
  }
}
