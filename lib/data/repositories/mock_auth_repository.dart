import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';

/// Mock user for testing without Firebase
class MockUser implements User {
  @override
  final String uid;
  
  @override
  final String? email;
  
  @override
  final String? displayName;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get photoURL => null;

  @override
  String? get phoneNumber => null;
  
  @override
  String? get tenantId => null;

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock-token';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }
  
  @override
  UserMetadata get metadata => throw UnimplementedError();
  
  @override
  String? get refreshToken => 'mock-refresh-token';
  
  @override
  Future<void> delete() async => debugPrint('MockUser: delete');
  
  @override
  Future<void> reload() async => debugPrint('MockUser: reload');
  
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    throw UnimplementedError();
  }
  
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async => throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) async => throw UnimplementedError();
    
  @override
    Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {
    debugPrint('MockUser: sendEmailVerification');
  }
  
  @override
  Future<void> updateDisplayName(String? displayName) async {
    debugPrint('MockUser: updateDisplayName $displayName');
  }

  @override
  Future<void> updateEmail(String email) async {
    debugPrint('MockUser: updateEmail $email');
  }
  
  @override
  Future<void> updatePassword(String newPassword) async {
     debugPrint('MockUser: updatePassword');
  }

  @override
  Future<void> updatePhotoURL(String? photoURL) async {
    debugPrint('MockUser: updatePhotoURL');
  }
  
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {
      debugPrint('MockUser: verifyBeforeUpdateEmail');
  }
  
  @override
  Future<User> unlink(String providerId) async {
     debugPrint('MockUser: unlink $providerId');
     return this;
  }
  
  // ignore: deprecated_member_use
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {
     debugPrint('MockUser: updatePhoneNumber');
  }
  
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
     debugPrint('MockUser: updateProfile');
  }

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async {
      throw UnimplementedError();
  }
  
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async {
     throw UnimplementedError();
  }
  
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? recaptchaVerifier]) {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmationResult> reauthenticateWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? recaptchaVerifier]) {
    throw UnimplementedError();
  }
  
  @override
  Future<void> verifyBeforeUpdatePassword(String newPassword, [ActionCodeSettings? actionCodeSettings]) {
    throw UnimplementedError();
  }
  
  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) {
    throw UnimplementedError();
  }
}

/// Mock Auth Repository to simulate logged-in user
class MockAuthRepository implements AuthRepository {
  final MockUser _mockUser = MockUser(
    uid: 'mock-user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  @override
  Stream<User?> get authStateChanges => Stream.value(_mockUser);

  @override
  User? get currentUser => _mockUser;

  @override
  Future<UserCredential> signInWithEmail({required String email, required String password}) async {
    debugPrint('MockAuth: signInWithEmail');
    throw UnimplementedError('Already logged in as mock user');
  }

  @override
  Future<UserCredential> signUpWithEmail({required String email, required String password, String? displayName}) async {
    debugPrint('MockAuth: signUpWithEmail');
    throw UnimplementedError('Already logged in as mock user');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('MockAuth: sendPasswordResetEmail to $email');
  }

  @override
  Future<void> signOut() async {
    debugPrint('MockAuth: signOut (simulated)');
    // In a real mock we might emit null, but for "Testing App" user wants to BE logged in.
    // If they sign out, they should probably stay logged in or we flip a switch?
    // For now, simple mock just stays logged in.
  }

  @override
  Future<void> deleteAccount() async {
    debugPrint('MockAuth: deleteAccount');
  }
}
