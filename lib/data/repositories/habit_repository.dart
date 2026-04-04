import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/models.dart';

/// Repository for habit operations in Firestore.
class HabitRepository {
  final FirebaseFirestore _firestore;

  HabitRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get habits collection for a user
  CollectionReference<Map<String, dynamic>> _habitsCollection(String userId) =>
      _firestore.collection('habits').doc(userId).collection('items');

  /// Get habit logs collection for a user
  CollectionReference<Map<String, dynamic>> _logsCollection(String userId) =>
      _firestore.collection('habitLogs').doc(userId).collection('logs');

  // ==================== HABITS ====================

  /// Stream all active habits for a user
  Stream<List<HabitModel>> watchHabits(String userId) {
    return _habitsCollection(userId)
        .where('active', isEqualTo: true)
        .where('isFuture', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitModel.fromJson(doc.data())).toList());
  }

  /// Stream future/wishlist habits
  Stream<List<HabitModel>> watchFutureHabits(String userId) {
    return _habitsCollection(userId)
        .where('isFuture', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitModel.fromJson(doc.data())).toList());
  }

  /// Get single habit
  Future<HabitModel?> getHabit(String userId, String habitId) async {
    final doc = await _habitsCollection(userId).doc(habitId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return HabitModel.fromJson(doc.data()!);
  }

  /// Create new habit
  Future<void> createHabit(String userId, HabitModel habit) async {
    await _habitsCollection(userId).doc(habit.id).set(habit.toJson());
  }

  /// Update habit
  Future<void> updateHabit(String userId, HabitModel habit) async {
    await _habitsCollection(userId).doc(habit.id).update(habit.toJson());
  }

  /// Delete habit and its logs
  Future<void> deleteHabit(String userId, String habitId) async {
    // Delete all logs for this habit
    final logsSnapshot = await _logsCollection(userId)
        .where('habitId', isEqualTo: habitId)
        .get();
    for (final doc in logsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the habit
    await _habitsCollection(userId).doc(habitId).delete();
  }

  /// Toggle habit active status
  Future<void> toggleHabitActive(
    String userId,
    String habitId,
    bool active,
  ) async {
    await _habitsCollection(userId).doc(habitId).update({
      'active': active,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==================== HABIT LOGS ====================

  /// Stream logs for a specific habit
  Stream<List<HabitLogModel>> watchHabitLogs(
    String userId,
    String habitId,
  ) {
    return _logsCollection(userId)
        .where('habitId', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitLogModel.fromJson(doc.data())).toList());
  }

  /// Stream all logs for a date range (for analytics)
  Stream<List<HabitLogModel>> watchLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _logsCollection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitLogModel.fromJson(doc.data())).toList());
  }

  /// Get log for a specific habit and date
  Future<HabitLogModel?> getLog(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final nextDay = normalizedDate.add(const Duration(days: 1));

    final snapshot = await _logsCollection(userId)
        .where('habitId', isEqualTo: habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedDate))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }
    return HabitLogModel.fromJson(snapshot.docs.first.data());
  }

  /// Create or update habit log
  Future<void> upsertLog(String userId, HabitLogModel log) async {
    await _logsCollection(userId).doc(log.id).set(log.toJson());
  }

  /// Toggle completion for a habit on a specific date
  Future<void> toggleCompletion(
    String userId,
    String habitId,
    DateTime date,
    bool completed,
    String logId,
  ) async {
    final log = HabitLogModel(
      id: logId,
      habitId: habitId,
      date: DateTime(date.year, date.month, date.day),
      completed: completed,
      createdAt: DateTime.now(),
    );
    await upsertLog(userId, log);
  }

  /// Calculate current streak for a habit
  Future<int> calculateStreak(String userId, String habitId) async {
    final today = DateTime.now();
    var streak = 0;
    var checkDate = DateTime(today.year, today.month, today.day);

    while (true) {
      final log = await getLog(userId, habitId, checkDate);
      if (log == null || !log.completed) {
        // If today isn't completed yet, check from yesterday
        if (streak == 0 && checkDate == DateTime(today.year, today.month, today.day)) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Get completion stats for a habit
  Future<Map<String, int>> getCompletionStats(
    String userId,
    String habitId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _logsCollection(userId)
        .where('habitId', isEqualTo: habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final logs = snapshot.docs.map((doc) => HabitLogModel.fromJson(doc.data())).toList();
    final completed = logs.where((log) => log.completed).length;

    return {
      'total': days,
      'completed': completed,
      'missed': days - completed,
    };
  }
}
