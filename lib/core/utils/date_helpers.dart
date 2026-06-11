import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Date and time formatting helpers.
class DateHelpers {
  /// Format a date as "Mon, 15 Jun"
  static String formatDateShort(DateTime date) {
    return DateFormat('E, d MMM').format(date);
  }

  /// Format a date as "Monday, 15 June 2025"
  static String formatDateFull(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  /// Format a date as "15 Jun 2025"
  static String formatDateCompact(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// Format time as "09:30 AM"
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get a list of the next [count] days starting from today.
  static List<DateTime> getNextDays(int count) {
    final today = DateTime.now();
    return List.generate(count, (i) => DateTime(today.year, today.month, today.day + i));
  }

  /// Check if two dates are the same day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if a date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Check if a date is tomorrow.
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Get day label: "Today", "Tomorrow", or "Mon 15"
  static String getDayLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    return DateFormat('E, d').format(date);
  }

  /// Format currency as $XX.XX
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format duration in minutes to human readable.
  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}min';
  }

  /// Get the week number for a date.
  static int getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final days = date.difference(firstDay).inDays;
    return (days / 7).ceil();
  }

  /// Get the month name.
  static String getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2025, month));
  }

  /// Get the month short name.
  static String getMonthShortName(int month) {
    return DateFormat('MMM').format(DateTime(2025, month));
  }
}
