import 'package:flutter/material.dart';

/// Crown Cuts Design System — Border Radius
///
/// Spec: Section 9.4
abstract class AppRadius {
  static const double cards = 20;
  static const double buttons = 16;
  static const double inputs = 12;
  static const double slots = 12;
  static const double badges = 20;
  static const double avatar = 999; // Fully rounded

  static BorderRadius get cardBorder => BorderRadius.circular(cards);
  static BorderRadius get buttonBorder => BorderRadius.circular(buttons);
  static BorderRadius get inputBorder => BorderRadius.circular(inputs);
  static BorderRadius get slotBorder => BorderRadius.circular(slots);
  static BorderRadius get badgeBorder => BorderRadius.circular(badges);
}
