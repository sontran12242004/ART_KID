import 'package:artkids_app/core/routing/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('direct links return to a valid parent page for each flow', () {
    const expected = {
      '/staff/marketplace': '/staff',
      '/staff/marketplace/new': '/staff/marketplace',
      '/staff/marketplace/listings/123': '/staff/marketplace',
      '/staff/marketplace/reviews/123': '/staff/marketplace/reviews',
      '/staff/marketplace/orders/123': '/staff/marketplace/orders',
      '/staff/grading/courses/123': '/staff/grading',
      '/parent/settings': '/parent',
      '/parent/shop': '/parent',
      '/parent/shop/cart': '/parent/shop',
      '/parent/shop/checkout': '/parent/shop/cart',
      '/parent/shop/product/123': '/parent/shop',
      '/parent/payments/vnpay/result': '/parent/orders',
      '/parent/submissions/lessons/123': '/parent/submissions',
      '/parent/live/sessions/123': '/parent/live',
      '/kid/lesson/123/submit': '/kid/lesson/123',
      '/kid/course/123/lessons': '/kid',
      '/parent/register': '/parent/login',
    };
    for (final entry in expected.entries) {
      expect(backDestination(entry.key), entry.value, reason: entry.key);
    }
    expect(backDestination('/parent/live', staff: true), '/staff');
    expect(backDestination('/submissions/123', staff: true), '/staff/grading');
    expect(backDestination('/submissions/123'), '/parent/submissions');
  });

  for (final pushed in [false, true]) {
    testWidgets(
      pushed ? 'pops the previous page' : 'uses fallback on a direct link',
      (tester) async {
        final router = GoRouter(
          initialLocation: pushed ? '/previous' : '/detail',
          routes: [
            GoRoute(
              path: '/previous',
              builder: (_, _) => const Scaffold(body: Text('Previous')),
            ),
            GoRoute(
              path: '/fallback',
              builder: (_, _) => const Scaffold(body: Text('Fallback')),
            ),
            GoRoute(
              path: '/detail',
              builder: (_, _) => Scaffold(
                appBar: AppBar(
                  leading: const AppBackButton(fallback: '/fallback'),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );
        if (pushed) router.push('/detail');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppBackButton));
        await tester.pumpAndSettle();
        expect(find.text(pushed ? 'Previous' : 'Fallback'), findsOneWidget);
      },
    );
  }
}
