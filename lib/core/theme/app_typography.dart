import 'package:flutter/material.dart';

/// Crown Cuts Design System — Typography
///
/// Spec: Section 9.2
/// Playfair Display for display/headings, DM Sans for body text.
abstract class AppTypography {
  // Font Families
  static const String displayFont = 'Playfair Display';
  static const String bodyFont = 'DM Sans';

  // Display — 28px, 700, Playfair Display
  static TextStyle display = const TextStyle(
    fontFamily: displayFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // Heading 1 — 22px, 600, DM Sans
  static TextStyle heading1 = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  // Heading 2 — 17px, 600, DM Sans
  static TextStyle heading2 = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // Body — 15px, 400, DM Sans
  static TextStyle body = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // Body Bold — 15px, 600, DM Sans
  static TextStyle bodyBold = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // Caption — 13px, 400, DM Sans
  static TextStyle caption = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // Label — 11px, 600, DM Sans (UPPERCASE)
  static TextStyle label = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.0,
  );

  // Button Text — 16px, 600, DM Sans
  static TextStyle button = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // Small Button Text — 14px, 600, DM Sans
  static TextStyle buttonSmall = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // Price Text — 17px, 700, DM Sans (gold)
  static TextStyle price = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // Large Price — 24px, 700, DM Sans
  static TextStyle priceLarge = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // Time text — 15px, 500, DM Sans
  static TextStyle time = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}
