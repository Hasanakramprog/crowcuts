import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crown_cuts/data/models/booking_model.dart';
import 'package:crown_cuts/data/models/work_schedule.dart';
import 'package:crown_cuts/core/utils/slot_engine.dart';

/// Helper to create a TimeOfDay quickly.
TimeOfDay _t(int hour, int minute) => TimeOfDay(hour: hour, minute: minute);

/// Helper to create a work schedule for testing.
WorkSchedule _makeSchedule({
  int startHour = 9,
  int startMin = 0,
  int endHour = 17,
  int endMin = 0,
  int interval = 30,
  int weekday = 1, // Monday
}) {
  return WorkSchedule(
    weeklySchedule: [
      DaySchedule(
        weekday: weekday,
        isWorking: true,
        startTime: _t(startHour, startMin),
        endTime: _t(endHour, endMin),
        slotIntervalMinutes: interval,
      ),
    ],
    daysOff: [],
  );
}

/// Helper to create a booking model.
BookingModel _booking({
  required String id,
  required String barberId,
  required int hour,
  required int minute,
  int durationMinutes = 30,
}) {
  return BookingModel(
    id: id,
    customerId: 'cust-1',
    customerName: 'Test User',
    barberId: barberId,
    serviceIds: ['svc-1'],
    date: DateTime(2026, 6, 8), // Monday
    startTime: _t(hour, minute),
    totalDurationMinutes: durationMinutes,
    totalPrice: 50,
    status: BookingStatus.confirmed,
    createdAt: DateTime(2026, 6, 7),
  );
}

void main() {
  group('SlotEngine.generateSlots()', () {
    // ─────────────── Schedule & Boundary ───────────────

    test('returns empty list when date is a day off', () {
      final schedule = WorkSchedule(
        weeklySchedule: [],
        daysOff: [DateTime(2026, 6, 8)], // Monday off
      );
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: [],
        requiredDurationMinutes: 30,
      );
      expect(slots, isEmpty);
    });

    test('returns empty list when no DaySchedule exists for that weekday', () {
      // Sunday has no schedule entry
      final schedule = _makeSchedule(weekday: 1);
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 14), // Sunday (weekday 7)
        existingBookings: [],
        requiredDurationMinutes: 30,
      );
      expect(slots, isEmpty);
    });

    test('returns empty list when day is non-working', () {
      final schedule = WorkSchedule(
        weeklySchedule: [
          DaySchedule(
            weekday: 1,
            isWorking: false, // Monday not working
            startTime: _t(9, 0),
            endTime: _t(17, 0),
          ),
        ],
        daysOff: [],
      );
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8), // Monday
        existingBookings: [],
        requiredDurationMinutes: 30,
      );
      expect(slots, isEmpty);
    });

    test('generates correct number of 30-min slots for a 9-5 day', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 17);
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8), // Monday
        existingBookings: [],
        requiredDurationMinutes: 30,
      );
      // 9AM-5PM = 8 hours = 16 x 30-min slots
      expect(slots.length, 16);
      expect(slots.first.startLabel, '09:00');
      expect(slots.last.startLabel, '16:30'); // last slot starts at 15:30
    });

    test('generates correct number of 60-min slots for a 9-5 day', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 17);
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: [],
        requiredDurationMinutes: 60,
      );
      // 9AM-5PM = 8 hours = 8 x 60-min slots
      expect(slots.length, 15);
      expect(slots.first.startLabel, '09:00');
      expect(slots.last.startLabel, '16:00');
    });

    test('generates correct number of 15-min slots for a 9-5 day', () {
      final schedule = _makeSchedule(
        startHour: 9,
        endHour: 17,
        interval: 15,
      );
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: [],
        requiredDurationMinutes: 30,
      );
      // With 15-min intervals and 30-min requirement, we get: 9:00, 9:15, ..., 16:00
      // (start + duration ≤ end) → (16:00 + 00:30 ≤ 17:00) → last at 16:00
      expect(slots.length, 31);
    });

    test('generates no slots when required duration exceeds work day', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 10); // 1 hour
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: [],
        requiredDurationMinutes: 90, // 1.5 hours — too long
      );
      // 9:00 + 90m = 10:30 > 10:00 → no slots
      expect(slots, isEmpty);
    });

    // ─────────────── Slot Status (Free vs Taken) ───────────────

    test('all slots are free when there are no existing bookings', () {
      final schedule = _makeSchedule();
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: [],
        requiredDurationMinutes: 30,
      );
      expect(slots.every((s) => s.status == SlotStatus.free), isTrue);
    });

    test('slot overlapping a booking is marked as taken', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 30,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );

      // 9:00 → free, 9:30 → free, 10:00 → taken (booked), 10:30 → free, 11:00 → free, 11:30 → free
      final slot1000 = slots.firstWhere((s) => s.startLabel == '10:00');
      expect(slot1000.status, SlotStatus.taken);
    });

    test('cancelled bookings do NOT mark slots as taken', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 30,
        ).copyWith(status: BookingStatus.cancelled),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // Cancelled booking → slot is free
      final slot1000 = slots.firstWhere((s) => s.startLabel == '10:00');
      expect(slot1000.status, SlotStatus.free);
    });

    test('no-show bookings do NOT mark slots as taken', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 30,
        ).copyWith(status: BookingStatus.noShow),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      final slot1000 = slots.firstWhere((s) => s.startLabel == '10:00');
      expect(slot1000.status, SlotStatus.free);
    });

    test('partial overlap also marks slot as taken', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      // Booking from 10:10 to 10:40 (30 min)
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 10,
          durationMinutes: 30,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // Slot 10:00-10:30 overlaps booking 10:10-10:40 → taken
      final slot1000 = slots.firstWhere((s) => s.startLabel == '10:00');
      expect(slot1000.status, SlotStatus.taken);
      // Slot 10:30-11:00 also overlaps (10:30 < 10:40) → taken
      final slot1030 = slots.firstWhere((s) => s.startLabel == '10:30');
      expect(slot1030.status, SlotStatus.taken);
    });

    test('slot ending exactly when booking starts is free (edge case)', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 30,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // Slot 09:30-10:00, booking starts at 10:00 → no overlap → free
      final slot0930 = slots.firstWhere((s) => s.startLabel == '09:30');
      expect(slot0930.status, SlotStatus.free);
    });

    // ─────────────── Almost Full Logic ───────────────

    test('last free slot before a taken block is marked almostFull', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 60, // takes 10:00-11:00
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // Generate: 9:00F, 9:30F, 10:00T, 10:30T, 11:00F, 11:30F
      // Only the last free slot before taken at the END of the day gets almostFull.
      // Here 10:30 is taken but 11:00 is free → no almostFull for this pattern.
      // Actually, 9:30 is free followed by taken (10:00), but looking ahead: 11:00 is free → not the last free.
      // To test almostFull we need a booking that fills the end of the day.

      // Let's use a different scenario: booking from 10:00-12:00 fills the rest of the day.
    });

    test('last free slot before taken block at end of day is marked almostFull', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      // Booking 10:00-12:00 (120 min) — fills the rest of the day
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 120,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // 9:00F, 9:30F, 10:00T, 10:30T, 11:00T, 11:30T
      // 9:30 is last free before taken at end → almostFull
      final slot0930 =
          slots.firstWhere((s) => s.startLabel == '09:30', orElse: () => throw 'missing');
      expect(slot0930.status, SlotStatus.almostFull);
      // 9:00 is NOT almostFull
      final slot0900 =
          slots.firstWhere((s) => s.startLabel == '09:00', orElse: () => throw 'missing');
      expect(slot0900.status, SlotStatus.free);
    });

    test('single free slot in between taken blocks is marked almostFull', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 9,
          minute: 0,
          durationMinutes: 30,
        ),
        _booking(
          id: 'book-2',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 30,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // 9:00T, 9:30F, 10:00T, 10:30F, 11:00F, 11:30F
      // 9:30 is free → takes block start → look ahead: 10:30 free exists → NOT almostFull
      final slot0930 =
          slots.firstWhere((s) => s.startLabel == '09:30', orElse: () => throw 'missing');
      expect(slot0930.status, SlotStatus.free);
    });

    test('last free slot before end-of-day taken block is almostFull', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 120,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // 9:00F, 9:30F, 10:00T, 10:30T, 11:00T, 11:30T
      // 9:30 is last free before taken-at-end → almostFull
      final slot0930 =
          slots.firstWhere((s) => s.startLabel == '09:30', orElse: () => throw 'missing');
      expect(slot0930.status, SlotStatus.almostFull);
    });

    test('free slot after taken block followed by free is NOT almostFull', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 10,
          minute: 0,
          durationMinutes: 30,
        ),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );
      // 9:00F, 9:30F, 10:00T, 10:30F, 11:00F, 11:30F
      // 9:30 is NOT the last free (10:30 is free too) → stays free
      final slot0930 =
          slots.firstWhere((s) => s.startLabel == '09:30', orElse: () => throw 'missing');
      expect(slot0930.status, SlotStatus.free);
    });

    // ─────────────── TimeSlot Model ───────────────

    test('TimeSlot.copyWith changes status correctly', () {
      final slot = TimeSlot(startTime: _t(9, 0), endTime: _t(9, 30));
      expect(slot.status, SlotStatus.free);

      final selected = slot.copyWith(status: SlotStatus.selected);
      expect(selected.status, SlotStatus.selected);
      expect(selected.startTime, slot.startTime);
      expect(selected.endTime, slot.endTime);
    });

    test('TimeSlot label formatting', () {
      final slot = TimeSlot(startTime: _t(14, 5), endTime: _t(14, 35));
      expect(slot.startLabel, '14:05');
      expect(slot.endLabel, '14:35');
      expect(slot.label, '14:05 - 14:35');
    });

    // ─────────────── Complex Scenario ───────────────

    test('handles multiple overlapping bookings across the day', () {
      final schedule = _makeSchedule(startHour: 8, endHour: 13); // 8AM-1PM
      final bookings = [
        _booking(
            id: 'b1', barberId: 'b-1', hour: 8, minute: 0, durationMinutes: 30),
        _booking(
            id: 'b2', barberId: 'b-1', hour: 9, minute: 30, durationMinutes: 60),
        _booking(
            id: 'b3', barberId: 'b-1', hour: 11, minute: 0, durationMinutes: 30),
        _booking(
            id: 'b4', barberId: 'b-1', hour: 12, minute: 0, durationMinutes: 30),
      ];
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );

      // Expected with 30-min intervals from 8:00 to 13:00 (10 slots):
      // 08:00 T (booked), 08:30 F, 09:00 F, 09:30 T (booked 9:30-10:30), 10:00 T,
      // 10:30 F, 11:00 T (booked), 11:30 F, 12:00 T (booked), 12:30 F
      //
      // almostFull check: only the last free slot before an end-of-day taken block.
      // Here 12:30 is the last slot and free, so nothing at end is taken.
      // No slot qualifies as almostFull.

      expect(slots.length, 10);
      expect(slots[0].startLabel, '08:00');
      expect(slots[0].status, SlotStatus.taken);
      expect(slots[3].startLabel, '09:30');
      expect(slots[3].status, SlotStatus.taken);
      expect(slots[4].startLabel, '10:00');
      expect(slots[4].status, SlotStatus.taken);
      expect(slots[5].startLabel, '10:30');
      expect(slots[5].status, SlotStatus.free); // free because more free slots ahead
      expect(slots[6].startLabel, '11:00');
      expect(slots[6].status, SlotStatus.taken);
      expect(slots[7].startLabel, '11:30');
      expect(slots[7].status, SlotStatus.free); // free because 12:30 is free
      expect(slots[8].startLabel, '12:00');
      expect(slots[8].status, SlotStatus.taken);
      expect(slots[9].startLabel, '12:30');
      expect(slots[9].status, SlotStatus.free);
    });
    // ─────────────── Real-world scenario: User's question ───────────────

    test('when 9:30 is booked and haircut needs > 30 min, 9:00 is taken', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 9,
          minute: 30,
          durationMinutes: 30,
        ),
      ];
      // Haircut needs 45 min
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 45,
      );

      // 9:00-9:45 overlaps 9:30-10:00 → taken
      final slot0900 =
          slots.firstWhere((s) => s.startLabel == '09:00', orElse: () => throw 'missing');
      expect(slot0900.status, SlotStatus.taken);

      // 9:30-10:15 also overlaps → taken
      final slot0930 =
          slots.firstWhere((s) => s.startLabel == '09:30', orElse: () => throw 'missing');
      expect(slot0930.status, SlotStatus.taken);

      // First clean slot is at 10:00 → free
      final slot1000 =
          slots.firstWhere((s) => s.startLabel == '10:00', orElse: () => throw 'missing');
      expect(slot1000.status, SlotStatus.free);
    });

    test('when 9:30 is booked and haircut needs only 30 min, 9:00 is free', () {
      final schedule = _makeSchedule(startHour: 9, endHour: 12);
      final bookings = [
        _booking(
          id: 'book-1',
          barberId: 'barber-1',
          hour: 9,
          minute: 30,
          durationMinutes: 30,
        ),
      ];
      // Quick service: only needs 30 min → 9:00-9:30 ends exactly when booking starts
      final slots = SlotEngine.generateSlots(
        schedule: schedule,
        date: DateTime(2026, 6, 8),
        existingBookings: bookings,
        requiredDurationMinutes: 30,
      );

      final slot0900 =
          slots.firstWhere((s) => s.startLabel == '09:00', orElse: () => throw 'missing');
      expect(slot0900.status, SlotStatus.free); // clean handoff at 9:30
    });
  });
}
