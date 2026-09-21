import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { parent, kid }

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.parent);
