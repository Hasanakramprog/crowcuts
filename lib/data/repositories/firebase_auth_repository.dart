import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, GoogleAuthProvider, EmailAuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_provider.dart';

/// Repository for Firebase Authentication + Firestore user sync.
///
/// Handles:
/// - Email/password sign-in/registration
/// - Google Sign-In for customers
/// - Reading/writing user profiles in Firestore 'users' collection
/// - Role-based user data (customer, barber, admin)
class FirebaseAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firestore = firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      authProvider: AuthProvider.email,
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());
    return user;
  }

  /// Sign in with Google for customers only.
  /// Returns [UserModel] with phone potentially null for new users.
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // Check if user document exists in Firestore
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        // Existing user - return from Firestore
        return UserModel.fromJson(doc.data()!);
      }

      // New Google user - create user document
      final newUser = UserModel(
        id: uid,
        name: userCredential.user!.displayName ?? googleUser.displayName ?? googleUser.email.split('@').first,
        phone: null, // Will be collected in phone input screen
        email: userCredential.user!.email ?? googleUser.email,
        role: UserRole.customer, // Google sign-in is customer-only
        createdAt: DateTime.now(),
        authProvider: AuthProvider.google,
        photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
      );

      await _firestore.collection('users').doc(uid).set(newUser.toJson());
      return newUser;
    } catch (e) {
      // Sign out on error to clean up state
      await _googleSignIn.signOut();
      await _auth.signOut();
      rethrow;
    }
  }

  /// Update user's phone number (used after Google sign-in).
  Future<void> updatePhoneNumber(String uid, String phone) async {
    await _firestore.collection('users').doc(uid).update({
      'phone': phone,
    });
  }

  /// Sign out the current user (both Firebase and Google).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
  /// For Google sign-in users, uses their Firebase Auth display data.
  Future<UserModel> _getOrCreateUser(String uid, String email) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }

    // Detect if this is a Google sign-in user via Firebase Auth provider data
    final firebaseUser = _auth.currentUser;
    final isGoogleUser = firebaseUser?.providerData
            .any((info) => info.providerId == 'google.com') ??
        false;

    // Create minimal profile — Google users get display name and photo
    final fallback = UserModel(
      id: uid,
      name: firebaseUser?.displayName ?? email.split('@').first,
      phone: null, // Google users collect phone separately
      email: email,
      role: UserRole.customer,
      createdAt: DateTime.now(),
      authProvider: isGoogleUser ? AuthProvider.google : AuthProvider.email,
      photoUrl: isGoogleUser ? firebaseUser?.photoURL : null,
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

  /// Create a barber user account (admin only).
  /// Returns the UserModel with the barberId set.
  /// This method creates both Firebase Auth user and Firestore profile document.
  Future<UserModel> createBarberUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String barberId,
  }) async {
    // Create Firebase Auth account
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;

    // Create user document with barber role
    final user = UserModel(
      id: uid,
      name: name,
      phone: phone,
      email: email,
      role: UserRole.barber,
      barberId: barberId,
      createdAt: DateTime.now(),
      authProvider: AuthProvider.email,
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());
    return user;
  }

  /// Update user's password (requires current password for security).
  /// Throws exception if current password is wrong or update fails.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user is currently signed in');
    }

    // Re-authenticate user before changing password (Firebase security requirement)
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
  }

  /// Update the current user's profile information (name, phone).
  /// Email updates require re-authentication and are not supported here.
  Future<void> updateCurrentUserProfile({
    String? name,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Get current user data
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    final currentUser = UserModel.fromJson(doc.data()!);
    
    // Update with new values
    final updatedUser = currentUser.copyWith(
      name: name ?? currentUser.name,
      phone: phone ?? currentUser.phone,
    );

    await _firestore.collection('users').doc(user.uid).update(updatedUser.toJson());
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
