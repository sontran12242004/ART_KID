import 'package:flutter/material.dart';

import '../constants/kid_ui_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData parent() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C5CE7),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            KidUiConstants.minTouchTarget,
            KidUiConstants.minTouchTarget,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),
    );
  }

  static ThemeData kid() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KidUiConstants.backgroundKid,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KidUiConstants.primaryKid,
        primary: KidUiConstants.primaryKid,
        secondary: KidUiConstants.secondaryKid,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: KidUiConstants.kidFontSize,
          color: KidUiConstants.textKid,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: KidUiConstants.kidTitleSize,
          color: KidUiConstants.textKid,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            KidUiConstants.largeTouchTarget,
            KidUiConstants.largeTouchTarget,
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            inherit: false,
          ),
        ),
      ),
    );
  }
}
