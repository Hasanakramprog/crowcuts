import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income_record.dart';
import '../repositories/firebase_firestore_repository.dart';

/// Income record state — immutable, system-generated, from Firestore.
class IncomeNotifier extends StateNotifier<List<IncomeRecord>> {
  final FirebaseFirestoreRepository _repo;

  IncomeNotifier(this._repo) : super([]) {
    _repo.streamAllIncome().listen((records) {
      if (mounted) state = records;
    }).onError((_) {});
  }

  /// Get income for a specific barber.
  List<IncomeRecord> getIncomeForBarber(String barberId) {
    return state.where((r) => r.barberId == barberId).toList();
  }

  /// Get income for a date range.
  List<IncomeRecord> getIncomeForRange(DateTime start, DateTime end) {
    return state.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get income for today.
  List<IncomeRecord> getTodayIncome() {
    final today = DateTime.now();
    return getIncomeForRange(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day, 23, 59),
    );
  }

  /// Get income for this week.
  List<IncomeRecord> getThisWeekIncome() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return getIncomeForRange(
      DateTime(start.year, start.month, start.day),
      now,
    );
  }

  /// Get income for this month.
  List<IncomeRecord> getThisMonthIncome() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getIncomeForRange(start, now);
  }

  /// Get income for this year.
  List<IncomeRecord> getThisYearIncome() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return getIncomeForRange(start, now);
  }

  /// Calculate total from records.
  double calculateTotal(List<IncomeRecord> records) {
    return records.fold<double>(0, (sum, r) => sum + r.amount);
  }

  /// Group records by service name.
  Map<String, double> breakdownByService(List<IncomeRecord> records) {
    final map = <String, double>{};
    for (final record in records) {
      for (final name in record.serviceNames) {
        map[name] = (map[name] ?? 0) + (record.amount / record.serviceNames.length);
      }
    }
    return map;
  }

  /// Group records by barber.
  Map<String, double> breakdownByBarber(List<IncomeRecord> records) {
    final map = <String, double>{};
    for (final record in records) {
      map[record.barberName] =
          (map[record.barberName] ?? 0) + record.amount;
    }
    return map;
  }

  /// Create income record when a booking is completed.
  void createFromBooking({
    required String bookingId,
    required String barberId,
    required String barberName,
    required List<String> serviceIds,
    required List<String> serviceNames,
    required double amount,
    required DateTime date,
  }) {
    final record = IncomeRecord(
      id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      barberId: barberId,
      barberName: barberName,
      serviceIds: serviceIds,
      serviceNames: serviceNames,
      amount: amount,
      date: date,
    );
    _repo.createIncomeRecord(record);
  }
}

final incomeProvider =
    StateNotifierProvider<IncomeNotifier, List<IncomeRecord>>((ref) {
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  return IncomeNotifier(repo);
});
