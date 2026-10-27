import 'package:flutter/material.dart';

import 'learning_screens.dart' show ProtectedVideo;
import 'video_widget.dart';
import 'widgets.dart';

Future<void> showCourseLecturesDialog(
  BuildContext context, {
  required String courseId,
  required String courseTitle,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 1100,
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: _CourseLectures(courseId: courseId, courseTitle: courseTitle),
    ),
  ),
);

class _CourseLectures extends StatefulWidget {
  const _CourseLectures({required this.courseId, required this.courseTitle});

  final String courseId;
  final String courseTitle;

  @override
  State<_CourseLectures> createState() => _CourseLecturesState();
}

class _CourseLecturesState extends State<_CourseLectures> {
  String? selectedLessonId;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
        child: Row(
          children: [
            const Icon(Icons.video_library_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bài giảng · ${widget.courseTitle}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Đóng video bài giảng',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ApiView(
          path: '/courses/${widget.courseId}/lessons',
          builder: (data) {
            final lessons = (data as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            if (lessons.isEmpty) {
              return const Center(child: Text('Khóa học chưa có bài giảng.'));
            }
            final selected = lessons.firstWhere(
              (lesson) => lesson['id'] == selectedLessonId,
              orElse: () => lessons.first,
            );
            final lessonList = ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: lesson['id'] == selected['id'],
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  leading: Icon(
                    lesson['hasVideo'] == true
                        ? Icons.play_circle_outline
                        : Icons.description_outlined,
                  ),
                  title: Text(
                    'Bài ${lesson['orderIndex']}: ${lesson['title']}',
                  ),
                  subtitle: lesson['hasVideo'] == true
                      ? null
                      : const Text('Chưa có video'),
                  onTap: () =>
                      setState(() => selectedLessonId = lesson['id'] as String),
                );
              },
            );
            final preview = _LecturePreview(
              key: ValueKey(selected['id']),
              lessonId: selected['id'] as String,
            );
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      SizedBox(height: 170, child: lessonList),
                      const Divider(height: 1),
                      Expanded(child: preview),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 290, child: lessonList),
                    const VerticalDivider(width: 1),
                    Expanded(child: preview),
                  ],
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

class _LecturePreview extends StatelessWidget {
  const _LecturePreview({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: ApiView(
      path: '/lessons/$lessonId',
      builder: (lesson) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson['title'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (lesson['videoAssetId'] != null)
            ProtectedVideo(assetId: lesson['videoAssetId'] as String)
          else if (lesson['videoUrl'] != null)
            ExternalVideo(url: lesson['videoUrl'] as String)
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Bài giảng này chưa có video.'),
            ),
          if ((lesson['practiceInstructions'] as String? ?? '')
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Hướng dẫn thực hành',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(lesson['practiceInstructions'] as String),
          ],
        ],
      ),
    ),
  );
}
