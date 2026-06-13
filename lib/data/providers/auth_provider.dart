import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import '../models/user_model.dart';
import '../repositories/firebase_auth_repository.dart';

/// Current authenticated user state.
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Auth notifier — connects to Firebase Auth + Firestore user profiles.
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthRepository _authRepo;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthNotifier(this._authRepo) : super(const AuthState(isLoading: true)) {
    // Listen to Firebase auth state changes.
    // Starts with isLoading: true so the splash screen waits for this
    // to complete before deciding where to navigate — prevents login flash.
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      try {
        if (firebaseUser != null) {
          final user = await _authRepo.getCurrentUser();
          if (mounted) {
            state = state.copyWith(user: user, isLoading: false);
          }
        } else {
          // No session — user needs to log in
          if (mounted) state = const AuthState(isLoading: false);
        }
      } catch (_) {
        if (mounted) state = const AuthState(isLoading: false);
      }
    });
  }

  /// Initialize — check if user is already signed in.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authRepo.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Login with email and password.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepo.signInWithEmail(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _mapAuthError(e),
        isLoading: false,
      );
      return false;
    }
  }

  /// Register a new customer account.
  Future<bool> register(
      String name, String phone, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepo.registerWithEmail(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _mapAuthError(e),
        isLoading: false,
      );
      return false;
    }
  }

  /// Logout.
  void logout() {
    _authRepo.signOut();
    state = const AuthState();
  }

  /// Get the current user's role.
  UserRole? get role => state.user?.role;

  /// Switch role (kept for demo/development purposes).
  void switchRole(UserRole targetRole) {
    // In Firebase mode, role switching is done via the database.
    // This is a no-op for production — kept for backward compatibility.
  }

  /// Map Firebase auth exceptions to user-friendly messages.
  String _mapAuthError(Object error) {
    final message = error.toString();
    if (message.contains('user-not-found') || message.contains('wrong-password')) {
      return 'Invalid email or password';
    }
    if (message.contains('email-already-in-use')) {
      return 'An account with this email already exists';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    if (message.contains('network-request-failed')) {
      return 'Network error. Please check your connection';
    }
    return 'Authentication failed. Please try again';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return AuthNotifier(repo);
});
