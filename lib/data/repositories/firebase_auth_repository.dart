import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'firestore_provider.dart';

/// Repository for Firebase Authentication + Firestore user sync.
///
/// Handles:
/// - Email/password sign-in/registration
/// - Reading/writing user profiles in Firestore 'users' collection
/// - Role-based user data (customer, barber, admin)
class FirebaseAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firestore = firestore;

  // ─────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Sign in with email and password.
  /// Returns [UserModel] on success, throws on failure.
  Future<UserModel> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;
    return _getOrCreateUser(uid, email);
  }

  /// Register a new user account.
  /// Creates both Firebase Auth user and Firestore profile document.
  Future<UserModel> registerWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      phone: phone,
      email: email,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());
    return user;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the currently signed-in user, or null.
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _getOrCreateUser(firebaseUser.uid, firebaseUser.email ?? '');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER PROFILE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch user from Firestore, or create one if missing.
  Future<UserModel> _getOrCreateUser(String uid, String email) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }

    // Create a minimal profile with 'customer' role by default
    final fallback = UserModel(
      id: uid,
      name: email.split('@').first,
      phone: '',
      email: email,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(fallback.toJson());
    return fallback;
  }

  /// Get a user by their ID (for role checks).
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  /// Update user profile data.
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  /// Find a user whose barberId matches the given barber ID.
  Future<UserModel?> getUserByBarberId(String barberId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('barberId', isEqualTo: barberId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromJson(snapshot.docs.first.data());
  }
}

/// Riverpod provider for [FirebaseAuthRepository].
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});
