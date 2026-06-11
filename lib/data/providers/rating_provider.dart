import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_model.dart';
import '../repositories/firebase_firestore_repository.dart';

/// Rating state management — synced from Firestore.
class RatingNotifier extends StateNotifier<List<RatingModel>> {
  final FirebaseFirestoreRepository _repo;

  RatingNotifier(this._repo) : super([]) {
    _repo.streamAllRatings().listen((ratings) {
      if (mounted) state = ratings;
    }).onError((_) {});
  }

  /// Get ratings for a specific barber.
  List<RatingModel> getRatingsForBarber(String barberId) {
    return state.where((r) => r.barberId == barberId).toList();
  }

  /// Add a new rating.
  void addRating(RatingModel rating) {
    _repo.addRating(rating);
  }

  /// Get the average rating for a barber.
  double getAverageRating(String barberId) {
    final barberRatings = getRatingsForBarber(barberId);
    if (barberRatings.isEmpty) return 0.0;
    final total = barberRatings.fold<double>(0, (sum, r) => sum + r.stars);
    return total / barberRatings.length;
  }
}

final ratingProvider =
    StateNotifierProvider<RatingNotifier, List<RatingModel>>((ref) {
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  return RatingNotifier(repo);
});
