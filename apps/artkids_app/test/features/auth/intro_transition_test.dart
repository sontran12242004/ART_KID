import 'package:artkids_app/features/auth/presentation/providers/intro_provider.dart';
import 'package:artkids_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntroPlayedProvider Tests', () {
    test('initial state is false and markPlayed sets to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(introPlayedProvider), isFalse);

      container.read(introPlayedProvider.notifier).markPlayed();
      expect(container.read(introPlayedProvider), isTrue);

      container.read(introPlayedProvider.notifier).resetForTest();
      expect(container.read(introPlayedProvider), isFalse);
    });
  });

  group('LoginScreen Transition & Intro Tests', () {
    testWidgets(
      'when intro has already played, renders login form directly and ready for interaction',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            introPlayedProvider.overrideWith(
              () => _TestIntroNotifier(initialValue: true),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Login form elements must be immediately visible and enabled
        expect(find.text('Đăng Nhập Phụ Huynh'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Mật khẩu'), findsOneWidget);
        expect(find.text('Đăng Nhập'), findsOneWidget);
        expect(find.text('Quên mật khẩu?'), findsOneWidget);
        expect(find.text('Tạo tài khoản ngay'), findsOneWidget);

        // Enter email and password to test interaction
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'parent@test.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mật khẩu'),
          '123456',
        );
        expect(find.text('parent@test.com'), findsOneWidget);
        expect(find.text('123456'), findsOneWidget);
      },
    );

    testWidgets(
      'when intro starts on launch, video fallback safely unlocks login screen without freeze',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            introPlayedProvider.overrideWith(
              () => _TestIntroNotifier(initialValue: false),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Initially in intro mode
        await tester.pump(const Duration(milliseconds: 100));

        // When video cannot load natively (test environment), it gracefully falls back
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Login form becomes available
        expect(find.text('Đăng Nhập Phụ Huynh'), findsOneWidget);
        expect(find.text('Đăng Nhập'), findsOneWidget);
        expect(container.read(introPlayedProvider), isTrue);
      },
    );
  });
}

class _TestIntroNotifier extends IntroPlayedNotifier {
  final bool initialValue;
  _TestIntroNotifier({required this.initialValue});

  @override
  bool build() => initialValue;
}
