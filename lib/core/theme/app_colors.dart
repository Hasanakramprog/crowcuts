import 'package:flutter/material.dart';

/// Crown Cuts Design System — Color Palette
///
/// Spec: Section 9.1
/// Dark theme with gold accents.
abstract class AppColors {
  // Gold / Primary
  static const Color goldPrimary = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8D5A0);
  static const Color goldDim = Color.fromRGBO(201, 168, 76, 0.3);
  static const Color goldShadow = Color.fromRGBO(201, 168, 76, 0.25);

  // Dark Backgrounds
  static const Color darkBackground = Color(0xFF111111);
  static const Color surface = Color(0xFF242424);
  static const Color surface2 = Color(0xFF2E2E2E);
  static const Color surfaceLight = Color(0xFF3A3A3A);

  // Text
  static const Color textPrimary = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFF7A7672);

  // Status
  static const Color successGreen = Color(0xFF4CAF7D);
  static const Color errorRed = Color(0xFFE05555);
  static const Color warningAmber = Color(0xFFE89040);

  // Borders
  static const Color borderDefault = Color(0xFF333333);
  static const Color borderGold = Color.fromRGBO(201, 168, 76, 0.3);

  // Specific uses
  static const Color busyOverlay = Color.fromRGBO(224, 85, 85, 0.25);
  static const Color shimmerBase = Color(0xFF2E2E2E);
  static const Color shimmerHighlight = Color(0xFF3A3A3A);

  // Avatar colors (for initials circles)
  static const List<Color> avatarColors = [
    Color(0xFFC9A84C),
    Color(0xFF4CAF7D),
    Color(0xFF5B8DEF),
    Color(0xFFE89040),
    Color(0xFF9B59B6),
    Color(0xFFE05555),
    Color(0xFF1ABC9C),
    Color(0xFF3498DB),
  ];
}
