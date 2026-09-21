import '../../domain/entities/drawing_submission.dart';

class DrawingSubmissionModel extends DrawingSubmission {
  const DrawingSubmissionModel({
    required super.id,
    required super.lessonId,
    required super.childId,
    required super.imagePath,
    super.status = 'uploaded',
    this.creatureId,
  });

  final String? creatureId;

  factory DrawingSubmissionModel.fromJson(Map<String, dynamic> json) {
    return DrawingSubmissionModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? json['lessonId'] as String? ?? '',
      childId: json['child_id'] as String? ?? json['childId'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? json['imageUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'uploaded',
      creatureId: json['creature_id'] as String? ?? json['creatureId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'child_id': childId,
      'image_path': imagePath,
      'status': status,
      'creature_id': creatureId,
    };
  }
}
