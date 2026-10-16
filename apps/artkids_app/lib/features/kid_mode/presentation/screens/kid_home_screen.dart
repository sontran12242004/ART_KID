import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../parent_dashboard/presentation/providers/parent_profile_provider.dart';
import '../../../parent_dashboard/presentation/widgets/app_avatar_widget.dart';
import '../providers/app_mode_provider.dart';
import '../providers/kid_badges_notifier.dart';
import '../providers/voice_guidance_provider.dart';
import '../widgets/kid_pin_pad.dart';

class KidHomeScreen extends ConsumerStatefulWidget {
  const KidHomeScreen({super.key});

  @override
  ConsumerState<KidHomeScreen> createState() => _KidHomeScreenState();
}

class _KidHomeScreenState extends ConsumerState<KidHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(voiceGuidanceServiceProvider)
          .speak('Chào bé! Hôm nay chúng mình cùng vẽ tranh nhé!');
    });
  }

  void _showParentalGate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.security_rounded,
              size: 48,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Cổng Xác Thực Phụ Huynh',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập mã PIN của phụ huynh để thoát Kid Mode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            KidPinPad(
              pinLength: 4,
              onPinComplete: (pin) {
                Navigator.of(modalContext).pop();
                // Chuyển lại về chế độ phụ huynh
                ref.read(appModeProvider.notifier).state = AppMode.parent;
                context.go(RoutePaths.parentHome);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(parentProfileProvider);
    final badgesState = ref.watch(kidBadgesNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh header: Lời chào + Nút thoát về Phụ huynh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AppAvatarWidget(
                        avatarId: profile.childAvatarId,
                        isChild: true,
                        radius: 26,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào ${profile.childNickname}! 🎨',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: KidUiConstants.textDark,
                            ),
                          ),
                          Text(
                            '${badgesState.totalStars} ⭐ • ${badgesState.unlockedCount}/20 Huy hiệu',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Nút khóa an toàn chuyển về Parent Mode
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        color: Colors.blueGrey,
                        size: 24,
                      ),
                    ),
                    tooltip: 'Thoát ra chế độ phụ huynh',
                    onPressed: () => _showParentalGate(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Lưới menu tính năng lớn cho trẻ em
              Expanded(
                child: ListView(
                  children: [
                    // Card lớn 1: Khóa học vẽ
                    _buildFeatureCard(
                      title: 'Khóa Học Vẽ',
                      subtitle: 'Học vẽ theo video từng bước',
                      icon: Icons.school_rounded,
                      color: const Color(0xFFFF6B6B),
                      onTap: () => context.push(RoutePaths.parentCourses),
                    ),
                    const SizedBox(height: 16),

                    // Card lớn 2: Gửi bài vẽ tay
                    _buildFeatureCard(
                      title: 'Gửi Bài Vẽ',
                      subtitle: 'Chụp tranh giấy và gửi cô giáo',
                      icon: Icons.photo_camera_rounded,
                      color: const Color(0xFF4ECDC4),
                      onTap: () => context.push('/kid/lesson/free-draw/submit'),
                    ),
                    const SizedBox(height: 16),

                    // Card lớn 3: Vẽ & Ghép tranh phòng khách
                    _buildFeatureCard(
                      title: 'Vẽ & Ghép Tranh',
                      subtitle: 'Vẽ các bạn thú & ghép tranh kéo-thả vui nhộn',
                      icon: Icons.extension_rounded,
                      color: const Color(0xFFFF9F1C),
                      onTap: () => context.push(RoutePaths.matchingGame),
                    ),
                    const SizedBox(height: 16),

                    // Card lớn 4: Huy hiệu & Ngôi sao
                    _buildFeatureCard(
                      title: 'Huy Hiệu & Cúp',
                      subtitle:
                          'Bé đã đạt ${badgesState.unlockedCount}/${badgesState.totalCount} huy hiệu (${(badgesState.overallProgressRatio * 100).toInt()}%)',
                      icon: Icons.military_tech_rounded,
                      color: const Color(0xFF9B5DE5),
                      onTap: () => context.push(RoutePaths.kidBadges),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
