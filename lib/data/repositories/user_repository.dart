import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/models.dart';
import '../../core/enums/enums.dart';

/// Repository for user profile operations in Firestore.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user document reference
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _usersCollection.doc(userId);

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    // Mock user support
    if (userId == 'mock-user-123') {
      return UserModel(
        id: 'mock-user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        level: UserLevel.intermediate, // Default to intermediate for testing features
        onboardingComplete: true,
      );
    }

    final doc = await _userDoc(userId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromJson(doc.data()!);
  }

  /// Stream user profile updates
  Stream<UserModel?> watchUser(String userId) {
    // Mock user support
    if (userId == 'mock-user-123') {
       return Stream.value(UserModel(
        id: 'mock-user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        level: UserLevel.intermediate,
        onboardingComplete: true,
      ));
    }

    return _userDoc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromJson(doc.data()!);
    });
  }

  /// Create new user profile
  Future<void> createUser(UserModel user) async {
    await _userDoc(user.id).set(user.toJson());
  }

  /// Update user profile
  Future<void> updateUser(UserModel user) async {
    await _userDoc(user.id).update(user.toJson());
  }

  /// Update specific user fields
  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    fields['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _userDoc(userId).update(fields);
  }

  /// Update user level
  Future<void> updateUserLevel(String userId, String level) async {
    await updateUserFields(userId, {'level': level});
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding(String userId) async {
    await updateUserFields(userId, {'onboardingComplete': true});
  }

  /// Delete user profile
  Future<void> deleteUser(String userId) async {
    // Delete user's todos
    final todosSnapshot = await _firestore
        .collection('todos')
        .doc(userId)
        .collection('items')
        .get();
    for (final doc in todosSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete user's habits
    final habitsSnapshot = await _firestore
        .collection('habits')
        .doc(userId)
        .collection('items')
        .get();
    for (final doc in habitsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete user's habit logs
    final logsSnapshot = await _firestore
        .collection('habitLogs')
        .doc(userId)
        .collection('logs')
        .get();
    for (final doc in logsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete user profile
    await _userDoc(userId).delete();
  }
}
