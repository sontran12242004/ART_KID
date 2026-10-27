import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_interceptor.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/connected_api.dart';
import 'widgets.dart';
import 'video_widget.dart';
import 'lesson_drawing_section.dart';
import 'grading_screens.dart';
import 'family_submission_browser.dart';
import 'submission_artwork.dart';

class ConnectedCourses extends ConsumerWidget {
  const ConnectedCourses({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Khóa học vẽ')),
    body: ApiView(
      path: '/courses?pageSize=100',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in data['items'])
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['title'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(c['description'] ?? ''),
                    Text(money(c['priceVnd'])),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push(
                            '/parent/courses/${c['id']}/products',
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Học cụ cho khóa học'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push('/kid/course/${c['id']}/lessons'),
                          child: const Text('Xem bài học'),
                        ),
                        if (c['priceVnd'] == 0)
                          ActionButton(
                            label: 'Đăng ký cho bé',
                            action: (r) {
                              final id = r.read(authProvider).selectedChild?.id;
                              if (id == null) {
                                throw Exception('Hãy thêm hồ sơ bé trước.');
                              }
                              return r
                                  .read(dioProvider)
                                  .post(
                                    '/enrollments',
                                    data: {'childId': id, 'courseId': c['id']},
                                  );
                            },
                          ),
                        if (c['priceVnd'] > 0)
                          TextButton(
                            onPressed: () => context.push(
                              '/parent/shop/checkout?type=course&id=${c['id']}',
                            ),
                            child: const Text('Mua khóa học'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ConnectedLessons extends ConsumerWidget {
  const ConnectedLessons({super.key, required this.courseId});
  final String courseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Bài học')),
    body: ApiView(
      path:
          '/courses/$courseId/lessons?childId=${ref.watch(authProvider).selectedChild?.id ?? ''}',
      builder: (data) => ListView(
        children: [
          for (final l in data)
            ListTile(
              leading: Icon(
                l['completed'] == true ? Icons.check_circle : Icons.play_circle,
                color: l['completed'] == true ? Colors.green.shade700 : null,
              ),
              title: Text(l['title']),
              subtitle: l['completed'] == true
                  ? Text(
                      'Đã hoàn thành',
                      style: TextStyle(color: Colors.green.shade700),
                    )
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/kid/lesson/${l['id']}'),
            ),
        ],
      ),
    ),
  );
}

class ConnectedLesson extends ConsumerWidget {
  const ConnectedLesson({super.key, required this.lessonId});
  final String lessonId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(authProvider).selectedChild;
    return Scaffold(
      appBar: AppBar(title: const Text('Học vẽ')),
      body: ApiView(
        path: '/lessons/$lessonId?childId=${child?.id ?? ''}',
        builder: (l) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Padding(
              padding: EdgeInsets.all(wide ? 20 : 8),
              child: Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: wide
                        ? (constraints.maxWidth * .36).clamp(280, 480)
                        : null,
                    height: wide
                        ? null
                        : (constraints.maxHeight * .33).clamp(150, 250),
                    child: Card(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l['title'],
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            if (l['videoAssetId'] != null)
                              ProtectedVideo(
                                key: ValueKey(l['id']),
                                assetId: l['videoAssetId'],
                                maxVideoHeight: wide ? double.infinity : 120,
                              )
                            else if (l['videoUrl'] != null)
                              ExternalVideo(
                                key: ValueKey(l['id']),
                                url: l['videoUrl'],
                                maxVideoHeight: wide ? double.infinity : 120,
                              )
                            else
                              const Text(
                                'Giảng viên chưa tải video cho bài học này.',
                              ),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('Hướng dẫn thực hành'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(l['practiceInstructions'] ?? ''),
                                ),
                              ],
                            ),
                            if (l['completed'] == true) ...[
                              const ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.check_circle,
                                  color: Colors.teal,
                                ),
                                title: Text('Bé đã hoàn thành bài học!'),
                              ),
                              FilledButton.icon(
                                onPressed: () => context.pushReplacement(
                                  l['nextLessonId'] != null
                                      ? '/kid/lesson/${l['nextLessonId']}'
                                      : '/kid/course/${l['courseId']}/lessons',
                                ),
                                icon: Icon(
                                  l['nextLessonId'] != null
                                      ? Icons.arrow_forward_rounded
                                      : Icons.menu_book_rounded,
                                ),
                                label: Text(
                                  l['nextLessonId'] != null
                                      ? 'Bài tiếp theo'
                                      : 'Về danh sách bài học',
                                ),
                              ),
                            ] else if (child != null)
                              ActionButton(
                                enabled: l['hasSubmission'] == true,
                                label: 'Đánh dấu hoàn thành',
                                action: (r) => r
                                    .read(dioProvider)
                                    .post(
                                      '/courses/progress',
                                      data: {
                                        'childId': child.id,
                                        'lessonId': lessonId,
                                        'status': 'completed',
                                        'learningSeconds': 0,
                                      },
                                    ),
                              ),
                            if (child != null &&
                                l['hasSubmission'] != true &&
                                l['completed'] != true)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Bé hãy nộp bài vẽ canvas hoặc ảnh bài trên giấy để mở nút hoàn thành nhé!',
                                ),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/kid/lesson/$lessonId/submit'),
                              icon: const Icon(Icons.upload),
                              label: const Text('Nộp ảnh bài vẽ trên giấy'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 8),
                  if (child != null)
                    Expanded(
                      child: LessonDrawingSection(
                        key: ValueKey('$lessonId-${child.id}'),
                        lessonId: lessonId,
                        childId: child.id,
                        childName: child.nickname,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// The player obtains private media through the authenticated HTTP client.
class ProtectedVideo extends ConsumerWidget {
  const ProtectedVideo({
    super.key,
    required this.assetId,
    this.maxVideoHeight = double.infinity,
  });
  final String assetId;
  final double maxVideoHeight;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(
        mediaBytesProvider(
          '/media/$assetId?childId=${ref.watch(authProvider).selectedChild?.id ?? ""}',
        ),
      )
      .when(
        data: (bytes) =>
            ExternalVideo(bytes: bytes, maxVideoHeight: maxVideoHeight),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(apiError(e)),
      );
}

class SubmissionUpload extends ConsumerStatefulWidget {
  const SubmissionUpload({super.key, required this.lessonId});
  final String lessonId;
  @override
  ConsumerState<SubmissionUpload> createState() => _SubmissionUploadState();
}

class _SubmissionUploadState extends ConsumerState<SubmissionUpload> {
  Uint8List? bytes;
  String filename = 'drawing.png';
  String? asset;
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nộp bài vẽ')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Chọn ảnh PNG hoặc JPEG từ thiết bị. Bài vẽ được lưu riêng cho hồ sơ bé và gửi giáo viên phụ trách khóa học.',
        ),
        const SizedBox(height: 16),
        if (bytes != null) Image.memory(bytes!, height: 280),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (f == null) return;
                  final b = await f.readAsBytes();
                  if (mounted) {
                    setState(() {
                      bytes = b;
                      filename = f.name;
                      asset = null;
                    });
                  }
                },
          icon: const Icon(Icons.photo),
          label: const Text('Chọn ảnh bài vẽ'),
        ),
        FilledButton(
          onPressed: bytes == null || busy ? null : submit,
          child: Text(busy ? 'Đang gửi bài…' : 'Gửi bài cho giáo viên'),
        ),
      ],
    ),
  );
  Future<void> submit() async {
    final child = ref.read(authProvider).selectedChild;
    if (child == null) return;
    if (!await confirm(
      context,
      'Cho phép lưu bài vẽ',
      'Bạn đồng ý lưu ảnh bài vẽ của ${child.nickname} để giáo viên xem và nhận xét?',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/auth/consent',
        data: {
          'childId': child.id,
          'purpose': 'data_processing',
          'policyVersion': '2026-01',
        },
      );
      asset ??= (await dio.post(
        '/media/upload',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes!, filename: filename),
          'kind': 'drawing',
          'childId': child.id,
        }),
      )).data['id'];
      await dio.post(
        '/kid/submissions',
        data: {
          'childId': child.id,
          'imageAssetId': asset,
          'lessonId': widget.lessonId,
        },
      );
      ref.invalidate(apiDataProvider);
      if (mounted) {
        toast(context, 'Đã nộp bài. Bạn có thể xem nhận xét trong Bài vẽ.');
        context.go('/parent/submissions');
      }
    } catch (e) {
      if (mounted) toast(context, apiError(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class SubmissionsScreen extends ConsumerWidget {
  const SubmissionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(authProvider).currentUser?.role == 'parent'
      ? const FamilySubmissionBrowser()
      : const GradingCoursesScreen();
}

class SubmissionDetail extends ConsumerWidget {
  const SubmissionDetail({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Bài vẽ và đánh giá')),
    body: ApiView(
      path: '/kid/submissions/$id',
      builder: (data) {
        final s = data['submission'];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (data['child'] != null)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.face)),
                  title: Text(
                    '${data['child']['nickname']} · ${DateTime.now().year - (data['child']['birthYear'] as int)} tuổi',
                  ),
                  subtitle: Text(
                    'Mã bé: ${data['child']['id']}\nNộp lúc ${dateLabel(s['createdAt'])} · ${statusLabel(s['status'])}',
                  ),
                ),
              ),
            SubmissionArtwork(assetId: s['imageAssetId']),
            for (final review in data['reviews'])
              Card(
                child: ListTile(
                  title: Text('${review['score']}/10'),
                  subtitle: Text(review['feedback']),
                ),
              ),
            if (ref.watch(authProvider).currentUser?.role != 'parent')
              FilledButton(
                onPressed: () async {
                  final v = await askFields(context, 'Chấm bài', [
                    const EntryField('score', 'Điểm (0–10)', number: true),
                    const EntryField('feedback', 'Nhận xét'),
                  ]);
                  if (v != null && context.mounted) {
                    await mutate(context, ref, '/kid/submissions/$id/reviews', {
                      'score': num.parse(v['score']!),
                      'feedback': v['feedback'],
                    });
                  }
                },
                child: const Text('Chấm điểm & nhận xét'),
              ),
          ],
        );
      },
    ),
  );
}
