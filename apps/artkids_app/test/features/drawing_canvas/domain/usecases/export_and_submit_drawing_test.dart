import 'package:flutter_test/flutter_test.dart';

import 'package:artkids_app/features/drawing_canvas/domain/usecases/export_and_submit_drawing.dart';
import 'package:artkids_app/features/drawing_canvas/domain/entities/drawing_submission.dart';
import 'package:artkids_app/features/drawing_canvas/domain/repositories/drawing_repository.dart';

class MockDrawingRepository implements DrawingRepository {
  bool submitDrawingCalled = false;
  bool exportCanvasCalled = false;

  @override
  Future<DrawingSubmission> submitDrawing({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
  }) async {
    submitDrawingCalled = true;
    return DrawingSubmission(
      id: 'sub-001',
      lessonId: lessonId,
      childId: childId,
      imagePath: 'https://cdn.artkids.app/drawings/sub-001.png',
      status: 'uploaded',
    );
  }

  @override
  Future<List<int>> exportCanvasToPng() async {
    exportCanvasCalled = true;
    return [0x89, 0x50, 0x4E, 0x47]; // PNG magic bytes
  }
}

void main() {
  late ExportAndSubmitDrawing useCase;
  late MockDrawingRepository mockRepo;

  setUp(() {
    mockRepo = MockDrawingRepository();
    useCase = ExportAndSubmitDrawing(mockRepo);
  });

  group('ExportAndSubmitDrawing', () {
    test('submits drawing when parental consent is confirmed', () async {
      final result = await useCase(
        lessonId: 'lesson-01',
        childId: 'child-01',
        pngBytes: [1, 2, 3],
        parentalConsentConfirmed: true,
      );

      expect(result.id, equals('sub-001'));
      expect(result.lessonId, equals('lesson-01'));
      expect(mockRepo.submitDrawingCalled, isTrue);
    });

    test('throws StateError when parental consent is not confirmed', () async {
      expect(
        () => useCase(
          lessonId: 'lesson-01',
          childId: 'child-01',
          pngBytes: [1, 2, 3],
          parentalConsentConfirmed: false,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
