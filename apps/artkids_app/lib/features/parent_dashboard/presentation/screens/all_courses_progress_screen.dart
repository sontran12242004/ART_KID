import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../domain/entities/course_progress.dart';
import '../providers/parent_dashboard_provider.dart';

/// Màn hình xem toàn bộ danh sách tiến độ theo khóa học của bé — Parent Mode
class AllCoursesProgressScreen extends ConsumerStatefulWidget {
  const AllCoursesProgressScreen({super.key, this.childId = 'child-1'});

  final String childId;

  @override
  ConsumerState<AllCoursesProgressScreen> createState() =>
      _AllCoursesProgressScreenState();
}

class _AllCoursesProgressScreenState
    extends ConsumerState<AllCoursesProgressScreen> {
  // Bộ lọc trạng thái: 'all' | 'inProgress' | 'completed' | 'notStarted'
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(
      childCoursesProgressProvider(widget.childId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: const Text(
          'Tiến Độ Các Khóa Học',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F3B46),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F3B46),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(childCoursesProgressProvider(widget.childId));
        },
        child: coursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return _buildEmptyState();
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

            // Đếm số lượng theo trạng thái
            final totalCount = sortedCourses.length;
            final inProgressCount = sortedCourses
                .where((c) => c.status == CourseProgressStatus.inProgress)
                .length;
            final completedCount = sortedCourses
                .where((c) => c.status == CourseProgressStatus.completed)
                .length;
            final notStartedCount = sortedCourses
                .where((c) => c.status == CourseProgressStatus.notStarted)
                .length;

            // Lọc danh sách theo tab đang chọn
            final filteredCourses = sortedCourses.where((c) {
              if (_selectedFilter == 'inProgress') {
                return c.status == CourseProgressStatus.inProgress;
              } else if (_selectedFilter == 'completed') {
                return c.status == CourseProgressStatus.completed;
              } else if (_selectedFilter == 'notStarted') {
                return c.status == CourseProgressStatus.notStarted;
              }
              return true; // 'all'
            }).toList();

            return Column(
              children: [
                // Thanh tab bộ lọc trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Tất cả ($totalCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'inProgress',
                          'Đang học ($inProgressCount)',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'completed',
                          'Hoàn thành ($completedCount)',
                        ),
                        if (notStartedCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'notStarted',
                            'Chưa bắt đầu ($notStartedCount)',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE8ECEF)),

                // Danh sách dọc các khóa học
                Expanded(
                  child: filteredCourses.isEmpty
                      ? Center(
                          child: Text(
                            'Không có khóa học nào trong mục này',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final item = filteredCourses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCourseCard(item),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1687A7)),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Color(0xFFE53935),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải dữ liệu tiến độ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                      childCoursesProgressProvider(widget.childId),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1687A7),
      backgroundColor: const Color(0xFFF1F4F6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4C6E76),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1687A7) : const Color(0xFFE0E0E0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = filterKey);
        }
      },
    );
  }

  Widget _buildCourseCard(CourseProgress item) {
    // Logic tính % hoàn thành: completedLessons chia totalLessons
    final progress = item.progressPercent;
    final progressInt = item.progressPercentageInt;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFECEFF1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Chuyển sang màn hình bài học khóa học
          context.push('/kid/course/${item.courseId}/lessons');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail khóa học
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child:
                          item.courseThumbnail != null &&
                              item.courseThumbnail!.isNotEmpty
                          ? Image.network(
                              item.courseThumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Tiêu đề và thông tin tiến độ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.courseTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F3B46),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(item.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.completedLessons}/${item.totalLessons} bài học đã hoàn thành',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Thanh tiến độ LinearProgressIndicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF2F5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColor(item.status),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Thông tin thời điểm học gần nhất và %
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.lastLearnedAt != null
                        ? 'Học gần nhất: ${_formatDate(item.lastLearnedAt!)}'
                        : 'Chưa tham gia học bài nào',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                      fontStyle: item.lastLearnedAt == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  Text(
                    '$progressInt%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _getColor(item.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE2F3F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.palette_rounded,
        color: Color(0xFF1687A7),
        size: 28,
      ),
    );
  }

  Color _getColor(CourseProgressStatus status) {
    switch (status) {
      case CourseProgressStatus.completed:
        return const Color(0xFF00B894);
      case CourseProgressStatus.inProgress:
        return const Color(0xFF0984E3);
      case CourseProgressStatus.notStarted:
        return const Color(0xFFB2BEC3);
    }
  }

  Widget _buildBadge(CourseProgressStatus status) {
    Color bg;
    Color text;
    IconData? icon;
    String label;

    switch (status) {
      case CourseProgressStatus.completed:
        bg = const Color(0xFFE8F8F5);
        text = const Color(0xFF00B894);
        icon = Icons.check_circle_rounded;
        label = 'Hoàn thành';
        break;
      case CourseProgressStatus.inProgress:
        bg = const Color(0xFFEBF3FC);
        text = const Color(0xFF0984E3);
        icon = null;
        label = 'Đang học';
        break;
      case CourseProgressStatus.notStarted:
        bg = const Color(0xFFF1F2F6);
        text = const Color(0xFF636E72);
        icon = null;
        label = 'Chưa bắt đầu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year lúc $hour:$minute';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text(
              'Bé chưa bắt đầu khóa học nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3B46),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các khóa học bé tham gia sẽ xuất hiện đầy đủ tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1687A7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () => context.push(RoutePaths.parentCourses),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text(
                'Khám phá khóa học',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
