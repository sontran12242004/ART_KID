import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/network/dio_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final container = ProviderContainer();
  try {
    await container
        .read(authProvider.notifier)
        .restore(container.read(dioProvider));
  } catch (_) {
    // Invalid sessions are cleared by the API interceptor.
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const ArtKidsApp()),
  );
}
