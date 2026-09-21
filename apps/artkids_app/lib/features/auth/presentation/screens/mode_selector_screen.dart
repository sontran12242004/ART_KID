import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/kid_ui_constants.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../kid_mode/presentation/providers/app_mode_provider.dart';

/// Màn hình chọn chế độ: Phụ huynh hoặc Trẻ em (Kid Mode)
class ModeSelectorScreen extends ConsumerWidget {
  const ModeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 3D của ứng dụng
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1982C4).withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo_3d.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 18),

                // Tên app ArtKids
                const Text(
                  'ArtKids',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: KidUiConstants.textDark,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ai đang sử dụng ứng dụng hôm nay?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C757D),
                  ),
                ),

                const SizedBox(height: 36),

                // Card Chọn Chế độ Trẻ Em (To, rực rỡ)
                _buildModeCard(
                  title: 'Bé Khám Phá 🎨',
                  subtitle: 'Vẽ tranh ma thuật, ghép hình & ngắm thú AI',
                  color: const Color(0xFFFF9F1C),
                  icon: Icons.child_care_rounded,
                  onTap: () {
                    ref.read(appModeProvider.notifier).state = AppMode.kid;
                    context.go(RoutePaths.kidPinGate);
                  },
                ),

                const SizedBox(height: 18),

                // Card Chọn Chế độ Phụ Huynh
                _buildModeCard(
                  title: 'Phụ Huynh 👨‍👩‍👧',
                  subtitle: 'Theo dõi tiến trình, đăng ký khóa học & quản lý',
                  color: const Color(0xFF2A9D8F),
                  icon: Icons.family_restroom_rounded,
                  onTap: () {
                    ref.read(appModeProvider.notifier).state = AppMode.parent;
                    context.go(RoutePaths.parentLogin);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
