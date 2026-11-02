import 'package:flutter/material.dart';

/// Shows the latest result without replaying obsolete notifications afterward.
void showAppSnackBar(BuildContext context, SnackBar snackBar) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..removeCurrentSnackBar()
    ..showSnackBar(snackBar);
}
