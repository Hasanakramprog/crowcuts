import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/firebase_firestore_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICE CATALOG — Stream-based from Firestore
// ═══════════════════════════════════════════════════════════════════════════════

/// Service notifier — writes to Firestore, stays in sync via stream.
class ServiceNotifier extends StateNotifier<List<ServiceModel>> {
  final FirebaseFirestoreRepository _repo;

  ServiceNotifier(this._repo) : super([]) {
    // Subscribe to Firestore stream
    _repo.streamServices().listen((services) {
      if (mounted) state = services;
    }).onError((_) {});
  }

  void addService(String name) {
    final id = 'svc-${DateTime.now().millisecondsSinceEpoch}';
    final service = ServiceModel(id: id, name: name);
    _repo.setService(service);
  }

  void updateService(String id, String newName) {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _repo.setService(state[index].copyWith(name: newName));
  }

  void toggleService(String id) {
    _repo.toggleServiceActive(id);
  }
}

final serviceCatalogProvider =
    StateNotifierProvider<ServiceNotifier, List<ServiceModel>>((ref) {
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  return ServiceNotifier(repo);
});

// ═══════════════════════════════════════════════════════════════════════════════
// BARBERS — Stream-based from Firestore
// ═══════════════════════════════════════════════════════════════════════════════

class BarberNotifier extends StateNotifier<List<BarberModel>> {
  final FirebaseFirestoreRepository _repo;

  BarberNotifier(this._repo) : super([]) {
    _repo.streamBarbers().listen((barbers) {
      if (mounted) state = barbers;
    }).onError((_) {});
  }

  BarberModel? getById(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateBarber(BarberModel updated) async {
    await _repo.setBarber(updated);
  }

  Future<void> addBarber(BarberModel barber) async {
    await _repo.setBarber(barber);
  }

  void toggleActive(String id) {
    _repo.toggleBarberActive(id);
  }

  void updateSchedule(String barberId, WorkSchedule schedule) {
    _repo.updateBarberSchedule(barberId, schedule);
  }
}

final barbersProvider =
    StateNotifierProvider<BarberNotifier, List<BarberModel>>((ref) {
  final repo = ref.watch(firebaseFirestoreRepositoryProvider);
  return BarberNotifier(repo);
});

// ── Derived providers ─────────────────────────────────────────────────────────

final barberProvider = Provider.family<BarberModel?, String>((ref, barberId) {
  final barbers = ref.watch(barbersProvider);
  try {
    return barbers.firstWhere((b) => b.id == barberId);
  } catch (_) {
    return null;
  }
});

final activeBarbersProvider = Provider<List<BarberModel>>((ref) {
  return ref.watch(barbersProvider).where((b) => b.isActive).toList();
});

final barberServicesProvider =
    Provider.family<List<BarberService>, String>((ref, barberId) {
  final barber = ref.watch(barberProvider(barberId));
  return barber?.services ?? [];
});
