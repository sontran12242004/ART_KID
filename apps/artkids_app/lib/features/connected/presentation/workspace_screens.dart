import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'family_screens.dart';
import 'widgets.dart';
import 'course_product_screens.dart';
import 'course_lecture_dialog.dart';
import 'lecture_upload_screen.dart';
export 'live_class_screens.dart';

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

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final admin = user?.role == 'admin';
    final teacherName = user?.name.isNotEmpty == true
        ? user!.name
        : (admin ? 'Quản trị viên' : 'Giảng viên');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1687A7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF1687A7),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              admin ? 'Quản Trị ART KID' : 'Giảng Viên ART KID',
              style: const TextStyle(
                color: Color(0xFF0F3B46),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => signOut(ref),
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Hero greeting card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1687A7), Color(0xFF276678)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1687A7).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $teacherName 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin
                            ? 'Trung tâm quản trị & kiểm duyệt nội dung'
                            : 'Không gian làm việc & giảng dạy của bạn',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00B894),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        admin ? 'Admin' : 'Online',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 2. Section: Tác vụ chính
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF1687A7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bảng Điều Khiển Tác Vụ',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x2 Quick Action Cards
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.fact_check_rounded,
                  color: const Color(0xFFE76F51),
                  title: 'Chấm bài học sinh',
                  subtitle: 'Đánh giá & chấm điểm',
                  onTap: () => context.push('/staff/grading'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.video_camera_front_rounded,
                  color: const Color(0xFF6C5CE7),
                  title: 'Lớp trực tuyến',
                  subtitle: 'Dạy học & tương tác live',
                  onTap: () => context.push('/parent/live'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF00B894),
                  title: admin ? 'Duyệt học cụ' : 'Học cụ của tôi',
                  subtitle: admin ? 'Kiểm duyệt đề xuất' : 'Kho & bán học cụ',
                  onTap: () => context.push(
                    admin
                        ? '/staff/marketplace/reviews'
                        : '/staff/marketplace',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFF0984E3),
                  title: admin ? 'Đơn hàng sàn' : 'Đơn học cụ của tôi',
                  subtitle:
                      admin ? 'Xác nhận & giao hàng' : 'Theo dõi đơn đặt mua',
                  onTap: () => context.push(
                    admin ? '/staff/orders' : '/staff/marketplace/orders',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. Section: Khóa học
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1687A7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    admin ? 'Tất Cả Khóa Học' : 'Khóa Học Của Tôi',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F3B46),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1687A7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
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
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Tạo khóa học',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Danh sách khóa học
          ApiView(
            path: '/courses?pageSize=100',
            builder: (data) {
              final courses = (data['items'] as List)
                  .where(
                    (c) =>
                        admin ||
                        c['instructorId'] ==
                            ref.watch(authProvider).currentUser?.id,
                  )
                  .toList();

              if (courses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          size: 44,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có khóa học nào',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bấm nút "Tạo khóa học" phía trên để bắt đầu thêm khóa học đầu tiên.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final currencyFormatter = NumberFormat.currency(
                locale: 'vi_VN',
                symbol: 'đ',
                decimalDigits: 0,
              );

              return Column(
                children: [
                  for (final c in courses)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1687A7).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.palette_rounded,
                              color: Color(0xFF1687A7),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            c['title'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (c['ageRange'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F2F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${c['ageRange']} tuổi',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF636E72),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B894).withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c['priceVnd'] == null || c['priceVnd'] == 0
                                        ? 'Miễn phí'
                                        : currencyFormatter.format(c['priceVnd']),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF00B894),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Chỉnh sửa khóa học',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Color(0xFF1687A7),
                                ),
                                onPressed: () => _editCourse(
                                  context,
                                  ref,
                                  Map<String, dynamic>.from(c),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Xóa khóa học',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Colors.red.shade600,
                                ),
                                onPressed: () => _deleteCourse(
                                  context,
                                  ref,
                                  Map<String, dynamic>.from(c),
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: EdgeInsets.zero,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if ((c['description'] as String?)?.isNotEmpty ==
                                      true) ...[
                                    Text(
                                      c['description'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: Colors.grey.shade200),
                                    const SizedBox(height: 12),
                                  ],
                                  const Text(
                                    'NỘI DUNG & BÀI HỌC',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                              horizontal: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF1687A7),
                                            ),
                                            foregroundColor:
                                                const Color(0xFF1687A7),
                                          ),
                                          onPressed: () =>
                                              showCourseLecturesDialog(
                                                context,
                                                courseId: c['id'],
                                                courseTitle: c['title'],
                                              ),
                                          icon: const Icon(
                                            Icons.video_library_outlined,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Xem bài giảng',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                              horizontal: 8,
                                            ),
                                            backgroundColor:
                                                const Color(0xFF1687A7),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () =>
                                              showLectureUploadDialog(
                                                context,
                                                courseId: c['id'],
                                              ),
                                          icon: const Icon(
                                            Icons.upload_file_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Thêm video',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'GIẢNG DẠY TRỰC TUYẾN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      backgroundColor: const Color(
                                        0xFF6C5CE7,
                                      ).withValues(alpha: 0.12),
                                      foregroundColor: const Color(0xFF6C5CE7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final v = await askFields(
                                        context,
                                        'Tạo lớp trực tuyến',
                                        [
                                          const EntryField('name', 'Tên lớp'),
                                          const EntryField(
                                            'capacity',
                                            'Sĩ số tối đa 30',
                                            number: true,
                                            value: '30',
                                          ),
                                        ],
                                      );
                                      if (v != null && context.mounted) {
                                        await mutate(
                                          context,
                                          ref,
                                          '/live/classes',
                                          {
                                            'courseId': c['id'],
                                            'name': v['name'],
                                            'capacity': int.parse(v['capacity']!),
                                          },
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.add_to_queue_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Tạo lớp trực tuyến cho khóa này',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  if (!admin) ...[
                                    const SizedBox(height: 14),
                                    const Text(
                                      'HỌC CỤ KÈM THEO',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF718096),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 11,
                                                horizontal: 6,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFF00B894),
                                              ),
                                              foregroundColor: const Color(
                                                0xFF00B894,
                                              ),
                                            ),
                                            onPressed: () => context.push(
                                              '/staff/courses/${c['id']}/products/new',
                                            ),
                                            icon: const Icon(
                                              Icons.add_shopping_cart_rounded,
                                              size: 17,
                                            ),
                                            label: const Text(
                                              'Đăng bán học cụ',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 11,
                                                horizontal: 6,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(
                                                color: Colors.grey.shade400,
                                              ),
                                              foregroundColor: const Color(
                                                0xFF2D3436,
                                              ),
                                            ),
                                            onPressed: () =>
                                                showCourseProductsDialog(
                                                  context,
                                                  c['id'],
                                                  c['title'],
                                                ),
                                            icon: const Icon(
                                              Icons.inventory_2_outlined,
                                              size: 17,
                                            ),
                                            label: const Text(
                                              'Học cụ liên quan',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
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
                  '${o['awaitingMarketplacePayment'] == true ? 'Chờ xác minh tiền marketplace' : statusLabel(o['status'])} · ${money(o['totalAmountVnd'] ?? o['totalVnd'] ?? 0)}',
                ),
                trailing: o['requiresLegacyConfirmation'] == true
                    ? ActionButton(
                        label: o['hasMarketplaceItems'] == true
                            ? 'Xác nhận phần hàng nền tảng'
                            : 'Xác nhận thanh toán',
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
