import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/repositories.dart';
import '../domain/models/models.dart';
import 'user_provider.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for current Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// Auth notifier for handling auth actions
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  // ────────────────────── Email / Password ──────────────────────

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          );
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    try {
      final credential = await ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          );

      // Create user profile in Firestore
      final user = UserModel.newUser(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
      );
      await ref.read(userRepositoryProvider).createUser(user);

      state = const AsyncData(null);
      return credential;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // ────────────────────── Google Sign-In ──────────────────────

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final credential = await ref.read(authRepositoryProvider).signInWithGoogle();
      await _ensureUserProfile(credential);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // ────────────────────── Phone Sign-In ──────────────────────

  /// Step 1: Send OTP to phone number
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String message) onError,
    int? forceResendingToken,
  }) async {
    await ref.read(authRepositoryProvider).verifyPhoneNumber(
          phoneNumber: phoneNumber,
          onCodeSent: onCodeSent,
          onAutoVerified: onAutoVerified,
          onError: onError,
          forceResendingToken: forceResendingToken,
        );
  }

  /// Step 2: Verify OTP and sign in
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String otp,
  }) async {
    state = const AsyncLoading();
    try {
      final credential = await ref.read(authRepositoryProvider).verifyPhoneOtp(
            verificationId: verificationId,
            otp: otp,
          );
      await _ensureUserProfile(credential);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Auto-verify (Android only) — called when the OTP is read automatically
  Future<void> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    state = const AsyncLoading();
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _ensureUserProfile(userCredential);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // ────────────────────── Apple Sign-In ──────────────────────

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    try {
      final credential = await ref.read(authRepositoryProvider).signInWithApple();
      await _ensureUserProfile(credential);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // ────────────────────── Account Linking ──────────────────────

  /// Link a pending credential to the current user after conflict resolution
  Future<void> linkPendingCredential(AuthCredential credential) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).linkCredential(credential);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // ────────────────────── Common ──────────────────────

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  // ────────────────────── Internal ──────────────────────

  /// Ensure a Firestore user profile exists for this credential.
  /// If no document exists yet (first social sign-in), create one.
  Future<void> _ensureUserProfile(UserCredential credential) async {
    final firebaseUser = credential.user;
    if (firebaseUser == null) return;

    final userRepo = ref.read(userRepositoryProvider);
    final existingUser = await userRepo.getUser(firebaseUser.uid);

    if (existingUser == null) {
      final newUser = UserModel.newUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? firebaseUser.phoneNumber ?? '',
        displayName: firebaseUser.displayName,
      );
      await userRepo.createUser(newUser);
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});
