import 'package:artkids_app/features/connected/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('latest toast replaces current and queued messages', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    ScaffoldMessenger.of(pageContext)
      ..showSnackBar(const SnackBar(content: Text('Old current')))
      ..showSnackBar(const SnackBar(content: Text('Old queued')));
    await tester.pumpAndSettle();
    toast(pageContext, 'Latest result');
    await tester.pumpAndSettle();
    expect(find.text('Latest result'), findsOneWidget);
    expect(find.text('Old current'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Old queued'), findsNothing);
  });

  testWidgets('repeated identical toasts do not replay after timeout', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      toast(pageContext, 'Repeated result');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Repeated result'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('late toast ignores an unmounted context', (tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    expect(() => toast(pageContext, 'Late result'), returnsNormally);
  });
}
