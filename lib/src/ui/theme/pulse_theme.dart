import 'package:flutter/material.dart';

/// Self-contained dark Material 3 theme used by the inspector UI.
///
/// The package never inherits the host app's theme so it remains visually
/// consistent regardless of where it is opened from.
class PulseTheme {
  PulseTheme._();

  static const Color background = Color(0xFF0B0D10);
  static const Color surface = Color(0xFF14171C);
  static const Color surfaceAlt = Color(0xFF1B1F26);
  static const Color border = Color(0xFF262B33);
  static const Color textPrimary = Color(0xFFF2F4F8);
  static const Color textSecondary = Color(0xFF9AA3AF);
  static const Color accent = Color(0xFF7C5CFF);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  static const Color jsonKey = Color(0xFF7DD3FC);
  static const Color jsonString = Color(0xFFFCA5A5);
  static const Color jsonNumber = Color(0xFFFCD34D);
  static const Color jsonBool = Color(0xFFC4B5FD);
  static const Color jsonNull = Color(0xFF9CA3AF);
  static const Color jsonPunctuation = Color(0xFF6B7280);

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: accent,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ).apply(fontFamily: 'monospace'),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Color methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return info;
      case 'POST':
        return success;
      case 'PUT':
      case 'PATCH':
        return warning;
      case 'DELETE':
        return error;
      default:
        return textSecondary;
    }
  }

  static Color statusColor(int? statusCode) {
    if (statusCode == null) return textSecondary;
    if (statusCode >= 200 && statusCode < 300) return success;
    if (statusCode >= 300 && statusCode < 400) return info;
    if (statusCode >= 400 && statusCode < 500) return warning;
    if (statusCode >= 500) return error;
    return textSecondary;
  }
}
