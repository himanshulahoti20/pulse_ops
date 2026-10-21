import 'package:flutter/material.dart';

/// A complete colour set for the inspector UI.
///
/// Pass your own to [PulseOpsConfig.theme] / [PulseOpsConfig.extraThemes] to
/// brand the inspector; users can switch between them in the settings sheet.
@immutable
class PulsePalette {
  const PulsePalette({
    required this.name,
    this.brightness = Brightness.dark,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    this.success = const Color(0xFF4ADE80),
    this.warning = const Color(0xFFFBBF24),
    this.error = const Color(0xFFF87171),
    this.info = const Color(0xFF60A5FA),
    this.jsonKey = const Color(0xFF7DD3FC),
    this.jsonString = const Color(0xFFFCA5A5),
    this.jsonNumber = const Color(0xFFFCD34D),
    this.jsonBool = const Color(0xFFC4B5FD),
    this.jsonNull = const Color(0xFF9CA3AF),
    this.jsonPunctuation = const Color(0xFF6B7280),
  });

  final String name;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color jsonKey;
  final Color jsonString;
  final Color jsonNumber;
  final Color jsonBool;
  final Color jsonNull;
  final Color jsonPunctuation;

  static const PulsePalette dark = PulsePalette(
    name: 'Dark',
    background: Color(0xFF0B0D10),
    surface: Color(0xFF14171C),
    surfaceAlt: Color(0xFF1B1F26),
    border: Color(0xFF262B33),
    textPrimary: Color(0xFFF2F4F8),
    textSecondary: Color(0xFF9AA3AF),
    accent: Color(0xFF7C5CFF),
  );

  static const PulsePalette midnight = PulsePalette(
    name: 'Midnight',
    background: Color(0xFF050B1A),
    surface: Color(0xFF0B1630),
    surfaceAlt: Color(0xFF12213F),
    border: Color(0xFF1E3158),
    textPrimary: Color(0xFFE6EEFF),
    textSecondary: Color(0xFF8FA3C8),
    accent: Color(0xFF38BDF8),
  );

  static const PulsePalette light = PulsePalette(
    name: 'Light',
    brightness: Brightness.light,
    background: Color(0xFFF6F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF0F5),
    border: Color(0xFFD9DEE7),
    textPrimary: Color(0xFF14171C),
    textSecondary: Color(0xFF5B6472),
    accent: Color(0xFF6D4AFF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    jsonKey: Color(0xFF0369A1),
    jsonString: Color(0xFFB91C1C),
    jsonNumber: Color(0xFFB45309),
    jsonBool: Color(0xFF6D28D9),
    jsonNull: Color(0xFF6B7280),
    jsonPunctuation: Color(0xFF9CA3AF),
  );

  static const PulsePalette highContrast = PulsePalette(
    name: 'High contrast',
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceAlt: Color(0xFF161616),
    border: Color(0xFF5A5A5A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD0D0D0),
    accent: Color(0xFFFFD60A),
  );

  static const List<PulsePalette> builtIn = [
    dark,
    midnight,
    light,
    highContrast
  ];

  @override
  bool operator ==(Object other) =>
      other is PulsePalette && other.name == name && other.accent == accent;

  @override
  int get hashCode => Object.hash(name, accent);
}

/// Inspector theme. The active palette and layout flags are global (like the
/// inspector itself) and can be changed at runtime from the settings sheet.
///
/// The package never inherits the host app's theme so it remains visually
/// consistent regardless of where it is opened from.
class PulseTheme {
  PulseTheme._();

  static final ValueNotifier<PulsePalette> palette =
      ValueNotifier<PulsePalette>(PulsePalette.dark);

  /// Tighter paddings in lists and tiles.
  static final ValueNotifier<bool> compact = ValueNotifier<bool>(false);

  /// Entrance / transition animations in the inspector.
  static final ValueNotifier<bool> animations = ValueNotifier<bool>(true);

  static PulsePalette get _p => palette.value;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get border => _p.border;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get accent => _p.accent;
  static Color get success => _p.success;
  static Color get warning => _p.warning;
  static Color get error => _p.error;
  static Color get info => _p.info;

  static Color get jsonKey => _p.jsonKey;
  static Color get jsonString => _p.jsonString;
  static Color get jsonNumber => _p.jsonNumber;
  static Color get jsonBool => _p.jsonBool;
  static Color get jsonNull => _p.jsonNull;
  static Color get jsonPunctuation => _p.jsonPunctuation;

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: _p.brightness,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: _p.brightness,
      colorScheme: scheme.copyWith(
        primary: accent,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ).apply(fontFamily: 'monospace'),
      appBarTheme: AppBarTheme(
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
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      snackBarTheme: SnackBarThemeData(
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
