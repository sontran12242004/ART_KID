import 'dart:typed_data';
import 'dart:io';
import 'package:video_player/video_player.dart';

String create(Uint8List bytes) {
  final file = File(
    '${Directory.systemTemp.path}/artkids-video-${DateTime.now().microsecondsSinceEpoch}.mp4',
  );
  file.writeAsBytesSync(bytes, flush: true);
  return file.path;
}

VideoPlayerController player(String path) =>
    VideoPlayerController.file(File(path));
void release(String path) {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
}
