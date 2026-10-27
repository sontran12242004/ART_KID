import 'package:equatable/equatable.dart';

import '../../../courses/domain/entities/course.dart';

/// Trạng thái tiến độ học của một khóa học
enum CourseProgressStatus {
  inProgress('Đang học'),
  completed('Hoàn thành'),
  notStarted('Chưa bắt đầu');

  const CourseProgressStatus(this.label);
  final String label;

  static CourseProgressStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'completed':
      case 'hoàn thành':
        return CourseProgressStatus.completed;
      case 'inprogress':
      case 'in_progress':
      case 'đang học':
        return CourseProgressStatus.inProgress;
      case 'notstarted':
      case 'not_started':
      case 'chưa bắt đầu':
      default:
        return CourseProgressStatus.notStarted;
    }
  }
}

/// Model tiến độ học tập theo từng khóa học của bé
class CourseProgress extends Equatable {
  const CourseProgress({
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnail,
    required this.totalLessons,
    required this.completedLessons,
    this.lastLearnedAt,
    required this.status,
    this.course,
  });

  /// Mã định danh khóa học
  final String courseId;

  /// Tên hiển thị của khóa học
  final String courseTitle;

  /// Đường dẫn hoặc URL ảnh đại diện khóa học
  final String? courseThumbnail;

  /// Tổng số bài học trong khóa
  final int totalLessons;

  /// Số bài học bé đã hoàn thành
  final int completedLessons;

  /// Thời điểm bé tham gia học khóa học này gần nhất (dùng để lọc sắp xếp)
  final DateTime? lastLearnedAt;

  /// Trạng thái hiện tại của khóa học (Đang học, Hoàn thành, Chưa bắt đầu)
  final CourseProgressStatus status;

  /// Tái sử dụng đối tượng Course gốc từ feature khóa học nếu có
  final Course? course;

  /// Logic tính tỷ lệ phần trăm tiến độ hoàn thành từ 0.0 đến 1.0
  double get progressPercent {
    if (totalLessons <= 0) return 0.0;
    // Tỷ lệ bài đã xong chia tổng số bài, giới hạn trong khoảng [0.0, 1.0]
    final ratio = completedLessons / totalLessons;
    return ratio.clamp(0.0, 1.0);
  }

  /// Tỷ lệ phần trăm dạng số nguyên (0 - 100%) để hiển thị trên giao diện
  int get progressPercentageInt => (progressPercent * 100).round();

  /// Khởi tạo CourseProgress tiện lợi từ entity Course gốc
  factory CourseProgress.fromCourse({
    required Course course,
    required int totalLessons,
    required int completedLessons,
    DateTime? lastLearnedAt,
    CourseProgressStatus? status,
  }) {
    // Tự động suy luận trạng thái nếu không truyền vào
    final computedStatus =
        status ??
        (completedLessons >= totalLessons && totalLessons > 0
            ? CourseProgressStatus.completed
            : completedLessons > 0
            ? CourseProgressStatus.inProgress
            : CourseProgressStatus.notStarted);

    return CourseProgress(
      courseId: course.id,
      courseTitle: course.title,
      courseThumbnail: course.thumbnailUrl,
      totalLessons: totalLessons,
      completedLessons: completedLessons,
      lastLearnedAt: lastLearnedAt,
      status: computedStatus,
      course: course,
    );
  }

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId:
          json['course_id'] as String? ?? json['courseId'] as String? ?? '',
      courseTitle:
          json['course_title'] as String? ??
          json['courseTitle'] as String? ??
          '',
      courseThumbnail:
          json['course_thumbnail'] as String? ??
          json['courseThumbnail'] as String?,
      totalLessons:
          json['total_lessons'] as int? ?? json['totalLessons'] as int? ?? 0,
      completedLessons:
          json['completed_lessons'] as int? ??
          json['completedLessons'] as int? ??
          0,
      lastLearnedAt: json['last_learned_at'] != null
          ? DateTime.tryParse(json['last_learned_at'].toString())
          : (json['lastLearnedAt'] != null
                ? DateTime.tryParse(json['lastLearnedAt'].toString())
                : null),
      status: CourseProgressStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'course_title': courseTitle,
      'course_thumbnail': courseThumbnail,
      'total_lessons': totalLessons,
      'completed_lessons': completedLessons,
      'last_learned_at': lastLearnedAt?.toIso8601String(),
      'status': status.name,
    };
  }

  CourseProgress copyWith({
    String? courseId,
    String? courseTitle,
    String? courseThumbnail,
    int? totalLessons,
    int? completedLessons,
    DateTime? lastLearnedAt,
    CourseProgressStatus? status,
    Course? course,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      courseThumbnail: courseThumbnail ?? this.courseThumbnail,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      lastLearnedAt: lastLearnedAt ?? this.lastLearnedAt,
      status: status ?? this.status,
      course: course ?? this.course,
    );
  }

  @override
  List<Object?> get props => [
    courseId,
    courseTitle,
    courseThumbnail,
    totalLessons,
    completedLessons,
    lastLearnedAt,
    status,
    course,
  ];
}
