import 'package:flutter/foundation.dart';

import '../../domain/entities/course.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

/// Triển khai CourseRepository hỗ trợ cả Remote API và Offline Fallback
class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this._remoteDataSource);

  final CourseRemoteDataSource _remoteDataSource;

  @override
  Future<List<Course>> getCourses() async {
    try {
      final courses = await _remoteDataSource.getCourses();
      if (courses.isNotEmpty) {
        return courses;
      }
    } catch (e) {
      debugPrint(
        '[CourseRepository] Không thể kết nối API ($e). Chuyển sang dữ liệu khóa học mẫu offline.',
      );
    }
    return _defaultCourses;
  }

  @override
  Future<List<Lesson>> getLessons(String courseId) async {
    try {
      final lessons = await _remoteDataSource.getLessons(courseId);
      if (lessons.isNotEmpty) {
        return lessons;
      }
    } catch (e) {
      debugPrint(
        '[CourseRepository] Không thể tải bài học từ API ($e). Chuyển sang bài học mẫu offline.',
      );
    }
    return _defaultLessonsMap[courseId] ?? _generateDefaultLessons(courseId);
  }

  @override
  Future<void> updateProgress({
    required String childId,
    required String lessonId,
    required int percent,
  }) async {
    try {
      await _remoteDataSource.updateProgress(
        childId: childId,
        lessonId: lessonId,
        percent: percent,
      );
    } catch (e) {
      debugPrint('[CourseRepository] updateProgress lưu offline: $e');
    }
  }

  // Dữ liệu khóa học mẫu phong phú chuẩn chương trình ArtKids
  static const List<Course> _defaultCourses = [
    Course(
      id: 'course_1_basic_lines',
      title: 'Nét Cọ Khởi Đầu - Bé Học Nét & Khối Cơ Bản',
      description:
          'Làm quen với các nét vẽ tự nhiên, vòng tròn diệu kỳ và những hình khối vui nhộn xung quanh bé.',
      ageRange: '4–6 tuổi',
      priceVnd: 199000,
      includesPhysicalKit: true,
    ),
    Course(
      id: 'course_2_cute_animals',
      title: 'Vương Quốc Động Vật Đáng Yêu',
      description:
          'Học cách vẽ các bạn thú cưng quen thuộc: chú mèo lười, cún con trung thành, chim sơn ca và sư tử dũng cảm.',
      ageRange: '5–8 tuổi',
      priceVnd: 249000,
      includesPhysicalKit: true,
    ),
    Course(
      id: 'course_3_color_magic',
      title: 'Phù Thủy Sắc Màu & Nghệ Thuật Pha Màu',
      description:
          'Cảm thụ màu sắc, bí kíp pha màu tương phản, sắc độ đậm nhạt và tạo ánh sáng lung linh cho bức tranh.',
      ageRange: '6–10 tuổi',
      priceVnd: 299000,
      includesPhysicalKit: true,
    ),
    Course(
      id: 'course_4_landscape_nature',
      title: 'Họa Sĩ Nhí Khám Phá Thiên Nhiên',
      description:
          'Kỹ thuật phối cảnh cơ bản, vẽ cây cối, dòng sông, ngọn núi hùng vĩ và không gian ba chiều sống động.',
      ageRange: '7–12 tuổi',
      priceVnd: 349000,
      includesPhysicalKit: true,
    ),
    Course(
      id: 'course_5_creature_ai',
      title: 'Sáng Tạo Nhân Vật & Sinh Vật AI',
      description:
          'Tự tay thiết kế nhân vật hoạt hình ngộ nghĩnh và biến nét vẽ thành sinh vật sống động với công nghệ AI ArtKids.',
      ageRange: '8–12 tuổi',
      priceVnd: 399000,
      includesPhysicalKit: true,
    ),
  ];

  static final Map<String, List<Lesson>> _defaultLessonsMap = {
    'course_1_basic_lines': const [
      Lesson(
        id: 'lesson_1_1',
        courseId: 'course_1_basic_lines',
        title: 'Bài 1: Cây cọ thần kỳ & cách cầm bút chuẩn',
        orderIndex: 0,
      ),
      Lesson(
        id: 'lesson_1_2',
        courseId: 'course_1_basic_lines',
        title: 'Bài 2: Vòng tròn vui nhộn - Vẽ mặt trời & bong bóng',
        orderIndex: 1,
      ),
      Lesson(
        id: 'lesson_1_3',
        courseId: 'course_1_basic_lines',
        title: 'Bài 3: Hình tam giác tí hon - Mái nhà & cánh buồm',
        orderIndex: 2,
      ),
      Lesson(
        id: 'lesson_1_4',
        courseId: 'course_1_basic_lines',
        title: 'Bài 4: Khối vuông kỳ diệu - Hộp quà sinh nhật',
        orderIndex: 3,
      ),
    ],
    'course_2_cute_animals': const [
      Lesson(
        id: 'lesson_2_1',
        courseId: 'course_2_cute_animals',
        title: 'Bài 1: Chú mèo tam thể cuộn tròn sưởi nắng',
        orderIndex: 0,
      ),
      Lesson(
        id: 'lesson_2_2',
        courseId: 'course_2_cute_animals',
        title: 'Bài 2: Cún con tinh nghịch vẫy đuôi mừng bé',
        orderIndex: 1,
      ),
      Lesson(
        id: 'lesson_2_3',
        courseId: 'course_2_cute_animals',
        title: 'Bài 3: Chim sơn ca hót líu lo trên cành hoa',
        orderIndex: 2,
      ),
      Lesson(
        id: 'lesson_2_4',
        courseId: 'course_2_cute_animals',
        title: 'Bài 4: Vua sư tử bờm vàng dũng mãnh',
        orderIndex: 3,
      ),
    ],
    'course_3_color_magic': const [
      Lesson(
        id: 'lesson_3_1',
        courseId: 'course_3_color_magic',
        title: 'Bài 1: Bảng màu cơ bản & phép màu hòa trộn',
        orderIndex: 0,
      ),
      Lesson(
        id: 'lesson_3_2',
        courseId: 'course_3_color_magic',
        title: 'Bài 2: Cầu vồng rực rỡ sau cơn mưa rào',
        orderIndex: 1,
      ),
      Lesson(
        id: 'lesson_3_3',
        courseId: 'course_3_color_magic',
        title: 'Bài 3: Hoàng hôn buông đỏ rực trên mặt biển',
        orderIndex: 2,
      ),
      Lesson(
        id: 'lesson_3_4',
        courseId: 'course_3_color_magic',
        title: 'Bài 4: Bầu trời đêm ngàn sao lung linh huyền ảo',
        orderIndex: 3,
      ),
    ],
    'course_4_landscape_nature': const [
      Lesson(
        id: 'lesson_4_1',
        courseId: 'course_4_landscape_nature',
        title: 'Bài 1: Con đường làng uốn lượn rợp bóng cây xanh',
        orderIndex: 0,
      ),
      Lesson(
        id: 'lesson_4_2',
        courseId: 'course_4_landscape_nature',
        title: 'Bài 2: Dãy núi tuyết trùng điệp & dòng suối trong veo',
        orderIndex: 1,
      ),
      Lesson(
        id: 'lesson_4_3',
        courseId: 'course_4_landscape_nature',
        title: 'Bài 3: Khu rừng cổ tích nhiệt đới muôn sắc hoa',
        orderIndex: 2,
      ),
    ],
    'course_5_creature_ai': const [
      Lesson(
        id: 'lesson_5_1',
        courseId: 'course_5_creature_ai',
        title: 'Bài 1: Phác thảo biểu cảm gương mặt nhân vật',
        orderIndex: 0,
      ),
      Lesson(
        id: 'lesson_5_2',
        courseId: 'course_5_creature_ai',
        title: 'Bài 2: Thiết kế trang phục siêu anh hùng sắc màu',
        orderIndex: 1,
      ),
      Lesson(
        id: 'lesson_5_3',
        courseId: 'course_5_creature_ai',
        title: 'Bài 3: Hô biến tranh vẽ thành sinh vật AI chuyển động',
        orderIndex: 2,
      ),
    ],
  };

  static List<Lesson> _generateDefaultLessons(String courseId) {
    return [
      Lesson(
        id: '${courseId}_lesson_1',
        courseId: courseId,
        title: 'Bài 1: Khởi động & Nét vẽ sáng tạo',
        orderIndex: 0,
      ),
      Lesson(
        id: '${courseId}_lesson_2',
        courseId: courseId,
        title: 'Bài 2: Phối màu & Hoàn thiện tác phẩm',
        orderIndex: 1,
      ),
    ];
  }
}
