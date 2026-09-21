import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/course_provider.dart';
import '../widgets/course_card.dart';

/// Danh sách khóa học vẽ — Phục vụ cả Phụ huynh & Bé với giao diện trực quan, sinh động
class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String _selectedAgeFilter = 'Tất cả';

  final List<String> _ageFilters = [
    'Tất cả',
    '4–6 tuổi',
    '5–8 tuổi',
    '6–10 tuổi',
    '7–12 tuổi',
  ];

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: const Text(
          'Khóa Học Vẽ',
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
      body: Column(
        children: [
          // Banner giới thiệu nhỏ gọn
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE2F3F5),
                  const Color(0xFFF7FDFD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE0F2F1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1687A7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Color(0xFF1687A7),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hành Trình Hội Họa Của Bé 🎨',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Lộ trình từ nét vẽ cơ bản đến tác phẩm nghệ thuật',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4C6E76),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Thanh lọc độ tuổi
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ageFilters.length,
              itemBuilder: (context, index) {
                final filter = _ageFilters[index];
                final isSelected = filter == _selectedAgeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1687A7),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF1687A7) : const Color(0xFFE0E0E0),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4C6E76),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedAgeFilter = filter);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Danh sách khóa học
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                final filteredCourses = _selectedAgeFilter == 'Tất cả'
                    ? courses
                    : courses
                        .where((c) =>
                            c.ageRange.toLowerCase().contains(_selectedAgeFilter.toLowerCase()))
                        .toList();

                if (filteredCourses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có khóa học cho độ tuổi $_selectedAgeFilter',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(coursesFutureProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: CourseCard(
                          course: course,
                          onTap: () {
                            context.push('/kid/course/${course.id}/lessons');
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1687A7)),
                    SizedBox(height: 14),
                    Text(
                      'Đang tải danh sách khóa học...',
                      style: TextStyle(color: Color(0xFF4C6E76), fontSize: 13),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể kết nối máy chủ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F3B46),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vui lòng kiểm tra kết nối mạng hoặc thử lại.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1687A7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => ref.invalidate(coursesFutureProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Thử lại',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
