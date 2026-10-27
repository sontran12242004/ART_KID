import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets.dart';

class GradingCoursesScreen extends StatelessWidget {
  const GradingCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chấm bài · Khóa học')),
    body: ApiView(
      path: '/grading/courses',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Chọn khóa học để xem bài học và bài vẽ đang chờ chấm.',
            ),
          ),
          if ((data as List).isEmpty)
            const ListTile(title: Text('Chưa có khóa học được phân công.')),
          for (final course in data)
            Card(
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(course['title']),
                subtitle: Text(
                  '${course['lessonCount']} bài học · ${course['pendingCount']} bài cần chấm',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/staff/grading/courses/${course['id']}'),
              ),
            ),
        ],
      ),
    ),
  );
}

class GradingLessonsScreen extends StatelessWidget {
  const GradingLessonsScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chấm bài · Bài học')),
    body: ApiView(
      path: '/grading/courses/$courseId/lessons',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              data['courseTitle'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if ((data['lessons'] as List).isEmpty)
            const ListTile(title: Text('Khóa học chưa có bài học.')),
          for (final lesson in data['lessons'])
            Card(
              child: ListTile(
                leading: Icon(
                  lesson['pendingCount'] > 0
                      ? Icons.rate_review_outlined
                      : Icons.check_circle_outline,
                  color: lesson['pendingCount'] > 0
                      ? Colors.orange.shade800
                      : Colors.teal,
                ),
                title: Text('Bài ${lesson['orderIndex']}: ${lesson['title']}'),
                subtitle: Text(
                  '${lesson['pendingCount']} bài cần chấm · ${lesson['totalCount']} bài đã nộp',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/staff/grading/lessons/${lesson['id']}'),
              ),
            ),
        ],
      ),
    ),
  );
}

class GradingSubmissionsScreen extends StatefulWidget {
  const GradingSubmissionsScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  State<GradingSubmissionsScreen> createState() =>
      _GradingSubmissionsScreenState();
}

class _GradingSubmissionsScreenState extends State<GradingSubmissionsScreen> {
  bool pendingOnly = true;
  int page = 1;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bài vẽ học sinh')),
    body: ApiView(
      path:
          '/grading/lessons/${widget.lessonId}/submissions?pendingOnly=$pendingOnly&page=$page',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            data['courseTitle'],
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            data['lessonTitle'],
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Cần chấm'),
                selected: pendingOnly,
                onSelected: (_) => setState(() {
                  pendingOnly = true;
                  page = 1;
                }),
              ),
              ChoiceChip(
                label: const Text('Tất cả bài nộp'),
                selected: !pendingOnly,
                onSelected: (_) => setState(() {
                  pendingOnly = false;
                  page = 1;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${data['total']} ${pendingOnly ? 'bài cần chấm' : 'bài đã nộp'}',
          ),
          if ((data['items'] as List).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                pendingOnly
                    ? 'Không có bài vẽ đang chờ chấm.'
                    : 'Chưa có bài vẽ được nộp.',
              ),
            ),
          for (final submission in data['items'])
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.face)),
                title: Text(
                  '${submission['childName']} · ${DateTime.now().year - (submission['birthYear'] as int)} tuổi',
                ),
                subtitle: Text(
                  'Mã bé: ${submission['childId']}\nNộp lúc ${dateLabel(submission['createdAt'])}\n${statusLabel(submission['status'])}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/submissions/${submission['id']}'),
              ),
            ),
          if (page > 1 || (data['total'] as int) > 20)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: page > 1 ? () => setState(() => page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Trang $page'),
                IconButton(
                  tooltip: 'Trang sau',
                  onPressed: page * 20 < (data['total'] as int)
                      ? () => setState(() => page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
