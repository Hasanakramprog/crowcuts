import 'package:flutter/material.dart';

/// Crown Cuts — Semantic Color Extension
///
/// Carries all context-sensitive colors through Flutter's theme system.
/// Access anywhere via:
///   final c = context.colors;
///   Container(color: c.surface);
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  // Backgrounds
  final Color background;
  final Color surface;
  final Color surface2;
  final Color surfaceLight;

  // Text
  final Color textPrimary;
  final Color textMuted;

  // Borders
  final Color borderDefault;
  final Color borderGold;

  // Shimmer / overlays
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color busyOverlay;

  // Shadows (invisible in dark, soft in light)
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
    required this.borderDefault,
    required this.borderGold,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.busyOverlay,
    required this.cardShadow,
    required this.buttonShadow,
  });

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static const dark = AppColorsExtension(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    surface2: Color(0xFF242424),
    surfaceLight: Color(0xFF2E2E2E),
    textPrimary: Color(0xFFF5F0E8),
    textMuted: Color(0xFF7A7672),
    borderDefault: Color(0xFF2E2E2E),
    borderGold: Color.fromRGBO(201, 168, 76, 0.3),
    shimmerBase: Color(0xFF242424),
    shimmerHighlight: Color(0xFF2E2E2E),
    busyOverlay: Color.fromRGBO(224, 85, 85, 0.25),
    cardShadow: [],
    buttonShadow: [
      BoxShadow(
        color: Color.fromRGBO(201, 168, 76, 0.30),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static const light = AppColorsExtension(
    background: Color(0xFFF8F5F2),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2EDE7),
    surfaceLight: Color(0xFFE8E0D6),
    textPrimary: Color(0xFF1C1916),
    textMuted: Color(0xFF8A7E72),
    borderDefault: Color(0xFFDDD5CB),
    borderGold: Color.fromRGBO(201, 168, 76, 0.45),
    shimmerBase: Color(0xFFF2EDE7),
    shimmerHighlight: Color(0xFFE8E0D6),
    busyOverlay: Color.fromRGBO(224, 85, 85, 0.12),
    cardShadow: [
      BoxShadow(
        color: Color.fromRGBO(28, 25, 22, 0.08),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Color.fromRGBO(28, 25, 22, 0.04),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color.fromRGBO(201, 168, 76, 0.35),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );

  // ─── ThemeExtension boilerplate ───────────────────────────────────────────
  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? surfaceLight,
    Color? textPrimary,
    Color? textMuted,
    Color? borderDefault,
    Color? borderGold,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? busyOverlay,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonShadow,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      borderDefault: borderDefault ?? this.borderDefault,
      borderGold: borderGold ?? this.borderGold,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      busyOverlay: busyOverlay ?? this.busyOverlay,
      cardShadow: cardShadow ?? this.cardShadow,
      buttonShadow: buttonShadow ?? this.buttonShadow,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension other, double t) {
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderGold: Color.lerp(borderGold, other.borderGold, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      busyOverlay: Color.lerp(busyOverlay, other.busyOverlay, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      buttonShadow: t < 0.5 ? buttonShadow : other.buttonShadow,
    );
  }
}

/// Ergonomic BuildContext extension — use `context.colors` anywhere.
extension AppColorsContext on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
