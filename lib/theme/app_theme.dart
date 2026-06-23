import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF08111E);
  static const surface = Color(0xFF122034);
  static const surfaceAlt = Color(0xFF18283E);
  static const accent = Color(0xFF6AB4A7);
  static const accentWarm = Color(0xFFE0B07A);
  static const outline = Color(0xFF26384D);
  static const textPrimary = Color(0xFFF2F5F7);
  static const textSecondary = Color(0xFF9AA8B9);
  static const fontFallback = <String>[
    'Noto Color Emoji',
    'Noto Sans CJK SC',
    'Microsoft YaHei',
    'Roboto',
  ];

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: accent,
      primary: accent,
      secondary: accentWarm,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: outline,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          fontFamilyFallback: fontFallback,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: fontFallback,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: fontFallback,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          height: 1.4,
          fontFamilyFallback: fontFallback,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          height: 1.5,
          fontFamilyFallback: fontFallback,
        ),
      ),
      chipTheme:
          ChipThemeData.fromDefaults(
            secondaryColor: accent,
            brightness: Brightness.dark,
            labelStyle: const TextStyle(color: textPrimary),
          ).copyWith(
            selectedColor: accent.withValues(alpha: 0.24),
            backgroundColor: surfaceAlt,
            side: const BorderSide(color: outline),
          ),
    );
  }
}
