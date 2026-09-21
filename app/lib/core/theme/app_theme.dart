import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Veritas design system colors
  static const _primary = Color(0xFF1E293B); // Slate 800 — authority
  static const _secondary = Color(0xFF006A61); // Teal — interactive
  static const _background = Color(0xFFF7F9FB); // Off-white canvas
  static const _surface = Color(0xFFFFFFFF);
  static const _outline = Color(0xFFC5C6CD);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _primary,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD8E3FB),
          onPrimaryContainer: Color(0xFF111C2D),
          secondary: _secondary,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFF86F2E4),
          onSecondaryContainer: Color(0xFF006F66),
          tertiary: Color(0xFF3B82F6),
          onTertiary: Colors.white,
          surface: _surface,
          onSurface: Color(0xFF191C1E),
          onSurfaceVariant: Color(0xFF45474C),
          surfaceContainerLow: Color(0xFFF2F4F6),
          surfaceContainer: Color(0xFFECEEF0),
          surfaceContainerHigh: Color(0xFFE6E8EA),
          outline: Color(0xFF75777D),
          outlineVariant: _outline,
          error: Color(0xFFBA1A1A),
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surface,
          indicatorColor: const Color(0xFF86F2E4),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          elevation: 4,
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _secondary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _outline),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF2F4F6),
          selectedColor: const Color(0xFF86F2E4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), space: 0),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _secondary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      );
}
