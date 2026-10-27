import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'family_screens.dart';
import 'widgets.dart';
import 'course_product_screens.dart';
import 'course_lecture_dialog.dart';
import 'lecture_upload_screen.dart';

class ConnectedKidHome extends ConsumerWidget {
  const ConnectedKidHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(authProvider).selectedChild;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: AppBar(
        title: Text('Chào Bé ${child?.nickname ?? ''}! 🎨'),
        actions: [
          IconButton(
            tooltip: 'Về giao diện phụ huynh',
            icon: const Icon(Icons.lock),
            onPressed: () async {
              final v = await askFields(context, 'Mã PIN phụ huynh', [
                const EntryField('pin', 'Nhập PIN', secret: true),
              ]);
              if (v == null) return;
              final ok = await ref
                  .read(authRepositoryProvider)
                  .verifyKidPin(v['pin']!);
              if (context.mounted) {
                if (ok) {
                  context.go('/parent');
                } else {
                  toast(context, 'Mã PIN không đúng.', error: true);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ApiView(
            path: '/children/${child?.id}/dashboard',
            builder: (d) => ListTile(
              title: Text('${d['child']['totalPoints']} ⭐'),
              subtitle: Text(
                '${d['totalBadgesCount']} huy hiệu · ${d['completedLessonsCount']} bài học',
              ),
            ),
          ),
          for (final item in [
            (
              'Vẽ & Ghép Tranh',
              Icons.extension,
              Colors.orange,
              '/matching-game',
            ),
            (
              'Thư Viện Tranh',
              Icons.collections,
              Colors.blue,
              '/matching-game/gallery',
            ),
            ('Khóa Học Vẽ', Icons.school, Colors.redAccent, '/parent/courses'),
            ('Bài Vẽ & Nhận Xét', Icons.brush, Colors.teal, '/parent/submissions'),
            (
              'Lớp Học Trực Tuyến',
              Icons.video_call,
              Colors.orange,
              '/parent/live',
            ),
            (
              'Huy Hiệu & Cúp',
              Icons.emoji_events,
              Colors.deepPurple,
              '/kid/badges',
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: item.$3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(24),
                  leading: Icon(item.$2, color: Colors.white, size: 36),
                  title: Text(
                    item.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onTap: () => context.push(item.$4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ConnectedBadges extends ConsumerWidget {
  const ConnectedBadges({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Huy hiệu & Cúp')),
    body: ApiView(
      path: '/children/${ref.watch(authProvider).selectedChild?.id}/badges',
      builder: (data) => ListView(
        children: [
          for (final b in data)
            ListTile(
              leading: Icon(
                b['isUnlocked'] == true ? Icons.emoji_events : Icons.lock,
                color: b['isUnlocked'] == true ? Colors.amber : Colors.grey,
              ),
              title: Text(b['badge']['title']),
              subtitle: Text(
                '${b['currentProgress']} / ${b['badge']['maxProgress']}',
              ),
            ),
        ],
      ),
    ),
  );
}

class LiveClassesScreen extends ConsumerWidget {
  const LiveClassesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(authProvider).selectedChild;
    final staff = ref.watch(authProvider).currentUser?.role != 'parent';
    return Scaffold(
      appBar: AppBar(title: const Text('Lớp học trực tuyến')),
      body: ApiView(
        path: '/live/classes',
        builder: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final c in data)
              Card(
                child: ExpansionTile(
                  title: Text(c['name']),
                  subtitle: Text('Tối đa ${c['capacity']} học sinh'),
                  children: [
                    if (!staff)
                      ActionButton(
                        label: 'Đăng ký bé vào lớp',
                        action: (r) => r
                            .read(dioProvider)
                            .post(
                              '/live/classes/${c['id']}/enrollments',
                              data: {'childId': child?.id},
                            ),
                      ),
                    if (staff)
                      FilledButton(
                        onPressed: () async {
                          final v = await askFields(
                            context,
                            'Lên lịch buổi học',
                            [
                              const EntryField('title', 'Tên buổi học'),
                              EntryField(
                                'startsAt',
                                'Bắt đầu (ISO, ví dụ 2026-10-21T19:00:00+07:00)',
                                value: DateTime.now()
                                    .add(const Duration(minutes: 5))
                                    .toIso8601String(),
                              ),
                              EntryField(
                                'endsAt',
                                'Kết thúc (ISO)',
                                value: DateTime.now()
                                    .add(const Duration(hours: 1))
                                    .toIso8601String(),
                              ),
                              const EntryField(
                                'roomUrl',
                                'Đường dẫn phòng học HTTPS',
                              ),
                            ],
                          );
                          if (v != null && context.mounted) {
                            await mutate(
                              context,
                              ref,
                              '/live/classes/${c['id']}/sessions',
                              {
                                ...v,
                                'startsAt': DateTime.parse(
                                  v['startsAt']!,
                                ).toUtc().toIso8601String(),
                                'endsAt': DateTime.parse(
                                  v['endsAt']!,
                                ).toUtc().toIso8601String(),
                                'provider': 'external',
                              },
                            );
                          }
                        },
                        child: const Text('Lên lịch buổi học'),
                      ),
                    ApiView(
                      path: '/live/classes/${c['id']}/sessions',
                      builder: (sessions) => Column(
                        children: [
                          for (final s in sessions)
                            ListTile(
                              title: Text(s['title']),
                              subtitle: Text(
                                '${dateLabel(s['startsAt'])} · ${statusLabel(s['status'])}',
                              ),
                              trailing: ActionButton(
                                label: 'Vào lớp',
                                action: (r) => r
                                    .read(dioProvider)
                                    .post(
                                      '/live/sessions/${s['id']}/join',
                                      data: staff ? {} : {'childId': child?.id},
                                    ),
                                onSuccess: (result) async {
                                  final url = result.data['joinUrl'];
                                  if (url != null) {
                                    await launchUrl(
                                      Uri.parse(url),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StaffWorkspace extends ConsumerWidget {
  const StaffWorkspace({super.key});

  Future<void> _editCourse(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> course,
  ) async {
    final values = await askFields(context, 'Chỉnh sửa khóa học', [
      EntryField('title', 'Tên khóa học', value: course['title']),
      EntryField('description', 'Mô tả', value: course['description'] ?? ''),
      EntryField('ageRange', 'Độ tuổi', value: course['ageRange']),
      EntryField(
        'priceVnd',
        'Giá (VND)',
        value: '${course['priceVnd']}',
        number: true,
      ),
    ]);
    if (values == null || !context.mounted) return;
    final price = int.tryParse(values['priceVnd']!);
    if (price == null || price < 0 || price > 100000000) {
      toast(
        context,
        'Giá khóa học phải là số nguyên từ 0 đến 100.000.000 VNĐ.',
        error: true,
      );
      return;
    }
    await mutate(
      context,
      ref,
      '/courses/${course['id']}',
      {...course, ...values, 'priceVnd': price},
      method: 'PUT',
      success: 'Đã cập nhật khóa học.',
    );
  }

  Future<void> _deleteCourse(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> course,
  ) async {
    final approved = await confirm(
      context,
      'Xóa khóa học',
      'Xóa "${course['title']}" khỏi danh sách và ngừng bán học cụ liên quan? Lịch sử học và đơn hàng đã phát sinh được giữ lại.',
    );
    if (!approved || !context.mounted) return;
    await mutate(
      context,
      ref,
      '/courses/${course['id']}',
      {},
      method: 'DELETE',
      success: 'Đã xóa khóa học.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(authProvider).currentUser?.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(admin ? 'Quản trị ART KID' : 'Giảng viên ART KID'),
        actions: [
          IconButton(
            onPressed: () => signOut(ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.grading),
            title: const Text('Chấm bài học sinh'),
            onTap: () => context.push('/staff/grading'),
          ),
          ListTile(
            leading: const Icon(Icons.video_call),
            title: const Text('Lớp học trực tuyến'),
            onTap: () => context.push('/parent/live'),
          ),
          if (admin)
            ListTile(
              title: const Text('Xác nhận đơn & giao hàng'),
              onTap: () => context.push('/staff/orders'),
            ),
          FilledButton(
            onPressed: () async {
              final v = await askFields(context, 'Tạo khóa học', [
                const EntryField('title', 'Tên khóa học'),
                const EntryField('description', 'Mô tả'),
                const EntryField('ageRange', 'Độ tuổi', value: '5-10'),
                const EntryField(
                  'priceVnd',
                  'Giá (VND)',
                  value: '0',
                  number: true,
                ),
              ]);
              if (v != null && context.mounted) {
                await mutate(context, ref, '/courses', {
                  ...v,
                  'priceVnd': int.parse(v['priceVnd']!),
                  'isPublished': true,
                });
              }
            },
            child: const Text('Tạo khóa học'),
          ),
          ApiView(
            path: '/courses?pageSize=100',
            builder: (data) => Column(
              children: [
                for (final c in (data['items'] as List).where(
                  (c) =>
                      admin ||
                      c['instructorId'] ==
                          ref.watch(authProvider).currentUser?.id,
                ))
                  Card(
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(c['title'])),
                          IconButton(
                            tooltip: 'Chỉnh sửa khóa học',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editCourse(
                              context,
                              ref,
                              Map<String, dynamic>.from(c),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Xóa khóa học',
                            color: Colors.red.shade700,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteCourse(
                              context,
                              ref,
                              Map<String, dynamic>.from(c),
                            ),
                          ),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(240, 44),
                          ),
                          onPressed: () => showCourseLecturesDialog(
                            context,
                            courseId: c['id'],
                            courseTitle: c['title'],
                          ),
                          icon: const Icon(Icons.video_library_outlined),
                          label: const Text('Xem video bài giảng'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(240, 44),
                          ),
                          onPressed: () => showLectureUploadDialog(
                            context,
                            courseId: c['id'],
                          ),
                          child: const Text('Tải video & thêm bài học'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(240, 44),
                          ),
                          onPressed: () async {
                            final v =
                                await askFields(context, 'Tạo lớp trực tuyến', [
                                  const EntryField('name', 'Tên lớp'),
                                  const EntryField(
                                    'capacity',
                                    'Sĩ số tối đa 30',
                                    number: true,
                                    value: '30',
                                  ),
                                ]);
                            if (v != null && context.mounted) {
                              await mutate(context, ref, '/live/classes', {
                                'courseId': c['id'],
                                'name': v['name'],
                                'capacity': int.parse(v['capacity']!),
                              });
                            }
                          },
                          child: const Text('Tạo lớp trực tuyến'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(240, 44),
                          ),
                          onPressed: () => context.push(
                            '/staff/courses/${c['id']}/products/new',
                          ),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Đăng bán học cụ'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(240, 44),
                          ),
                          onPressed: () => showCourseProductsDialog(
                            context,
                            c['id'],
                            c['title'],
                          ),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Xem học cụ liên quan'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminOrders extends ConsumerWidget {
  const AdminOrders({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Quản lý đơn hàng')),
    body: ApiView(
      path: '/commerce/orders?pageSize=100',
      builder: (data) => ListView(
        children: [
          for (final o in data)
            Card(
              child: ListTile(
                title: Text(o['orderCode'] ?? o['id']),
                subtitle: Text(
                  '${statusLabel(o['status'])} · ${money(o['totalAmountVnd'] ?? o['totalVnd'] ?? 0)}',
                ),
                trailing: o['status'] == 'pending_confirmation'
                    ? ActionButton(
                        label: 'Xác nhận thanh toán',
                        action: (r) => r
                            .read(dioProvider)
                            .post(
                              '/commerce/orders/${o['id']}/confirm',
                              data: {},
                            ),
                      )
                    : TextButton(
                        onPressed: () =>
                            context.push('/parent/orders/${o['id']}'),
                        child: const Text('Xem chi tiết'),
                      ),
              ),
            ),
        ],
      ),
    ),
  );
}
