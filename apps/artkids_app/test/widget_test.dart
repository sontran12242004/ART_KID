import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artkids_app/app.dart';

void main() {
  testWidgets('ArtKidsApp launches successfully with ProviderScope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ArtKidsApp()));

    // Verify ArtKidsApp renders initial Splash/Mode selector
    expect(find.byType(ArtKidsApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
