import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'app_radius.dart';

/// Crown Cuts — Full App Theme Data (Dark + Light)
class AppTheme {
  // ─── Shared text theme factory ────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color muted) {
    return GoogleFonts.dmSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: 1.0,
      ),
    );
  }

  // ─── DARK ─────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const c = AppColorsExtension.dark;
    final colorScheme = ColorScheme.dark(
      primary: AppColors.goldPrimary,
      secondary: AppColors.goldLight,
      surface: c.surface,
      error: AppColors.errorRed,
      onPrimary: c.background,
      onSecondary: c.background,
      onSurface: c.textPrimary,
      onError: Colors.white,
      outline: c.borderDefault,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      extensions: const [AppColorsExtension.dark],
      textTheme: _buildTextTheme(c.textPrimary, c.textMuted),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: c.borderDefault, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: _inputTheme(c.surface2, c.borderDefault, c.textMuted),
      elevatedButtonTheme: _elevatedButtonTheme(c.background),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      bottomNavigationBarTheme: _bottomNavTheme(c.surface, c.textMuted),
      appBarTheme: _appBarTheme(c.background, c.textPrimary),
      chipTheme: _chipTheme(c.surface2, c.textPrimary),

      dividerTheme: DividerThemeData(
        color: c.borderDefault.withAlpha(100),
        thickness: 0.5,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.goldPrimary,
        linearTrackColor: c.surface2,
      ),
    );
  }

  // ─── LIGHT ────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const c = AppColorsExtension.light;
    final colorScheme = ColorScheme.light(
      primary: AppColors.goldPrimary,
      secondary: AppColors.goldLight,
      surface: c.surface,
      error: AppColors.errorRed,
      onPrimary: Colors.white,
      onSecondary: c.background,
      onSurface: c.textPrimary,
      onError: Colors.white,
      outline: c.borderDefault,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      extensions: const [AppColorsExtension.light],
      textTheme: _buildTextTheme(c.textPrimary, c.textMuted),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shadowColor: const Color.fromRGBO(28, 25, 22, 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: _inputTheme(c.surface2, c.borderDefault, c.textMuted),
      elevatedButtonTheme: _elevatedButtonTheme(Colors.white),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      bottomNavigationBarTheme: _bottomNavTheme(c.surface, c.textMuted),
      appBarTheme: _appBarTheme(c.surface, c.textPrimary),
      chipTheme: _chipTheme(c.surface2, c.textPrimary),

      dividerTheme: DividerThemeData(
        color: c.borderDefault,
        thickness: 0.5,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.goldPrimary,
        linearTrackColor: c.surface2,
      ),
    );
  }

  // ─── Shared sub-themes ────────────────────────────────────────────────────
  static InputDecorationTheme _inputTheme(
      Color fill, Color border, Color hint) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputBorder,
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputBorder,
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputBorder,
        borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputBorder,
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputBorder,
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
      ),
      hintStyle: GoogleFonts.dmSans(fontSize: 15, color: hint),
      labelStyle: GoogleFonts.dmSans(fontSize: 15, color: hint),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color onPrimary) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: onPrimary,
        disabledBackgroundColor: const Color(0xFF3A3A3A),
        disabledForegroundColor: const Color(0xFF7A7672),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldPrimary,
        side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldPrimary,
        textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme(
      Color bg, Color unselected) {
    return BottomNavigationBarThemeData(
      backgroundColor: bg,
      selectedItemColor: AppColors.goldPrimary,
      unselectedItemColor: unselected,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle:
          GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      unselectedLabelStyle:
          GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }

  static AppBarTheme _appBarTheme(Color bg, Color fg) {
    return AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    );
  }

  static ChipThemeData _chipTheme(Color bg, Color label) {
    return ChipThemeData(
      backgroundColor: bg,
      selectedColor: AppColors.goldPrimary,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: label),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.slotBorder),
      side: BorderSide.none,
    );
  }
}
