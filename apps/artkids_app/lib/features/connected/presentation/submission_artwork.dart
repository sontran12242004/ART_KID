import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_interceptor.dart';
import '../data/connected_api.dart';

class SubmissionArtwork extends ConsumerWidget {
  const SubmissionArtwork({super.key, required this.assetId});
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(mediaBytesProvider('/media/$assetId'))
      .when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Không tải được ảnh bài vẽ. ${apiError(error)}'),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(mediaBytesProvider('/media/$assetId')),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (bytes) => _ArtworkPreview(key: ValueKey(assetId), bytes: bytes),
      );
}

class _ArtworkPreview extends StatefulWidget {
  const _ArtworkPreview({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<_ArtworkPreview> createState() => _ArtworkPreviewState();
}

class _ArtworkPreviewState extends State<_ArtworkPreview> {
  String? error;
  Size? dimensions;

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  Future<void> _inspect() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      try {
        final frame = await codec.getNextFrame();
        final size = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        frame.image.dispose();
        if (mounted) setState(() => dimensions = size);
      } finally {
        codec.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'File ảnh của bài nộp không đọc được. Vui lòng yêu cầu nộp lại ảnh.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = dimensions;
    if (error != null ||
        (size != null && (size.width <= 1 || size.height <= 1))) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.image_not_supported_outlined, size: 40),
              const SizedBox(height: 12),
              Text(
                error ??
                    'Ảnh bài nộp chỉ có kích thước ${size!.width.toInt()} × ${size.height.toInt()} pixel, không có nội dung tranh để xem.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng mở bài canvas khác hoặc yêu cầu bé nộp lại ảnh bài vẽ đầy đủ.',
              ),
            ],
          ),
        ),
      );
    }
    if (size == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('Bài vẽ đã nộp')),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => Dialog(
                      insetPadding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Xem bài vẽ · Cuộn hoặc chụm để phóng to',
                                ),
                              ),
                              IconButton(
                                tooltip: 'Đóng ảnh',
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ColoredBox(
                              color: Colors.white,
                              child: InteractiveViewer(
                                minScale: .5,
                                maxScale: 6,
                                child: Center(
                                  child: Image.memory(
                                    widget.bytes,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'Ảnh bài vẽ phóng to',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('Phóng to'),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: (MediaQuery.sizeOf(context).height * .55).clamp(260, 600),
              child: ColoredBox(
                color: Colors.white,
                child: Image.memory(
                  widget.bytes,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ảnh bài vẽ đã nộp',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
