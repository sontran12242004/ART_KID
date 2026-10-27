import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/data/repositories/auth_repository_impl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/session_store.dart';
import '../../../core/network/api_interceptor.dart';
import '../data/connected_api.dart';
import 'widgets.dart';

Future<void> signOut(WidgetRef ref) async {
  final refresh = ref.read(sessionStoreProvider).refreshToken;
  try {
    if (refresh != null) {
      await ref
          .read(dioProvider)
          .post('/auth/logout', data: {'refreshToken': refresh});
    }
  } catch (_) {
    /* Local sign-out still clears the session if the server is unavailable. */
  } finally {
    ref.invalidate(apiDataProvider);
    ref.invalidate(mediaBytesProvider);
    ref.read(sessionStoreProvider.notifier).clear();
  }
}

class ChildPicker extends ConsumerWidget {
  const ChildPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.children.isEmpty) {
      return ListTile(
        title: const Text('Chưa có hồ sơ bé'),
        trailing: TextButton(
          onPressed: () => context.push('/parent/children'),
          child: const Text('Thêm bé'),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey(auth.selectedChild?.id),
      initialValue: auth.selectedChild?.id,
      decoration: const InputDecoration(
        labelText: 'Hồ sơ bé đang sử dụng',
        border: OutlineInputBorder(),
      ),
      items: auth.children
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.nickname} · ${c.age} tuổi'),
            ),
          )
          .toList(),
      onChanged: (id) {
        if (id != null) {
          ref
              .read(authProvider.notifier)
              .selectChild(auth.children.firstWhere((c) => c.id == id));
        }
      },
    );
  }
}

class ParentWorkspace extends ConsumerWidget {
  const ParentWorkspace({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final child = auth.selectedChild;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: AppBar(
        title: Text('Chào ${auth.currentUser?.name ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () {
              ref.invalidate(apiDataProvider);
              ref.read(authProvider.notifier).reloadChildren();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await signOut(ref);
              if (context.mounted) context.go('/parent/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ChildPicker(),
          const SizedBox(height: 16),
          if (child != null)
            ApiView(
              path: '/children/${child.id}/dashboard',
              builder: (data) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      Text(
                        '${child.nickname}: ${data['completedLessonsCount']} bài học',
                      ),
                      Text('${data['totalArtworksCount']} bài vẽ'),
                      Text('${data['totalBadgesCount']} huy hiệu'),
                      Text('${data['child']['totalPoints']} ⭐'),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          for (final item in <(String, String, IconData)>[
            ('Khóa học vẽ', '/parent/courses', Icons.school),
            (
              'Gói học & đăng ký',
              '/parent/subscriptions',
              Icons.card_membership,
            ),
            ('Cửa hàng học cụ', '/parent/shop', Icons.shopping_bag),
            ('Đơn hàng của tôi', '/parent/orders', Icons.receipt_long),
            ('Bài vẽ & nhận xét', '/parent/submissions', Icons.brush),
            ('Lớp học trực tuyến', '/parent/live', Icons.video_call),
            ('Thông báo', '/parent/notifications', Icons.notifications),
            ('Quản lý hồ sơ bé', '/parent/children', Icons.family_restroom),
            ('Cài đặt tài khoản', '/parent/settings', Icons.settings),
          ])
            Card(
              child: ListTile(
                leading: Icon(item.$3, color: Colors.teal),
                title: Text(item.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(item.$2),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: child == null ? null : () => context.go('/kid'),
            icon: const Icon(Icons.palette),
            label: const Text('Chuyển sang giao diện của bé'),
          ),
        ],
      ),
    );
  }
}

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});
  Future<void> edit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? child,
  ) async {
    final values = await askFields(
      context,
      child == null ? 'Thêm hồ sơ bé' : 'Sửa hồ sơ bé',
      [
        EntryField(
          'nickname',
          'Tên gọi của bé',
          value: child?['nickname'] ?? '',
        ),
        EntryField(
          'birthYear',
          'Năm sinh',
          value: '${child?['birthYear'] ?? DateTime.now().year - 6}',
          number: true,
        ),
        EntryField(
          'interests',
          'Sở thích',
          value: child?['interests'] ?? '',
          required: false,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final year = int.tryParse(values['birthYear']!);
    if (year == null) {
      toast(context, 'Năm sinh không hợp lệ.', error: true);
      return;
    }
    if (await mutate(
      context,
      ref,
      child == null ? '/children' : '/children/${child['id']}',
      {
        'nickname': values['nickname'],
        'birthYear': year,
        'interests': values['interests'],
        'avatarPresetId': child?['avatarPresetId'],
      },
      method: child == null ? 'POST' : 'PUT',
    )) {
      await ref.read(authProvider.notifier).reloadChildren();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Hồ sơ các bé')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => edit(context, ref, null),
      label: const Text('Thêm bé'),
      icon: const Icon(Icons.add),
    ),
    body: ApiView(
      path: '/children',
      builder: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in data as List)
            Card(
              child: ListTile(
                title: Text(c['nickname']),
                subtitle: Text('Năm sinh ${c['birthYear']}'),
                trailing: IconButton(
                  tooltip: 'Sửa hồ sơ',
                  onPressed: () =>
                      edit(context, ref, Map<String, dynamic>.from(c)),
                  icon: const Icon(Icons.edit),
                ),
                onTap: () {
                  final children = ref.read(authProvider).children;
                  final child = children
                      .where((v) => v.id == c['id'])
                      .firstOrNull;
                  if (child != null) {
                    ref.read(authProvider.notifier).selectChild(child);
                  }
                  toast(context, 'Đã chọn ${c['nickname']}.');
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class ConnectedSettingsScreen extends ConsumerWidget {
  const ConnectedSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt tài khoản')),
    body: ApiView(
      path: '/auth/me',
      builder: (value) {
        final user = Map<String, dynamic>.from(value);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              title: Text(user['fullName']),
              subtitle: Text(user['email']),
            ),
            FilledButton(
              onPressed: () async {
                final result = await askFields(context, 'Thông tin phụ huynh', [
                  EntryField('fullName', 'Họ tên', value: user['fullName']),
                  EntryField(
                    'phoneNumber',
                    'Số điện thoại',
                    value: user['phoneNumber'] ?? '',
                    required: false,
                  ),
                ]);
                if (result == null || !context.mounted) return;
                if (await mutate(context, ref, '/auth/me', {
                  ...user,
                  ...result,
                }, method: 'PUT')) {
                  final next =
                      (await ref.read(dioProvider).get('/auth/me')).data;
                  ref
                      .read(authProvider.notifier)
                      .updateUser(parentFromApi(next));
                }
              },
              child: const Text('Sửa thông tin'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                final result = await askFields(context, 'Đổi mã PIN', [
                  const EntryField(
                    'password',
                    'Mật khẩu tài khoản',
                    secret: true,
                  ),
                  const EntryField('pin', 'PIN mới (4–6 chữ số)', secret: true),
                ]);
                if (result != null && context.mounted) {
                  await mutate(context, ref, '/auth/kid-pin/update', result);
                }
              },
              child: const Text('Đổi mã PIN phụ huynh'),
            ),
            SwitchListTile(
              title: const Text('Nhận thông báo'),
              value: user['notificationsEnabled'] == true,
              onChanged: (v) => mutate(context, ref, '/auth/me', {
                ...user,
                'notificationsEnabled': v,
              }, method: 'PUT'),
            ),
            SwitchListTile(
              title: const Text('Nhắc bé vẽ mỗi ngày'),
              value: user['dailyDrawingReminder'] == true,
              onChanged: (v) => mutate(context, ref, '/auth/me', {
                ...user,
                'dailyDrawingReminder': v,
              }, method: 'PUT'),
            ),
            const Divider(),
            const Text(
              'Quyền xử lý bài vẽ của bé',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final child in ref.watch(authProvider).children)
              ApiView(
                path: '/children/${child.id}/consents',
                builder: (data) => Column(
                  children: [
                    ListTile(title: Text(child.nickname)),
                    for (final consent in data as List)
                      ListTile(
                        title: Text(
                          consent['purpose'] == 'ai_generation'
                              ? 'Phân tích bài vẽ bằng AI'
                              : 'Lưu và gửi bài vẽ',
                        ),
                        subtitle: Text(
                          consent['revokedAt'] == null
                              ? 'Đang cho phép'
                              : 'Đã thu hồi',
                        ),
                        trailing: consent['revokedAt'] != null
                            ? null
                            : TextButton(
                                onPressed: () => mutate(
                                  context,
                                  ref,
                                  '/consents/${consent['id']}',
                                  {},
                                  method: 'DELETE',
                                  success: 'Đã thu hồi quyền.',
                                ),
                                child: const Text('Thu hồi'),
                              ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                try {
                  await signOut(ref);
                } catch (e) {
                  if (context.mounted) toast(context, apiError(e), error: true);
                }
                if (context.mounted) context.go('/parent/login');
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    ),
  );
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo')),
    body: ApiView(
      path: '/notifications?pageSize=100',
      builder: (data) => data.isEmpty
          ? const Center(child: Text('Chưa có thông báo.'))
          : ListView(
              children: [
                for (final n in data as List)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        n['readAt'] == null
                            ? Icons.mark_email_unread
                            : Icons.mark_email_read,
                      ),
                      title: Text(n['title']),
                      subtitle: Text(
                        '${n['message']}\n${dateLabel(n['createdAt'])}',
                      ),
                      onTap: () => mutate(
                        context,
                        ref,
                        '/notifications/${n['id']}/read',
                        {},
                        success: 'Đã đánh dấu đã đọc.',
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
