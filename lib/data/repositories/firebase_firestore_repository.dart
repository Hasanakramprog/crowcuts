import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'firestore_provider.dart';

/// Repository for all Firestore CRUD operations.
///
/// Collections:
/// - `barbers` — barber profiles and schedules
/// - `services` — global service catalog
/// - `bookings` — all bookings
/// - `ratings` — customer reviews
/// - `incomeRecords` — system-generated income history
class FirebaseFirestoreRepository {
  final _db = firestore;

  // ══════════════════════════════════════════════════════════════════════════
  // BARBERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream all barbers (reactive).
  Stream<List<BarberModel>> streamBarbers() {
    return _db.collection('barbers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BarberModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get a single barber by ID.
  Future<BarberModel?> getBarber(String id) async {
    final doc = await _db.collection('barbers').doc(id).get();
    if (!doc.exists) return null;
    return BarberModel.fromJson(doc.data()!);
  }

  /// Create or update a barber.
  Future<void> setBarber(BarberModel barber) async {
    await _db.collection('barbers').doc(barber.id).set(barber.toJson());
  }

  /// Patch only the avatarUrl field on a barber document.
  /// Uses merge:true so it works whether the document exists or not.
  Future<void> updateBarberAvatarUrl(String barberId, String avatarUrl) async {
    await _db
        .collection('barbers')
        .doc(barberId)
        .set({'avatarUrl': avatarUrl}, SetOptions(merge: true));
  }

  /// Update barber's isActive status.
  Future<void> toggleBarberActive(String barberId) async {
    final doc = await _db.collection('barbers').doc(barberId).get();
    if (!doc.exists) return;
    final current = doc.data()!['isActive'] as bool? ?? true;
    await _db.collection('barbers').doc(barberId).update({
      'isActive': !current,
    });
  }

  /// Update barber's schedule.
  Future<void> updateBarberSchedule(
      String barberId, WorkSchedule schedule) async {
    await _db
        .collection('barbers')
        .doc(barberId)
        .update({'schedule': schedule.toJson()});
  }

  /// Delete a barber.
  Future<void> deleteBarber(String barberId) async {
    await _db.collection('barbers').doc(barberId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICES
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream all services (reactive).
  Stream<List<ServiceModel>> streamServices() {
    return _db.collection('services').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get all services (one-shot).
  Future<List<ServiceModel>> getServices() async {
    final snapshot = await _db.collection('services').get();
    return snapshot.docs
        .map((doc) => ServiceModel.fromJson(doc.data()))
        .toList();
  }

  /// Create or update a service.
  Future<void> setService(ServiceModel service) async {
    await _db.collection('services').doc(service.id).set(service.toJson());
  }

  /// Toggle service active status.
  Future<void> toggleServiceActive(String serviceId) async {
    final doc = await _db.collection('services').doc(serviceId).get();
    if (!doc.exists) return;
    final current = doc.data()!['isActive'] as bool? ?? true;
    await _db.collection('services').doc(serviceId).update({
      'isActive': !current,
    });
  }

  /// Delete a service.
  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOOKINGS
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream all bookings (reactive).
  Stream<List<BookingModel>> streamAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream bookings for a specific barber on a specific date.
  Stream<List<BookingModel>> streamBookingsForBarberOnDate(
      String barberId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('bookings')
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream bookings for a customer (descending by date).
  Stream<List<BookingModel>> streamBookingsForCustomer(String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream bookings for a barber (all, descending by date).
  Stream<List<BookingModel>> streamBookingsForBarber(String barberId) {
    return _db
        .collection('bookings')
        .where('barberId', isEqualTo: barberId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get a single booking by ID.
  Future<BookingModel?> getBooking(String id) async {
    final doc = await _db.collection('bookings').doc(id).get();
    if (!doc.exists) return null;
    return BookingModel.fromJson(doc.data()!);
  }

  /// Create a new booking.
  Future<void> createBooking(BookingModel booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toJson());
  }

  /// Update booking status.
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.name,
    });
  }

  /// Cancel booking with optional reason.
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final update = <String, dynamic>{
      'status': BookingStatus.cancelled.name,
    };
    if (reason != null) update['cancellationReason'] = reason;
    await _db.collection('bookings').doc(bookingId).update(update);
  }

  /// Mark booking as rated.
  Future<void> markBookingAsRated(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'isRated': true,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RATINGS
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream ratings for a barber (newest first).
  Stream<List<RatingModel>> streamRatingsForBarber(String barberId) {
    return _db
        .collection('ratings')
        .where('barberId', isEqualTo: barberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RatingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream all ratings.
  Stream<List<RatingModel>> streamAllRatings() {
    return _db
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RatingModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Add a new rating.
  Future<void> addRating(RatingModel rating) async {
    await _db.collection('ratings').doc(rating.id).set(rating.toJson());
  }

  /// Compute average rating for a barber (one-shot).
  Future<double> getAverageRating(String barberId) async {
    final snapshot = await _db
        .collection('ratings')
        .where('barberId', isEqualTo: barberId)
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    final total = snapshot.docs.fold<double>(
        0, (sum, doc) => sum + (doc.data()['stars'] as num).toDouble());
    return total / snapshot.docs.length;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INCOME RECORDS
  // ══════════════════════════════════════════════════════════════════════════

  /// Stream all income records.
  Stream<List<IncomeRecord>> streamAllIncome() {
    return _db
        .collection('incomeRecords')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncomeRecord.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream income for a specific barber.
  Stream<List<IncomeRecord>> streamIncomeForBarber(String barberId) {
    return _db
        .collection('incomeRecords')
        .where('barberId', isEqualTo: barberId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IncomeRecord.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get income for a date range (one-shot).
  Future<List<IncomeRecord>> getIncomeForRange(
      DateTime start, DateTime end) async {
    final snapshot = await _db
        .collection('incomeRecords')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => IncomeRecord.fromJson(doc.data()))
        .toList();
  }

  /// Create an income record (when a booking is completed).
  Future<void> createIncomeRecord(IncomeRecord record) async {
    await _db
        .collection('incomeRecords')
        .doc(record.id)
        .set(record.toJson());
  }
}

/// Riverpod provider for [FirebaseFirestoreRepository].
final firebaseFirestoreRepositoryProvider =
    Provider<FirebaseFirestoreRepository>((ref) {
  return FirebaseFirestoreRepository();
});
