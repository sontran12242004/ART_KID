import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the startup intro video and transition animation
/// has already completed during the current application lifecycle.
///
/// Once set to `true`, the app will never replay the intro on
/// rebuilds, orientation changes, keyboard toggles, or back navigation.
class IntroPlayedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markPlayed() {
    state = true;
  }

  void resetForTest() {
    state = false;
  }
}

final introPlayedProvider =
    NotifierProvider<IntroPlayedNotifier, bool>(IntroPlayedNotifier.new);
