import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/kid_mode/presentation/providers/app_mode_provider.dart';
import 'features/matching_game/presentation/providers/matching_game_progress_provider.dart';

class ArtKidsApp extends ConsumerWidget {
  const ArtKidsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appMode = ref.watch(appModeProvider);
    final syncError = ref.watch(gameSyncErrorProvider);

    return MaterialApp.router(
      title: 'ArtKids',
      debugShowCheckedModeBanner: false,
      theme: appMode == AppMode.kid ? AppTheme.kid() : AppTheme.parent(),
      routerConfig: router,
      builder: (context, child) => Column(
        children: [
          if (syncError != null)
            Material(
              color: Colors.red.shade50,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Chưa lưu được tiến độ: $syncError'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(matchingGameProgressProvider.notifier)
                            .loadAll(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
