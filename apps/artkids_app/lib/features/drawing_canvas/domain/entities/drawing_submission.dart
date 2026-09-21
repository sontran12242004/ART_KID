import 'package:equatable/equatable.dart';

class DrawingSubmission extends Equatable {
  const DrawingSubmission({
    required this.id,
    required this.lessonId,
    required this.childId,
    required this.imagePath,
    this.status = 'uploaded',
  });

  final String id;
  final String lessonId;
  final String childId;
  final String imagePath;
  final String status;

  @override
  List<Object?> get props => [id, lessonId, childId, imagePath, status];
}
