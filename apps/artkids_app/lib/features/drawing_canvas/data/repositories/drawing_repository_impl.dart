import '../../domain/entities/drawing_submission.dart';
import '../../domain/repositories/drawing_repository.dart';
import '../datasources/drawing_remote_datasource.dart';

class DrawingRepositoryImpl implements DrawingRepository {
  DrawingRepositoryImpl(this._remoteDataSource);

  final DrawingRemoteDataSource _remoteDataSource;

  @override
  Future<DrawingSubmission> submitDrawing({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
  }) {
    return _remoteDataSource.submitDrawing(
      lessonId: lessonId,
      childId: childId,
      pngBytes: pngBytes,
    );
  }

  @override
  Future<List<int>> exportCanvasToPng() async {
    // Canvas export handled via Flutter RepaintBoundary or flutter_painter controller
    return <int>[];
  }
}
