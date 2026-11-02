import 'package:artkids_app/core/network/api_interceptor.dart';
import 'package:artkids_app/core/network/dio_client.dart';
import 'package:artkids_app/features/auth/presentation/providers/intro_provider.dart';
import 'package:artkids_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/http_fixture.dart';

void main() {
  testWidgets(
    'login error toast contains the readable API message, not Dio internals',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWith((ref) {
            final dio = fixtureDio(
              (request) => jsonResponse({
                'title': 'Email hoặc mật khẩu chưa đúng.',
              }, status: 401),
            );
            dio.interceptors.add(ApiInterceptor(ref, dio));
            return dio;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(introPlayedProvider.notifier).markPlayed();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'parent@example.invalid',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'InvalidPassword123!',
      );
      await tester.ensureVisible(find.text('Đăng Nhập'));
      await tester.tap(find.text('Đăng Nhập'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đăng nhập thất bại: Email hoặc mật khẩu chưa đúng.'),
        findsOneWidget,
      );
      expect(find.textContaining('DioException'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    },
  );
}
