import 'package:flutter/material.dart';

/// Schedule for a single day of the week.
class DaySchedule {
  final int weekday; // 1=Monday ... 7=Sunday
  final bool isWorking;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int slotIntervalMinutes; // e.g. 30

  const DaySchedule({
    required this.weekday,
    this.isWorking = true,
    required this.startTime,
    required this.endTime,
    this.slotIntervalMinutes = 30,
  });

  DaySchedule copyWith({
    int? weekday,
    bool? isWorking,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? slotIntervalMinutes,
  }) {
    return DaySchedule(
      weekday: weekday ?? this.weekday,
      isWorking: isWorking ?? this.isWorking,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotIntervalMinutes: slotIntervalMinutes ?? this.slotIntervalMinutes,
    );
  }

  String get weekdayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String get weekdayFull {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'isWorking': isWorking,
        'startTime': '${startTime.hour}:${startTime.minute}',
        'endTime': '${endTime.hour}:${endTime.minute}',
        'slotIntervalMinutes': slotIntervalMinutes,
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    final endParts = (json['endTime'] as String).split(':');
    return DaySchedule(
      weekday: json['weekday'] as int,
      isWorking: json['isWorking'] as bool? ?? true,
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      slotIntervalMinutes: json['slotIntervalMinutes'] as int? ?? 30,
    );
  }

  @override
  String toString() =>
      'DaySchedule(${weekdayFull}, ${isWorking ? "$startTime-$endTime" : "OFF"})';
}

/// A barber's full weekly schedule including days off.
class WorkSchedule {
  final List<DaySchedule> weeklySchedule; // one per day of week
  final List<DateTime> daysOff; // specific blocked dates

  const WorkSchedule({
    required this.weeklySchedule,
    this.daysOff = const [],
  });

  WorkSchedule copyWith({
    List<DaySchedule>? weeklySchedule,
    List<DateTime>? daysOff,
  }) {
    return WorkSchedule(
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      daysOff: daysOff ?? this.daysOff,
    );
  }

  /// Get the schedule for a specific weekday (1=Monday).
  DaySchedule? forWeekday(int weekday) {
    try {
      return weeklySchedule.firstWhere((d) => d.weekday == weekday);
    } catch (_) {
      return null;
    }
  }

  /// Check if a specific date is a day off.
  bool isDayOff(DateTime date) {
    return daysOff.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  Map<String, dynamic> toJson() => {
        'weeklySchedule': weeklySchedule.map((s) => s.toJson()).toList(),
        'daysOff':
            daysOff.map((d) => d.toIso8601String().split('T').first).toList(),
      };

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
        weeklySchedule: (json['weeklySchedule'] as List<dynamic>)
            .map((s) => DaySchedule.fromJson(s as Map<String, dynamic>))
            .toList(),
        daysOff: (json['daysOff'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            [],
      );

  @override
  String toString() => 'WorkSchedule(${weeklySchedule.length} days, ${daysOff.length} days off)';
}
