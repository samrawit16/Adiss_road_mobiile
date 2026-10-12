import 'package:flutter/material.dart';

/// No statics: the palette lives on an instance.
class AppColors {
  AppColors();

  final Color navy = const Color(0xFF1B2B6D);
  final Color navyDark = const Color(0xFF12204F);
  final Color navyCard = const Color(0xFF25397F);
  final Color navyLight = const Color(0xFF34499B);
  final Color amber = const Color(0xFFFFB300);
  final Color amberDark = const Color(0xFFE6A200);
  final Color danger = const Color(0xFFE53935);
  final Color success = const Color(0xFF2ECC71);
  final Color bgLight = const Color(0xFFF7F8FA);
  final Color textDark = const Color(0xFF14181F);
  final Color textMuted = const Color(0xFF9AA5C8);

  // Compatibility aliases used by feature screens.
  final Color mutedText = const Color(0xFF9AA5C8);
  final Color white = Colors.white;
  final Color red = const Color(0xFFE53935);
}

/// The single palette instance used across the app (injected, not static).
final AppColors appColors = AppColors();

/// No statics: the themes are built from the shared palette instance.
class AppTheme {
  ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: appColors.bgLight,
        colorScheme: ColorScheme.fromSeed(
            seedColor: appColors.navy, brightness: Brightness.light),
      );

  ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: appColors.navyDark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: appColors.navy, brightness: Brightness.dark),
      );
}

/// The single theme instance used across the app (injected, not static).
final AppTheme appTheme = AppTheme();
