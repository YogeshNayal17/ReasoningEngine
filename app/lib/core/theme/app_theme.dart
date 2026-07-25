import 'package:flutter/material.dart';

/// App-wide Material 3 theme definitions.
///
/// A single seed color drives both light and dark [ColorScheme]s so the
/// palette stays internally consistent. Swap [_seedColor] once real brand
/// colors are available — nothing else should need to change.
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF3854D8);

  static ThemeData get light => _themeFrom(Brightness.light);

  static ThemeData get dark => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }
}
