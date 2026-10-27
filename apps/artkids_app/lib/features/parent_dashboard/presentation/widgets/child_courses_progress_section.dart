import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../domain/entities/course_progress.dart';
import '../providers/parent_dashboard_provider.dart';

/// Section hiển thị Tiến Độ Theo Khóa Học của bé trên ChildProgressScreen
class ChildCoursesProgressSection extends ConsumerWidget {
  const ChildCoursesProgressSection({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesProgressAsync = ref.watch(
      childCoursesProgressProvider(childId),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề section đồng bộ phong cách với các card khác
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1687A7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF1687A7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tiến Độ Theo Khóa Học',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F3B46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nội dung danh sách theo trạng thái tải dữ liệu
            coursesProgressAsync.when(
              data: (courses) {
                // Trạng thái rỗng: bé chưa tham gia khóa học nào
                if (courses.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Sắp xếp các khóa học theo thời điểm học gần nhất giảm dần (mới nhất lên đầu)
                final sortedCourses = List<CourseProgress>.from(courses)
                  ..sort((a, b) {
                    if (a.lastLearnedAt == null && b.lastLearnedAt == null) {
                      return 0;
                    }
                    if (a.lastLearnedAt == null) return 1;
                    if (b.lastLearnedAt == null) return -1;
                    return b.lastLearnedAt!.compareTo(a.lastLearnedAt!);
                  });

                // Logic lọc: nếu danh sách dài hơn 3, chỉ lấy 3 khóa học gần nhất
                final displayedCourses = sortedCourses.length > 3
                    ? sortedCourses.take(3).toList()
                    : sortedCourses;
                final bool hasMore = sortedCourses.length > 3;

                return Column(
                  children: [
                    // Danh sách tối đa 3 item
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedCourses.length,
                      separatorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: Color(0xFFECEFF1)),
                      ),
                      itemBuilder: (context, index) {
                        final courseProgress = displayedCourses[index];
                        return _CourseProgressItem(
                          item: courseProgress,
                          onTap: () {
                            // Chạm để xem danh sách bài học của khóa học
                            context.push(
                              '/kid/course/${courseProgress.courseId}/lessons',
                            );
                          },
                        );
                      },
                    ),

                    // Nút "Xem tất cả" dẫn sang màn hình danh sách đầy đủ khi có hơn 3 khóa
                    if (hasMore) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1687A7),
                            backgroundColor: const Color(
                              0xFFE2F3F5,
                            ).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            // Điều hướng sang màn hình xem tất cả tiến độ khóa học của đúng bé
                            context.push(
                              '/parent/child-progress/$childId/courses',
                            );
                          },
                          icon: const Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          label: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF1687A7),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        'Chưa tải được tiến độ khóa học.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          childCoursesProgressProvider(childId),
                        ),
                        child: const Text(
                          'Thử lại',
                          style: TextStyle(color: Color(0xFF1687A7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện trạng thái rỗng khi bé chưa bắt đầu khóa nào
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        children: [
          Icon(Icons.palette_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'Bé chưa bắt đầu khóa học nào',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn một khóa học thú vị để bé bắt đầu hành trình sáng tạo ngay hôm nay!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1687A7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              // Dẫn sang màn hình danh sách khóa học
              context.push(RoutePaths.parentCourses);
            },
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text(
              'Khám phá khóa học',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị 1 dòng khóa học với thumbnail, tên, thanh tiến độ, text bài và badge
class _CourseProgressItem extends StatelessWidget {
  const _CourseProgressItem({required this.item, required this.onTap});

  final CourseProgress item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Logic tính % tiến độ hoàn thành từ số bài hoàn thành chia tổng số bài
    final progress = item.progressPercent;
    final progressInt = item.progressPercentageInt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail nhỏ của khóa học
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child:
                    item.courseThumbnail != null &&
                        item.courseThumbnail!.isNotEmpty
                    ? Image.network(
                        item.courseThumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholderThumbnail(),
                      )
                    : _buildPlaceholderThumbnail(),
              ),
            ),
            const SizedBox(width: 12),

            // Tên khóa học và thanh tiến độ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng trên: Tên khóa học và Badge trạng thái
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.courseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F3B46),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(item.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Thanh tiến độ LinearProgressIndicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFEEF2F5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(item.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Text phụ thể hiện số bài hoàn thành / tổng số bài và %
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.completedLessons}/${item.totalLessons} bài học',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$progressInt%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getProgressColor(item.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thumbnail mặc định nếu không tải được ảnh
  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: const Color(0xFFE2F3F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.palette_rounded,
        color: Color(0xFF1687A7),
        size: 26,
      ),
    );
  }

  /// Màu thanh tiến độ tương ứng từng trạng thái
  Color _getProgressColor(CourseProgressStatus status) {
    switch (status) {
      case CourseProgressStatus.completed:
        return const Color(0xFF00B894); // Xanh lá
      case CourseProgressStatus.inProgress:
        return const Color(0xFF0984E3); // Xanh dương
      case CourseProgressStatus.notStarted:
        return const Color(0xFFB2BEC3); // Xám
    }
  }

  /// Badge nhỏ biểu thị trạng thái: "Đang học" (xanh dương), "Hoàn thành" (xanh lá + tick), "Chưa bắt đầu" (xám)
  Widget _buildStatusBadge(CourseProgressStatus status) {
    Color bgColor;
    Color textColor;
    IconData? icon;
    String label;

    switch (status) {
      case CourseProgressStatus.completed:
        bgColor = const Color(0xFFE8F8F5);
        textColor = const Color(0xFF00B894);
        icon = Icons.check_circle_rounded;
        label = 'Hoàn thành';
        break;
      case CourseProgressStatus.inProgress:
        bgColor = const Color(0xFFEBF3FC);
        textColor = const Color(0xFF0984E3);
        icon = null;
        label = 'Đang học';
        break;
      case CourseProgressStatus.notStarted:
        bgColor = const Color(0xFFF1F2F6);
        textColor = const Color(0xFF636E72);
        icon = null;
        label = 'Chưa bắt đầu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
