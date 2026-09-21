import '../entities/drawing_submission.dart';
import '../repositories/drawing_repository.dart';

/// Export canvas → PNG → upload submission-service → queue AI job
class ExportAndSubmitDrawing {
  ExportAndSubmitDrawing(this._repository);
  final DrawingRepository _repository;

  Future<DrawingSubmission> call({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
    required bool parentalConsentConfirmed,
  }) {
    if (!parentalConsentConfirmed) {
      throw StateError('Cần xác nhận phụ huynh trước khi gửi ảnh lên AI');
    }
    return _repository.submitDrawing(
      lessonId: lessonId,
      childId: childId,
      pngBytes: pngBytes,
    );
  }
}
