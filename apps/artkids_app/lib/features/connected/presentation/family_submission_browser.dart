import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import 'family_screens.dart';
import 'widgets.dart';

class FamilySubmissionBrowser extends ConsumerStatefulWidget {
  const FamilySubmissionBrowser({
    super.key,
    this.courseId,
    this.lessonId,
    this.unassigned = false,
  });
  final String? courseId;
  final String? lessonId;
  final bool unassigned;

  @override
  ConsumerState<FamilySubmissionBrowser> createState() =>
      _FamilySubmissionBrowserState();
}

class _FamilySubmissionBrowserState
    extends ConsumerState<FamilySubmissionBrowser> {
  String? status;
  int page = 1;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(authProvider).selectedChild;
    final drawings = widget.lessonId != null || widget.unassigned;
    final root = widget.courseId == null && !drawings;
    ref.listen(authProvider.select((s) => s.selectedChild?.id), (_, next) {
      setState(() {
        page = 1;
        status = null;
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          root
              ? 'Bài vẽ & nhận xét · Khóa học'
              : drawings
              ? 'Bài vẽ & nhận xét'
              : 'Bài vẽ & nhận xét · Bài học',
        ),
      ),
      body: child == null
          ? const Center(child: Text('Vui lòng chọn hồ sơ bé.'))
          : ApiView(
              path:
                  '/family/submission-browser?childId=${child.id}&page=$page'
                  '${widget.courseId == null ? '' : '&courseId=${widget.courseId}'}'
                  '${widget.lessonId == null ? '' : '&lessonId=${widget.lessonId}'}'
                  '${widget.unassigned ? '&unassigned=true' : ''}'
                  '${status == null ? '' : '&status=$status'}',
              builder: (data) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (root) ...[
                    const ChildPicker(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Bài vẽ của ${data['childName']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (!root)
                    Text(
                      data['title'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  if (root)
                    const Text(
                      'Chọn khóa học, sau đó chọn bài học để xem bài vẽ và nhận xét của giáo viên.',
                    ),
                  const SizedBox(height: 12),
                  if (drawings) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in <String?, String>{
                          null: 'Tất cả',
                          'pending_review': 'Chờ chấm',
                          'reviewed': 'Đã nhận xét',
                        }.entries)
                          ChoiceChip(
                            label: Text(filter.value),
                            selected: status == filter.key,
                            onSelected: (_) => setState(() {
                              status = filter.key;
                              page = 1;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('${data['total']} bài vẽ'),
                  ],
                  if ((data['items'] as List).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        root
                            ? 'Bé chưa có khóa học nào.'
                            : drawings
                            ? 'Chưa có bài vẽ trong mục này.'
                            : 'Khóa học chưa có bài học.',
                      ),
                    ),
                  for (final item in data['items'])
                    Card(
                      child: ListTile(
                        leading: Icon(
                          drawings
                              ? Icons.brush_outlined
                              : root
                              ? Icons.school_outlined
                              : Icons.menu_book_outlined,
                          color: drawings && item['status'] == 'reviewed'
                              ? Colors.teal
                              : null,
                        ),
                        title: Text(
                          drawings
                              ? '${data['childName']} · ${dateLabel(item['createdAt'])}'
                              : root
                              ? item['title']
                              : 'Bài ${item['orderIndex']}: ${item['title']}',
                        ),
                        subtitle: Text(
                          drawings
                              ? statusLabel(item['status'])
                              : '${item['totalCount']} bài đã nộp · ${item['pendingCount']} chờ chấm · ${item['reviewedCount']} đã nhận xét',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          drawings
                              ? '/submissions/${item['id']}'
                              : root
                              ? '/parent/submissions/courses/${item['id']}'
                              : '/parent/submissions/lessons/${item['id']}',
                        ),
                      ),
                    ),
                  if (root && (data['unassignedCount'] as int) > 0)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Tranh ngoài bài học'),
                        subtitle: Text('${data['unassignedCount']} bài đã nộp'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/parent/submissions/unassigned'),
                      ),
                    ),
                  if (drawings && (page > 1 || (data['total'] as int) > 20))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Trang trước',
                          onPressed: page > 1
                              ? () => setState(() => page--)
                              : null,
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
}
