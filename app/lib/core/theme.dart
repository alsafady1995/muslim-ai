import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0E7C66); // emerald
  static const gold = Color(0xFFC9A227);
  static const flame = Color(0xFFF57C00);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const error = Color(0xFFC62828);
}

class AppTheme {
  static ThemeData light(Locale locale) => _build(Brightness.light, locale);
  static ThemeData dark(Locale locale) => _build(Brightness.dark, locale);

  static ThemeData _build(Brightness brightness, Locale locale) {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: brightness, secondary: AppColors.gold);
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness);
    final text = locale.languageCode == 'ar'
        ? GoogleFonts.notoKufiArabicTextTheme(base.textTheme)
        : GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: text,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(centerTitle: true, backgroundColor: scheme.surface, scrolledUnderElevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  /// Uthmani Quran text style. Amiri Quran renders the Uthmani script and marks well.
  static TextStyle quran(BuildContext context, {double size = 26, Color? color}) =>
      GoogleFonts.amiriQuran(fontSize: size, height: 2.1, color: color ?? Theme.of(context).colorScheme.onSurface);
}
