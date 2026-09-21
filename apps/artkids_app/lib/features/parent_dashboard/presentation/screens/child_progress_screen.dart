import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/parent_dashboard_provider.dart';
import '../widgets/child_courses_progress_section.dart';
import '../widgets/child_progress_card.dart';

/// Màn hình Báo cáo Tiến độ Học tập của con — Parent Mode
class ChildProgressScreen extends ConsumerWidget {
  const ChildProgressScreen({
    super.key,
    this.childId = 'child-1',
  });

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(childProgressProvider(childId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: const Text(
          'Tiến Độ Học Vẽ Của Bé',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F3B46),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F3B46)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(childProgressProvider(childId));
          ref.invalidate(childCoursesProgressProvider(childId));
        },
        child: progressAsync.when(
          data: (report) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Card thống kê tổng quan
                ChildProgressCard(report: report),
                const SizedBox(height: 20),

                // 2. Section mới: Tiến độ theo khóa học của bé
                ChildCoursesProgressSection(childId: childId),
                const SizedBox(height: 20),

                // 3. Card lời khuyên sư phạm cho phụ huynh
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: Color(0xFFF39C12), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Lời khuyên sư phạm cho phụ huynh',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F3B46),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bé đang hoàn thành rất tốt các bài tập phối màu và nét cọ cơ bản. Ba mẹ nên khích lệ bé kể lại câu chuyện đằng sau mỗi bức tranh hoặc nhân vật AI để phát triển toàn diện tư duy ngôn ngữ và trí tưởng tượng sáng tạo.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1687A7)),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFE53935)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể kết nối máy chủ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F3B46)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng kiểm tra lại kết nối mạng của thiết bị.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1687A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      ref.invalidate(childProgressProvider(childId));
                      ref.invalidate(childCoursesProgressProvider(childId));
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
