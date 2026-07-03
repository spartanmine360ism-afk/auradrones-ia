import 'package:flutter/material.dart';

class AuraColors {
  const AuraColors._();

  static const bg = Color(0xFF060A10);
  static const surface = Color(0xFF0F1722);
  static const surfaceSoft = Color(0xFF172231);
  static const electricBlue = Color(0xFF1E88FF);
  static const cyan = Color(0xFF32E6FF);
  static const mint = Color(0xFF55F0B4);
  static const amber = Color(0xFFFFC857);
  static const danger = Color(0xFFFF5A6C);
  static const text = Color(0xFFF4F8FF);
  static const muted = Color(0xFF9BA8B7);
}

class AuraTheme {
  const AuraTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AuraColors.electricBlue,
      brightness: Brightness.dark,
      surface: AuraColors.surface,
      primary: AuraColors.electricBlue,
      secondary: AuraColors.cyan,
      error: AuraColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AuraColors.bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: AuraColors.text,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: AuraColors.text,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AuraColors.text,
        ),
        bodyMedium: TextStyle(color: AuraColors.text),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AuraColors.surface.withValues(alpha: .92),
        indicatorColor: AuraColors.electricBlue.withValues(alpha: .18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (_) => const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
