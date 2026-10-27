import '../../domain/entities/lesson.dart';

class LessonModel extends Lesson {
  const LessonModel({
    required super.id,
    required super.courseId,
    required super.title,
    super.videoUrl,
    super.orderIndex = 0,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      courseId:
          json['course_id'] as String? ?? json['courseId'] as String? ?? '',
      title: json['title'] as String,
      videoUrl: json['video_url'] as String? ?? json['videoUrl'] as String?,
      orderIndex:
          json['order_index'] as int? ?? json['orderIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'video_url': videoUrl,
      'order_index': orderIndex,
    };
  }
}
