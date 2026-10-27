import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_source_stub.dart'
    if (dart.library.js_interop) 'video_source_web.dart'
    as source;

class MemoryVideo extends StatelessWidget {
  const MemoryVideo({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => ExternalVideo(bytes: bytes);
}

class ExternalVideo extends StatefulWidget {
  const ExternalVideo({
    super.key,
    this.url,
    this.bytes,
    this.maxVideoHeight = double.infinity,
  });
  final String? url;
  final Uint8List? bytes;
  final double maxVideoHeight;
  @override
  State<ExternalVideo> createState() => _ExternalVideoState();
}

class _ExternalVideoState extends State<ExternalVideo> {
  VideoPlayerController? controller;
  String? blob;
  String? error;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      blob = widget.bytes == null ? null : source.create(widget.bytes!);
      controller = blob != null
          ? source.player(blob!)
          : VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      await controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = 'Không phát được video: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    if (blob != null) source.release(blob!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) return Text(error!);
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxVideoHeight),
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        VideoProgressIndicator(c, allowScrubbing: true),
        IconButton(
          tooltip: 'Phát / Tạm dừng',
          onPressed: () {
            setState(() {
              c.value.isPlaying ? c.pause() : c.play();
            });
          },
          icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
      ],
    );
  }
}
