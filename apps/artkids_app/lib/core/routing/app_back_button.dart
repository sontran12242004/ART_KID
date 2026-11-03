import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

/// A valid destination when a page was opened directly or refreshed.
String backDestination(String path, {bool staff = false}) {
  if (path == '/parent/register') return '/parent/login';
  if (path.startsWith('/staff/marketplace/reviews/')) {
    return '/staff/marketplace/reviews';
  }
  if (path.startsWith('/staff/marketplace/orders/')) {
    return '/staff/marketplace/orders';
  }
  if (path.startsWith('/staff/marketplace/') &&
      !path.endsWith('/reviews') &&
      !path.endsWith('/orders')) {
    return '/staff/marketplace';
  }
  if (path.startsWith('/staff/grading/')) return '/staff/grading';
  if (path.startsWith('/staff')) return '/staff';
  if (path.startsWith('/submissions/')) {
    return staff ? '/staff/grading' : '/parent/submissions';
  }
  if (path.startsWith('/parent/live/sessions/')) return '/parent/live';
  if (path == '/parent/live') return staff ? '/staff' : '/parent';
  if (path.startsWith('/parent/payments/') ||
      path.startsWith('/parent/orders/')) {
    return '/parent/orders';
  }
  if (path.startsWith('/parent/submissions/')) return '/parent/submissions';
  if (path == '/parent/shop/checkout') return '/parent/shop/cart';
  if (path.startsWith('/parent/shop/')) return '/parent/shop';
  if (path.startsWith('/parent/courses/')) return '/parent/courses';
  if (path.startsWith('/kid/lesson/') && path.endsWith('/submit')) {
    return path.substring(0, path.length - '/submit'.length);
  }
  if (path.startsWith('/kid/') && path != '/kid/pin') return '/kid';
  if (path.startsWith('/matching-game/')) return '/matching-game';
  if (path == '/matching-game') return '/kid';
  return staff ? '/staff' : '/parent';
}

class AppBackButton extends ConsumerWidget {
  const AppBackButton({super.key, this.fallback});
  final String? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Quay lại',
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        if (fallback != null) {
          router.go(fallback!);
          return;
        }
        final role = ref.read(authProvider).currentUser?.role;
        router.go(
          fallback ??
              backDestination(
                GoRouterState.of(context).uri.path,
                staff: role != null && role != 'parent',
              ),
        );
      }
    },
  );
}
