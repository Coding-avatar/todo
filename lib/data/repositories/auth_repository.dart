import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Repository for Firebase Authentication operations.
class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  // ────────────────────── Email / Password ──────────────────────

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create new account with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ────────────────────── Google Sign-In ──────────────────────

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AccountConflictException(
          message: 'An account already exists with the same email but a different sign-in method.',
          email: e.email,
          pendingCredential: e.credential,
        );
      }
      throw _handleAuthException(e);
    }
  }

  // ────────────────────── Phone Sign-In ──────────────────────

  /// Initiate phone number verification (sends OTP)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String message) onError,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification on Android
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'account-exists-with-different-credential') {
          onError('An account already exists with a different sign-in method.');
        } else {
          onError(_handleAuthException(e).message);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-retrieval timed out — user can still enter OTP manually
      },
    );
  }

  /// Verify OTP and sign in
  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AccountConflictException(
          message: 'An account already exists with the same email but a different sign-in method.',
          email: e.email,
          pendingCredential: e.credential,
        );
      }
      throw _handleAuthException(e);
    }
  }

  // ────────────────────── Apple Sign-In ──────────────────────

  /// Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only provides name on first sign-in — persist it
      final displayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      if (displayName.isNotEmpty && userCredential.user?.displayName == null) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('Apple sign-in was cancelled.');
      }
      throw AuthException('Apple sign-in failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AccountConflictException(
          message: 'An account already exists with the same email but a different sign-in method.',
          email: e.email,
          pendingCredential: e.credential,
        );
      }
      throw _handleAuthException(e);
    }
  }

  // ────────────────────── Account Linking ──────────────────────

  /// Link a pending credential to the currently signed-in user
  Future<UserCredential> linkCredential(AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in.');
      }
      return await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ────────────────────── Common ──────────────────────

  /// Sign out (also clears Google sign-in session)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No account found with this email.');
      case 'wrong-password':
        return AuthException('Incorrect password.');
      case 'email-already-in-use':
        return AuthException('An account already exists with this email.');
      case 'weak-password':
        return AuthException('Password is too weak. Use at least 6 characters.');
      case 'invalid-email':
        return AuthException('Invalid email address.');
      case 'user-disabled':
        return AuthException('This account has been disabled.');
      case 'too-many-requests':
        return AuthException('Too many attempts. Please try again later.');
      case 'operation-not-allowed':
        return AuthException('This sign-in method is not enabled.');
      case 'requires-recent-login':
        return AuthException('Please sign in again to complete this action.');
      case 'invalid-verification-code':
        return AuthException('Invalid OTP. Please check and try again.');
      case 'session-expired':
        return AuthException('OTP has expired. Please request a new one.');
      case 'invalid-phone-number':
        return AuthException('Invalid phone number. Please check and try again.');
      default:
        return AuthException(e.message ?? 'An error occurred.');
    }
  }
}

/// Custom exception for auth errors with user-friendly messages
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

/// Exception for account-exists-with-different-credential conflicts
class AccountConflictException implements Exception {
  final String message;
  final String? email;
  final AuthCredential? pendingCredential;

  AccountConflictException({
    required this.message,
    this.email,
    this.pendingCredential,
  });

  @override
  String toString() => message;
}
