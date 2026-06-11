import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/firebase_firestore_repository.dart';
import 'auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BARBER-SCOPED PROVIDERS — stream only the data a barber is allowed to see
// ═══════════════════════════════════════════════════════════════════════════════

/// Bookings for the currently signed-in barber.
final barberBookingsProvider =
    StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final user = ref.watch(authProvider).user;
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  final barberId = user?.barberId;
  if (barberId == null) return Stream.value([]);
  return repo.streamBookingsForBarber(barberId);
});

/// Income records for the currently signed-in barber.
final barberIncomeProvider =
    StreamProvider.autoDispose<List<IncomeRecord>>((ref) {
  final user = ref.watch(authProvider).user;
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  final barberId = user?.barberId;
  if (barberId == null) return Stream.value([]);
  return repo.streamIncomeForBarber(barberId);
});

/// Ratings for a specific barber.
final barberRatingsProvider =
    StreamProvider.family.autoDispose<List<RatingModel>, String>((ref, barberId) {
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  return repo.streamRatingsForBarber(barberId);
});
