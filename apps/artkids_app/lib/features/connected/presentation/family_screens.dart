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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.child_care_rounded, color: Color(0xFF1687A7)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Chưa có hồ sơ bé',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/parent/children'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm bé'),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          key: ValueKey(auth.selectedChild?.id),
          value: auth.selectedChild?.id,
          hint: const Text('Chọn hồ sơ bé đang học'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1687A7)),
          items: auth.children
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1687A7).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_rounded,
                          size: 18,
                          color: Color(0xFF1687A7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${c.nickname} · ${c.age} tuổi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  ),
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
        ),
      ),
    );
  }
}

class ParentWorkspace extends ConsumerWidget {
  const ParentWorkspace({super.key});

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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final child = auth.selectedChild;
    final parentName = auth.currentUser?.name.isNotEmpty == true
        ? auth.currentUser!.name
        : 'Phụ Huynh';

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
                Icons.family_restroom_rounded,
                color: Color(0xFF1687A7),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Không Gian Phụ Huynh',
              style: TextStyle(
                color: Color(0xFF0F3B46),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1687A7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Làm mới',
              onPressed: () {
                ref.invalidate(apiDataProvider);
                ref.read(authProvider.notifier).reloadChildren();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF1687A7),
                size: 20,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await signOut(ref);
                if (context.mounted) context.go('/parent/login');
              },
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
          // 1. Hero Welcome Card
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            'Xin chào, $parentName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            child != null
                                ? 'Đang theo dõi: ${child.nickname} (${child.age} tuổi)'
                                : 'Đồng hành cùng hành trình sáng tạo của bé',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed:
                          child == null ? null : () => context.go('/kid'),
                      icon: const Icon(Icons.child_care_rounded, size: 18),
                      label: const Text(
                        'Bé Học',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (auth.children.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Hồ sơ bé: ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final c in auth.children)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      '${c.nickname} (${c.age}t)',
                                      style: TextStyle(
                                        color: c.id == child?.id
                                            ? const Color(0xFF0F3B46)
                                            : Colors.white,
                                        fontWeight: c.id == child?.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: c.id == child?.id,
                                    selectedColor: Colors.white,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    side: BorderSide(
                                      color: c.id == child?.id
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref
                                            .read(authProvider.notifier)
                                            .selectChild(c);
                                      }
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Thêm bé',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                onPressed: () =>
                                    context.push('/parent/children'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Child Learning Progress Dashboard
          if (child != null) ...[
            ApiView(
              path: '/children/${child.id}/dashboard',
              builder: (data) => Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C5CE7)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  size: 16,
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tiến độ học tập của ${child.nickname}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F3B46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA502)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '⭐ ${data['child']?['totalPoints'] ?? 0} điểm',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE67E22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.menu_book_rounded,
                            value: '${data['completedLessonsCount'] ?? 0}',
                            label: 'Bài học xong',
                            color: const Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.brush_rounded,
                            value: '${data['totalArtworksCount'] ?? 0}',
                            label: 'Tác phẩm vẽ',
                            color: const Color(0xFF00B894),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.emoji_events_rounded,
                            value: '${data['totalBadgesCount'] ?? 0}',
                            label: 'Huy hiệu đạt',
                            color: const Color(0xFFF39C12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.stars_rounded,
                            value: '${data['child']?['totalPoints'] ?? 0}',
                            label: 'Sao tích lũy',
                            color: const Color(0xFFE17055),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. Section: Bảng Điều Khiển Tác Vụ Phụ Huynh
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
                'Học Tập & Đồng Hành',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x3 Grid of Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.palette_rounded,
                  color: const Color(0xFF6C5CE7),
                  title: 'Khóa Học Vẽ',
                  subtitle: 'Lộ trình & video bài học',
                  onTap: () => context.push('/parent/courses'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.video_camera_front_rounded,
                  color: const Color(0xFFE76F51),
                  title: 'Lớp Trực Tuyến',
                  subtitle: 'Lịch học Live & phòng dạy',
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
                  icon: Icons.rate_review_rounded,
                  color: const Color(0xFF00B894),
                  title: 'Bài Vẽ & Nhận Xét',
                  subtitle: 'Đánh giá từ giảng viên',
                  onTap: () => context.push('/parent/submissions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF0984E3),
                  title: 'Cửa Hàng Học Cụ',
                  subtitle: 'Mua lẻ dụng cụ vẽ & Kit',
                  onTap: () => context.push('/parent/shop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.card_membership_rounded,
                  color: const Color(0xFFF39C12),
                  title: 'Gói Học Hội Viên',
                  subtitle: 'Kit định kỳ & ưu đãi',
                  onTap: () => context.push('/parent/subscriptions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFF2D3436),
                  title: 'Đơn Hàng Của Tôi',
                  subtitle: 'Tra cứu hành trình Kit',
                  onTap: () => context.push('/parent/orders'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Section: Tài Khoản & Tiện Ích
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
                'Tài Khoản & Tiện Ích',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
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
            child: Column(
              children: [
                _buildUtilityTile(
                  icon: Icons.family_restroom_rounded,
                  color: const Color(0xFF1687A7),
                  title: 'Quản lý hồ sơ các bé',
                  subtitle: 'Thêm, sửa hồ sơ & độ tuổi của từng bé',
                  onTap: () => context.push('/parent/children'),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildUtilityTile(
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFFF1C40F),
                  title: 'Thông báo',
                  subtitle: 'Nhắc lịch học, phản hồi bài vẽ & giao hàng',
                  onTap: () => context.push('/parent/notifications'),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildUtilityTile(
                  icon: Icons.security_rounded,
                  color: const Color(0xFF636E72),
                  title: 'Cài đặt tài khoản & Mã PIN',
                  subtitle: 'Đổi mật khẩu, mã PIN phụ huynh & thiết lập',
                  onTap: () => context.push('/parent/settings'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Bottom Prominent Button: Vào không gian của bé
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1687A7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1,
            ),
            onPressed: child == null ? null : () => context.go('/kid'),
            icon: const Icon(Icons.palette_rounded, size: 20),
            label: const Text(
              'Chuyển sang giao diện sáng tạo của bé',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
          ),
          const SizedBox(height: 16),
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
