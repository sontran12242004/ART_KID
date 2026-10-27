import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../kid_mode/presentation/providers/app_mode_provider.dart';
import '../providers/parent_dashboard_provider.dart';
import '../providers/parent_profile_provider.dart';
import '../widgets/app_avatar_widget.dart';
import '../widgets/child_progress_card.dart';
import '../widgets/kit_delivery_tracker.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(parentProfileProvider);
    final deliveriesAsync = ref.watch(kitDeliveriesProvider('current-parent'));
    final progressAsync = ref.watch(childProgressProvider('child-1'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'ArtKids — Phụ Huynh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D3436)),
            tooltip: 'Cài đặt & Hồ sơ',
            onPressed: () => context.push(RoutePaths.parentSettings),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(
              Icons.child_care_rounded,
              color: Color(0xFFFF6B6B),
            ),
            label: const Text(
              'Bé Học',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              ref.read(appModeProvider.notifier).state = AppMode.kid;
              context.go(RoutePaths.kidPinGate);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome card (chạm để vào Cài đặt & Đổi Avatar)
            InkWell(
              onTap: () => context.push(RoutePaths.parentSettings),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1687A7), Color(0xFF276678)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1687A7).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AppAvatarWidget(
                      avatarId: profile.parentAvatarId,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${profile.parentName} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.childNickname} (${profile.childAge} tuổi) • Đang học ${profile.currentCourseTitle}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Lưới Quick Navigation
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.palette_rounded,
                    color: const Color(0xFF6C5CE7),
                    title: 'Khóa Học Vẽ',
                    subtitle: 'Danh sách bài học',
                    onTap: () => context.push(RoutePaths.parentCourses),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF00B894),
                    title: 'Cửa Hàng Học Cụ',
                    subtitle: 'Mua lẻ kit & dụng cụ',
                    onTap: () => context.push(RoutePaths.parentShop),
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
                    title: 'Gói Đăng Ký',
                    subtitle: 'Hội viên & Kit định kỳ',
                    onTap: () => context.push(RoutePaths.parentSubscriptions),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFFE17055),
                    title: 'Đơn Hàng Của Tôi',
                    subtitle: 'Quản lý & tra cứu Kit',
                    onTap: () => context.push(RoutePaths.parentOrders),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.push(RoutePaths.parentKidPinSetup),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0984E3).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pin_outlined,
                        color: Color(0xFF0984E3),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mã PIN Trẻ Em',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Cài đặt bảo vệ chế độ Kid Mode và phân quyền thao tác',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Báo cáo học tập của bé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến Độ Học Tập Của Con',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.parentProgress),
                  child: const Text('Chi tiết'),
                ),
              ],
            ),
            progressAsync.when(
              data: (report) => ChildProgressCard(report: report),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Tình trạng giao Kit học cụ gần nhất
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kit Học Cụ Gần Nhất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.parentOrders),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            deliveriesAsync.when(
              data: (deliveries) {
                if (deliveries.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có kit học cụ nào đang vận chuyển.'),
                    ),
                  );
                }
                return KitDeliveryTracker(delivery: deliveries.first);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
