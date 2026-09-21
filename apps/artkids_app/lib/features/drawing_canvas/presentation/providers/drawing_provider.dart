import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/drawing_remote_datasource.dart';
import '../../data/repositories/drawing_repository_impl.dart';
import '../../domain/entities/drawing_submission.dart';
import '../../domain/repositories/drawing_repository.dart';
import '../../domain/usecases/export_and_submit_drawing.dart';

final drawingRemoteDataSourceProvider = Provider<DrawingRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DrawingRemoteDataSourceImpl(dio);
});

final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  final remote = ref.watch(drawingRemoteDataSourceProvider);
  return DrawingRepositoryImpl(remote);
});

final exportAndSubmitDrawingUseCaseProvider = Provider<ExportAndSubmitDrawing>((ref) {
  final repo = ref.watch(drawingRepositoryProvider);
  return ExportAndSubmitDrawing(repo);
});

class DrawingCanvasState {
  const DrawingCanvasState({
    this.selectedColor = Colors.black,
    this.strokeWidth = 5.0,
    this.isSubmitting = false,
    this.submissionResult,
    this.errorMessage,
  });

  final Color selectedColor;
  final double strokeWidth;
  final bool isSubmitting;
  final DrawingSubmission? submissionResult;
  final String? errorMessage;

  DrawingCanvasState copyWith({
    Color? selectedColor,
    double? strokeWidth,
    bool? isSubmitting,
    DrawingSubmission? submissionResult,
    String? errorMessage,
  }) {
    return DrawingCanvasState(
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionResult: submissionResult ?? this.submissionResult,
      errorMessage: errorMessage,
    );
  }
}

class DrawingCanvasNotifier extends StateNotifier<DrawingCanvasState> {
  DrawingCanvasNotifier(this._submitUseCase) : super(const DrawingCanvasState());

  final ExportAndSubmitDrawing _submitUseCase;

  void setColor(Color color) => state = state.copyWith(selectedColor: color);
  void setStrokeWidth(double width) => state = state.copyWith(strokeWidth: width);

  Future<DrawingSubmission?> submitDrawing({
    required String lessonId,
    required String childId,
    required List<int> pngBytes,
    required bool parentalConsent,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final result = await _submitUseCase(
        lessonId: lessonId,
        childId: childId,
        pngBytes: pngBytes,
        parentalConsentConfirmed: parentalConsent,
      );
      state = state.copyWith(
        isSubmitting: false,
        submissionResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final drawingCanvasProvider =
    StateNotifierProvider<DrawingCanvasNotifier, DrawingCanvasState>((ref) {
  final useCase = ref.watch(exportAndSubmitDrawingUseCaseProvider);
  return DrawingCanvasNotifier(useCase);
});
