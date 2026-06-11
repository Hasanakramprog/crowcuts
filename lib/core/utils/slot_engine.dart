import 'package:flutter/material.dart';

import '../../data/models/work_schedule.dart';
import '../../data/models/booking_model.dart';

/// Represents a single time slot in the booking UI.
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final SlotStatus status;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    this.status = SlotStatus.free,
  });

  TimeSlot copyWith({SlotStatus? status}) =>
      TimeSlot(startTime: startTime, endTime: endTime, status: status ?? this.status);

  String get startLabel {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get endLabel {
    final h = endTime.hour.toString().padLeft(2, '0');
    final m = endTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get label => '$startLabel - $endLabel';

  @override
  String toString() => 'TimeSlot($label, ${status.name})';
}

enum SlotStatus { free, almostFull, taken, selected }

/// Pure Dart utility for generating time slots.
/// No UI dependencies. Must be unit-testable.
class SlotEngine {
  /// Generate available time slots for a given barber on a given date.
  ///
  /// [schedule] — The barber's work schedule
  /// [date] — The date to generate slots for
  /// [existingBookings] — Existing bookings for this barber on this date
  /// [requiredDurationMinutes] — Total duration of selected services
  static List<TimeSlot> generateSlots({
    required WorkSchedule schedule,
    required DateTime date,
    required List<BookingModel> existingBookings,
    required int requiredDurationMinutes,
  }) {
    // 1. Check if date is a day off
    if (schedule.isDayOff(date)) return [];

    // 2. Find day schedule
    // date.weekday: 1=Monday ... 7=Sunday (matches our DaySchedule)
    final daySchedule = schedule.forWeekday(date.weekday);
    if (daySchedule == null || !daySchedule.isWorking) return [];

    final interval = daySchedule.slotIntervalMinutes;
    final startMinute = daySchedule.startTime.hour * 60 + daySchedule.startTime.minute;
    final endMinute = daySchedule.endTime.hour * 60 + daySchedule.endTime.minute;

    // Upgrade 3: pre-compute "now" so past slots are hidden when date is today.
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    // 3. Generate candidate slots
    final slots = <TimeSlot>[];
    for (int m = startMinute; m + requiredDurationMinutes <= endMinute; m += interval) {
      // Upgrade 3: skip slots that have already started when viewing today.
      if (isToday && m < nowMinutes) continue;

      final slotStart = TimeOfDay(hour: m ~/ 60, minute: m % 60);
      final slotEndMinutes = m + requiredDurationMinutes;
      final slotEnd = TimeOfDay(
        hour: slotEndMinutes ~/ 60,
        minute: slotEndMinutes % 60,
      );

      // 4. Check for overlap with existing bookings
      final isTaken = _checkOverlap(
        slotStartMinute: m,
        slotEndMinute: m + requiredDurationMinutes,
        existingBookings: existingBookings,
      );

      if (isTaken) {
        slots.add(TimeSlot(startTime: slotStart, endTime: slotEnd, status: SlotStatus.taken));
      } else {
        slots.add(TimeSlot(startTime: slotStart, endTime: slotEnd, status: SlotStatus.free));
      }
    }

    // 5. Mark "almost full" — last free slot before each taken block
    _markAlmostFull(slots);

    return slots;
  }

  /// Check if a slot overlaps any existing booking.
  static bool _checkOverlap({
    required int slotStartMinute,
    required int slotEndMinute,
    required List<BookingModel> existingBookings,
  }) {
    for (final booking in existingBookings) {
      if (booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.noShow) continue;

      final bookingStart =
          booking.startTime.hour * 60 + booking.startTime.minute;
      final bookingEnd = bookingStart + booking.totalDurationMinutes;

      // Check if intervals overlap
      if (slotStartMinute < bookingEnd && slotEndMinute > bookingStart) {
        return true;
      }
    }
    return false;
  }

  /// Mark the last free slot before each taken block as 'almostFull'.
  ///
  /// Upgrade 2: fixed — previously only the globally last free slot was marked.
  /// Now every free slot that is immediately followed by a taken slot is marked,
  /// so each booking gap gets its own "LAST!" warning.
  static void _markAlmostFull(List<TimeSlot> slots) {
    for (int i = 0; i < slots.length - 1; i++) {
      if (slots[i].status == SlotStatus.free &&
          slots[i + 1].status == SlotStatus.taken) {
        slots[i] = slots[i].copyWith(status: SlotStatus.almostFull);
      }
    }
  }
}
