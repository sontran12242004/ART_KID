import '../entities/drawing_submission.dart';

abstract class DrawingRepository {
  Future<DrawingSubmission> submitDrawing({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
  });

  Future<List<int>> exportCanvasToPng();
}
