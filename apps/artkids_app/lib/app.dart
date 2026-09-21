import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/kid_mode/presentation/providers/app_mode_provider.dart';

class ArtKidsApp extends ConsumerWidget {
  const ArtKidsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appMode = ref.watch(appModeProvider);

    return MaterialApp.router(
      title: 'ArtKids',
      debugShowCheckedModeBanner: false,
      theme: appMode == AppMode.kid ? AppTheme.kid() : AppTheme.parent(),
      routerConfig: router,
    );
  }
}
