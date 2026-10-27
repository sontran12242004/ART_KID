import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../data/connected_api.dart';
import '../data/lecture_video_uploader.dart';
import 'widgets.dart';

Future<void> showLectureUploadDialog(
  BuildContext context, {
  required String courseId,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: SizedBox(width: 620, child: LectureUploadForm(courseId: courseId)),
  ),
);

class LectureUploadForm extends ConsumerStatefulWidget {
  const LectureUploadForm({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<LectureUploadForm> createState() => _LectureUploadFormState();
}

class _LectureUploadFormState extends ConsumerState<LectureUploadForm> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final instructions = TextEditingController();
  final order = TextEditingController();
  final uploader = LectureVideoUploader();
  XFile? file;
  Map<String, dynamic>? session;
  CancelToken? cancelToken;
  bool busy = false;
  bool uploaded = false;
  bool orderEdited = false;
  double progress = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    _suggestOrder();
  }

  Future<void> _suggestOrder() async {
    try {
      final response = await ref
          .read(dioProvider)
          .get<List<dynamic>>('/courses/${widget.courseId}/lessons');
      final maximum = (response.data ?? []).fold<int>(
        0,
        (value, row) => (row['orderIndex'] as int) > value
            ? row['orderIndex'] as int
            : value,
      );
      if (mounted && !orderEdited && order.text.isEmpty) {
        order.text = '${maximum + 1}';
      }
    } catch (_) {
      if (mounted && !orderEdited && order.text.isEmpty) {
        order.text = '1';
      }
    }
  }

  @override
  void dispose() {
    cancelToken?.cancel();
    uploader.dispose();
    title.dispose();
    instructions.dispose();
    order.dispose();
    super.dispose();
  }

  Future<void> _pick(int maximum) async {
    final selected = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (selected == null) return;
    final length = await selected.length();
    if (!mounted) return;
    if (!selected.name.toLowerCase().endsWith('.mp4') ||
        length <= 0 ||
        length > maximum) {
      setState(
        () => error =
            'Chọn video MP4 có dung lượng tối đa ${(maximum / 1000000).floor()} MB.',
      );
      return;
    }
    setState(() {
      file = selected;
      session = null;
      uploaded = false;
      progress = 0;
      error = null;
    });
  }

  Future<void> _save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (file == null) {
      setState(() => error = 'Hãy chọn video bài giảng.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    cancelToken = CancelToken();
    try {
      final dio = ref.read(dioProvider);
      final path = '/courses/${widget.courseId}/lessons/video-upload';
      if (session == null) {
        final result = await dio.post<dynamic>(
          path,
          data: {'fileName': file!.name, 'sizeBytes': await file!.length()},
        );
        session = Map<String, dynamic>.from(result.data);
      }
      if (!uploaded) {
        await uploader.upload(
          file: file!,
          session: session!,
          cancelToken: cancelToken!,
          onProgress: (value) {
            if (mounted) setState(() => progress = value.clamp(0, 1));
          },
        );
        uploaded = true;
      }
      if (cancelToken!.isCancelled) {
        throw cancelToken!.cancelError!;
      }
      await dio.post<dynamic>(
        '$path/complete',
        data: {
          'uploadToken': session!['uploadToken'],
          'title': title.text.trim(),
          'orderIndex': int.parse(order.text.trim()),
          'practiceInstructions': instructions.text.trim(),
        },
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      ref.invalidate(apiDataProvider('/courses/${widget.courseId}/lessons'));
      if (mounted) {
        toast(context, 'Đã lưu bài giảng.');
        Navigator.of(context).pop();
      }
    } catch (exception) {
      if (mounted) {
        setState(
          () => error =
              exception is DioException && CancelToken.isCancel(exception)
              ? 'Đã dừng tải. Bạn có thể thử lại.'
              : apiError(exception),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm bài giảng',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: title,
              enabled: !busy,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Tên bài giảng',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nhập tên bài giảng.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: order,
              onChanged: (_) => orderEdited = true,
              enabled: !busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thứ tự bài giảng',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final number = int.tryParse(value?.trim() ?? '');
                return number == null || number < 0 || number > 1000
                    ? 'Nhập thứ tự từ 0 đến 1000.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: instructions,
              enabled: !busy,
              minLines: 2,
              maxLines: 4,
              maxLength: 10000,
              decoration: const InputDecoration(
                labelText: 'Hướng dẫn thực hành',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ApiView(
              path: '/media/video-storage',
              builder: (status) {
                final ready = status['isConfigured'] == true;
                final maximum = (status['maxUploadBytes'] as num).toInt();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!ready)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Chưa thiết lập nơi lưu video. Vui lòng liên hệ quản trị viên.',
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: busy || !ready ? null : () => _pick(maximum),
                      icon: const Icon(Icons.video_file_outlined),
                      label: Text(file?.name ?? 'Chọn video MP4'),
                    ),
                    Text(
                      'Dung lượng tối đa ${(maximum / 1000000).floor()} MB.',
                    ),
                    if (busy) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress < 1 ? progress : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progress < 1
                            ? 'Đang tải video: ${(progress * 100).floor()}%'
                            : 'Đang xác minh và lưu bài giảng…',
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: busy
                              ? () => cancelToken?.cancel()
                              : () => Navigator.of(context).pop(),
                          child: Text(busy ? 'Dừng tải' : 'Đóng'),
                        ),
                        FilledButton.icon(
                          onPressed: busy || !ready ? null : _save,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            uploaded
                                ? 'Lưu bài giảng'
                                : 'Tải video & lưu bài giảng',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
