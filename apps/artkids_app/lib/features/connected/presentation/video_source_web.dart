import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:video_player/video_player.dart';

String create(Uint8List bytes) => web.URL.createObjectURL(
  web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'video/mp4')),
);
void release(String url) => web.URL.revokeObjectURL(url);
VideoPlayerController player(String url) =>
    VideoPlayerController.networkUrl(Uri.parse(url));
