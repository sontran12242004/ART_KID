import 'package:equatable/equatable.dart';

class Lesson extends Equatable {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.videoUrl,
    this.orderIndex = 0,
  });

  final String id;
  final String courseId;
  final String title;
  final String? videoUrl;
  final int orderIndex;

  @override
  List<Object?> get props => [id, courseId, title, videoUrl, orderIndex];
}
