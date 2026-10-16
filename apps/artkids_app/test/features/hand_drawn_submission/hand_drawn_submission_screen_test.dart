import 'package:artkids_app/features/hand_drawn_submission/presentation/screens/hand_drawn_submission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows camera instructions before a drawing is captured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HandDrawnSubmissionScreen(lessonId: 'lesson-01')),
    );

    expect(find.text('Bé hãy vẽ trên giấy thật nhé! ✏️'), findsOneWidget);
    expect(find.text('Chụp bài vẽ 📷'), findsOneWidget);
    expect(find.text('Đặt tranh ngay ngắn trong khung hình'), findsOneWidget);
  });
}
