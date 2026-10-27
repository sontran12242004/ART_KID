import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../matching_game/presentation/widgets/drawing_canvas.dart';
import '../data/connected_api.dart';
import 'widgets.dart';

class LessonDrawingSection extends ConsumerStatefulWidget {
  const LessonDrawingSection({
    super.key,
    required this.lessonId,
    required this.childId,
    required this.childName,
  });

  final String lessonId;
  final String childId;
  final String childName;

  @override
  ConsumerState<LessonDrawingSection> createState() =>
      _LessonDrawingSectionState();
}

class _LessonDrawingSectionState extends ConsumerState<LessonDrawingSection> {
  final canvas = GlobalKey<DrawingCanvasState>();
  bool busy = false;
  bool hasDrawing = false;
  String? assetId;
  String? submissionId;
  String? error;

  void _changed() => setState(() {
    hasDrawing = canvas.currentState?.hasDrawn ?? false;
    assetId = null;
    submissionId = null;
    error = null;
  });

  Future<void> _clear() async {
    if (await confirm(
      context,
      'Vẽ lại từ đầu?',
      'Các nét vẽ hiện tại sẽ được xóa để bé vẽ tranh mới.',
    )) {
      if (mounted) canvas.currentState?.clear();
    }
  }

  Future<bool> _confirmSubmission(Uint8List png) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Nộp bài của ${widget.childName}?'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(png, height: 180, fit: BoxFit.contain),
                const SizedBox(height: 12),
                const Text(
                  'Đồng ý lưu bức tranh này và gửi cho giáo viên phụ trách bài học xem, chấm điểm và nhận xét?',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vẽ tiếp'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận nộp bài'),
            ),
          ],
        ),
      ) ??
      false;

  Future<Map<String, dynamic>> _send(Dio dio, String imageId) async {
    try {
      final response = await dio.post<dynamic>(
        '/kid/submissions',
        data: {
          'childId': widget.childId,
          'lessonId': widget.lessonId,
          'imageAssetId': imageId,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 409 ||
          exception.type == DioExceptionType.receiveTimeout ||
          exception.type == DioExceptionType.connectionError) {
        final response = await dio.get<List<dynamic>>(
          '/kid/submissions?childId=${widget.childId}&pageSize=100',
        );
        for (final raw in response.data ?? []) {
          final row = Map<String, dynamic>.from(raw);
          if (row['imageAssetId'] == imageId &&
              row['lessonId'] == widget.lessonId) {
            return row;
          }
        }
      }
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (busy ||
        submissionId != null ||
        !(canvas.currentState?.hasDrawn ?? false)) {
      return;
    }
    if (ref.read(authProvider).selectedChild?.id != widget.childId) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final png = await canvas.currentState!.exportPng();
      if (!mounted || !await _confirmSubmission(png)) return;
      if (!mounted ||
          ref.read(authProvider).selectedChild?.id != widget.childId) {
        return;
      }
      final dio = ref.read(dioProvider);
      await dio.post<dynamic>(
        '/auth/consent',
        data: {
          'childId': widget.childId,
          'purpose': 'data_processing',
          'policyVersion': '2026-01',
        },
      );
      if (assetId == null) {
        final upload = await dio.post<dynamic>(
          '/media/upload',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              png,
              filename: 'lesson-${widget.lessonId}.png',
            ),
            'kind': 'drawing',
            'childId': widget.childId,
          }),
        );
        assetId = upload.data['id'] as String;
      }
      final saved = await _send(dio, assetId!);
      if (mounted) {
        ref.invalidate(apiDataProvider);
        setState(() => submissionId = saved['id'] as String);
        toast(context, 'Đã nộp bài vẽ của ${widget.childName}!');
      }
    } catch (exception) {
      if (mounted) setState(() => error = apiError(exception));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Góc vẽ của ${widget.childName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Chọn màu rồi vẽ nhé! Bé có thể vừa xem video vừa vẽ.'),
          const SizedBox(height: 4),
          Expanded(
            child: AbsorbPointer(
              absorbing: busy,
              child: DrawingCanvas(
                key: canvas,
                showActions: false,
                onFinish: _submit,
                onChanged: _changed,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: busy || !hasDrawing
                    ? null
                    : () => canvas.currentState?.undo(),
                icon: const Icon(Icons.undo),
                label: const Text('Hoàn tác'),
              ),
              OutlinedButton.icon(
                onPressed: busy || !hasDrawing ? null : _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Vẽ lại'),
              ),
              FilledButton.icon(
                onPressed: busy || !hasDrawing || submissionId != null
                    ? null
                    : _submit,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  busy
                      ? 'Đang gửi bài…'
                      : submissionId != null
                      ? 'Đã nộp bài'
                      : 'Nộp bài vẽ',
                ),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (submissionId != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Đã gửi tranh cho giáo viên. Bé có thể xem điểm và nhận xét khi giáo viên chấm xong.',
            ),
            TextButton.icon(
              onPressed: () => context.push('/submissions/$submissionId'),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Xem bài đã nộp'),
            ),
          ],
        ],
      ),
    ),
  );
}
