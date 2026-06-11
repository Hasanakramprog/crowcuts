import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../repositories/firebase_firestore_repository.dart';

/// All bookings state — synced from Firestore.
class BookingNotifier extends StateNotifier<List<BookingModel>> {
  final FirebaseFirestoreRepository _repo;

  BookingNotifier(this._repo) : super([]) {
    _repo.streamAllBookings().listen((bookings) {
      if (mounted) state = bookings;
    }).onError((_) {});
  }

  /// Get bookings for a specific customer.
  List<BookingModel> getBookingsForCustomer(String customerId) {
    return state
        .where((b) => b.customerId == customerId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get bookings for a specific barber on a specific date.
  List<BookingModel> getBookingsForBarberOnDate(
      String barberId, DateTime date) {
    return state
        .where((b) => b.barberId == barberId && _isSameDay(b.date, date))
        .toList();
  }

  /// Get all bookings for a barber (any date).
  List<BookingModel> getBookingsForBarber(String barberId) {
    return state.where((b) => b.barberId == barberId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all bookings (admin view).
  List<BookingModel> getAllBookings() {
    return state.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get a booking by ID.
  BookingModel? getBookingById(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the barber name for a booking.
  String getBarberNameForBooking(String barberId) {
    // This will be resolved from barbers provider in the UI
    return '';
  }

  /// Create a new booking.
  ///
  /// Optimistic update: adds the booking to local state immediately so the
  /// UI reflects it at once, without waiting for the Firestore stream
  /// round-trip. The stream will overwrite state with server truth shortly after.
  void addBooking(BookingModel booking) {
    state = [...state, booking];
    _repo.createBooking(booking);
  }

  /// Update booking status.
  void updateStatus(String bookingId, BookingStatus status) {
    _repo.updateBookingStatus(bookingId, status);
  }

  /// Cancel a booking.
  void cancelBooking(String bookingId, {String? reason}) {
    _repo.cancelBooking(bookingId, reason: reason);
  }

  /// Admin cancel a booking — requires a reason.
  void adminCancelBooking(String bookingId, String reason) {
    cancelBooking(bookingId, reason: reason);
  }

  /// Mark booking as rated.
  void markAsRated(String bookingId) {
    _repo.markBookingAsRated(bookingId);
  }

  /// Get upcoming bookings for a customer (pending + confirmed, future).
  List<BookingModel> getUpcomingForCustomer(String customerId) {
    final now = DateTime.now();
    return state.where((b) {
      if (b.customerId != customerId) return false;
      if (b.status != BookingStatus.pending &&
          b.status != BookingStatus.confirmed) return false;
      return b.date.isAfter(now) ||
          (_isSameDay(b.date, now) &&
              b.startTime.hour >= now.hour);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get completed bookings that are NOT yet rated.
  List<BookingModel> getUnratedCompletions(String customerId) {
    return state.where((b) {
      return b.customerId == customerId &&
          b.status == BookingStatus.completed &&
          !b.isRated;
    }).toList();
  }

  /// Get today's bookings for a barber.
  List<BookingModel> getTodayForBarber(String barberId) {
    final today = DateTime.now();
    return state.where((b) {
      return b.barberId == barberId && _isSameDay(b.date, today);
    }).toList()
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
  }
}

/// All bookings provider.
final bookingProvider =
    StateNotifierProvider<BookingNotifier, List<BookingModel>>((ref) {
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  return BookingNotifier(repo);
});

/// Helper for date comparison.
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
