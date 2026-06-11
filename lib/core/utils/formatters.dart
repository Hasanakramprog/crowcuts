import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Formatting utilities for data display.
class Formatters {
  /// Format currency as $XX.XX
  static String currency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format a date as "Mon, 15 Jun"
  static String dateShort(DateTime date) {
    return DateFormat('E, d MMM').format(date);
  }

  /// Format a date as "Monday, 15 June 2025"
  static String dateFull(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  /// Format a TimeOfDay as "9:30 AM"
  static String timeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Format duration in minutes to human-readable.
  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}min';
  }

  /// Get the ordinal suffix for a day number (1st, 2nd, 3rd, 4th, etc.).
  static String ordinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }

  /// Format rating as "4.5 ★ (124 reviews)"
  static String rating(double rating, int reviewCount) {
    return '${rating.toStringAsFixed(1)} ★ ($reviewCount reviews)';
  }

  /// Format phone number as "(555) 123-4567"
  static String phone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  /// Truncate text to max length, appending "...".
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
