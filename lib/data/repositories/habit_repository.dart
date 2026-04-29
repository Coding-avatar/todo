import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/models.dart';
import '../local/local_storage_service.dart';

/// Repository for habit operations with hybrid local-cloud storage.
/// 
/// Strategy:
/// - Reads: Return local cache immediately, sync in background
/// - Writes: Write to local first (instant), push to cloud async
class HabitRepository {
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorage;

  HabitRepository({
    FirebaseFirestore? firestore,
    LocalStorageService? localStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage ?? LocalStorageService();

  /// Get habits collection for a user
  CollectionReference<Map<String, dynamic>> _habitsCollection(String userId) =>
      _firestore.collection('habits').doc(userId).collection('items');

  /// Get habit logs collection for a user
  CollectionReference<Map<String, dynamic>> _logsCollection(String userId) =>
      _firestore.collection('habitLogs').doc(userId).collection('logs');

  // ==================== HABITS ====================

  /// Stream all active habits for a user (local first)
  Stream<List<HabitModel>> watchHabits(String userId) async* {
    // Emit local data immediately
    yield _localStorage.getActiveHabits();
    
    // Listen to cloud changes
    yield* _habitsCollection(userId)
        .where('active', isEqualTo: true)
        .where('isFuture', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudHabits = snapshot.docs
              .map((doc) => HabitModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveHabits(cloudHabits);
          return _localStorage.getActiveHabits();
        });
  }

  /// Stream future/wishlist habits (local first)
  Stream<List<HabitModel>> watchFutureHabits(String userId) async* {
    yield _localStorage.getFutureHabits();
    
    yield* _habitsCollection(userId)
        .where('isFuture', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudHabits = snapshot.docs
              .map((doc) => HabitModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveHabits(cloudHabits);
          return _localStorage.getFutureHabits();
        });
  }

  /// Get single habit (from local cache)
  Future<HabitModel?> getHabit(String userId, String habitId) async {
    return _localStorage.getHabit(habitId);
  }

  /// Create new habit (save locally, push to cloud async)
  Future<void> createHabit(String userId, HabitModel habit) async {
    final habitToSave = habit.copyWith(
      syncStatus: 'pending',
      version: 0,
      updatedAt: DateTime.now(),
    );
    await _localStorage.saveHabit(habitToSave);
    
    _pushHabitToCloud(userId, habitToSave).ignore();
  }

  /// Update habit (save locally, push to cloud async)
  Future<void> updateHabit(String userId, HabitModel habit) async {
    final habitToSave = habit.copyWithSync(
      syncStatus: 'pending',
      deviceId: _localStorage.getDeviceId(),
    );
    await _localStorage.saveHabit(habitToSave);
    
    _pushHabitToCloud(userId, habitToSave).ignore();
  }

  /// Delete habit and its logs (remove locally, push async)
  Future<void> deleteHabit(String userId, String habitId) async {
    // Remove from local
    await _localStorage.deleteHabit(habitId);
    await _localStorage.deleteLogsForHabit(habitId);
    
    // Delete from cloud
    _deleteHabitFromCloud(userId, habitId).ignore();
  }

  /// Toggle habit active status (update locally, push async)
  Future<void> toggleHabitActive(
    String userId,
    String habitId,
    bool active,
  ) async {
    final habit = _localStorage.getHabit(habitId);
    if (habit != null) {
      final updated = habit.copyWithSync(
        active: active,
        isFuture: !active, // Move to wishlist when archived, and vice versa
        syncStatus: 'pending',
        deviceId: _localStorage.getDeviceId(),
      );
      await _localStorage.saveHabit(updated);
      
      _pushHabitToCloud(userId, updated).ignore();
    }
  }

  // ==================== HABIT LOGS ====================

  /// Stream logs for a specific habit (local first)
  Stream<List<HabitLogModel>> watchHabitLogs(
    String userId,
    String habitId,
  ) async* {
    final localLogs = _localStorage.getLogsForHabit(habitId);
    yield localLogs;
    
    yield* _logsCollection(userId)
        .where('habitId', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudLogs = snapshot.docs
              .map((doc) => HabitLogModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveLogs(cloudLogs);
          return _localStorage.getLogsForHabit(habitId);
        });
  }

  /// Stream all logs for a date range (local first, for analytics)
  Stream<List<HabitLogModel>> watchLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async* {
    final localLogs = _localStorage.getLogsInRange(startDate, endDate);
    yield localLogs;
    
    yield* _logsCollection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudLogs = snapshot.docs
              .map((doc) => HabitLogModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveLogs(cloudLogs);
          return _localStorage.getLogsInRange(startDate, endDate);
        });
  }

  /// Get log for a specific habit and date (from local cache)
  Future<HabitLogModel?> getLog(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final logs = _localStorage.getLogsForHabit(habitId);
    
    return logs.firstWhere(
      (log) => log.date.year == normalizedDate.year &&
          log.date.month == normalizedDate.month &&
          log.date.day == normalizedDate.day,
      orElse: () => HabitLogModel(
        id: 'temp',
        habitId: habitId,
        date: normalizedDate,
        completed: false,
        createdAt: DateTime.now(),
      ),
    ).id == 'temp'
        ? null
        : logs.firstWhere(
            (log) => log.date.year == normalizedDate.year &&
                log.date.month == normalizedDate.month &&
                log.date.day == normalizedDate.day,
          );
  }

  /// Create or update habit log (save locally, push async)
  Future<void> upsertLog(String userId, HabitLogModel log) async {
    final logToSave = log.copyWith(
      syncStatus: 'pending',
      version: log.version + 1,
    );
    await _localStorage.saveHabitLog(logToSave);
    
    _pushLogToCloud(userId, logToSave).ignore();
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
      syncStatus: 'pending',
      version: 0,
      deviceId: _localStorage.getDeviceId(),
    );
    await upsertLog(userId, log);
  }

  /// Calculate current streak for a habit (from local)
  Future<int> calculateStreak(String userId, String habitId) async {
    final today = DateTime.now();
    var streak = 0;
    var checkDate = DateTime(today.year, today.month, today.day);
    final logs = _localStorage.getLogsForHabit(habitId);

    while (true) {
      final log = logs.firstWhere(
        (l) => l.date.year == checkDate.year &&
            l.date.month == checkDate.month &&
            l.date.day == checkDate.day,
        orElse: () => HabitLogModel(
          id: 'temp',
          habitId: habitId,
          date: checkDate,
          completed: false,
          createdAt: DateTime.now(),
        ),
      );

      if (log.id == 'temp' || !log.completed) {
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

  /// Get completion stats for a habit (from local)
  Future<Map<String, int>> getCompletionStats(
    String userId,
    String habitId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final logs = _localStorage.getLogsInRange(startDate, endDate)
        .where((log) => log.habitId == habitId)
        .toList();
    
    final completed = logs.where((log) => log.completed).length;

    return {
      'total': days,
      'completed': completed,
      'missed': days - completed,
    };
  }

  // ============= PRIVATE HELPER METHODS =============

  /// Push a single habit to cloud
  Future<void> _pushHabitToCloud(String userId, HabitModel habit) async {
    try {
      await _habitsCollection(userId).doc(habit.id).set(
            habit.copyWith(syncStatus: 'synced').toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error pushing habit to cloud: $e');
    }
  }

  /// Delete a habit from cloud
  Future<void> _deleteHabitFromCloud(String userId, String habitId) async {
    try {
      // Delete all logs for this habit
      final logsSnapshot = await _logsCollection(userId)
          .where('habitId', isEqualTo: habitId)
          .get();
      for (final doc in logsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the habit
      await _habitsCollection(userId).doc(habitId).delete();
    } catch (e) {
      debugPrint('Error deleting habit from cloud: $e');
    }
  }

  /// Push a single log to cloud
  Future<void> _pushLogToCloud(String userId, HabitLogModel log) async {
    try {
      await _logsCollection(userId).doc(log.id).set(
            log.copyWith(syncStatus: 'synced').toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error pushing habit log to cloud: $e');
    }
  }

  /// Merge cloud habits with local, handling conflicts
  Future<void> _mergeAndSaveHabits(List<HabitModel> cloudHabits) async {
    final localHabits = _localStorage.getAllHabits();
    final merged = <String, HabitModel>{};

    for (final cloudHabit in cloudHabits) {
      final localHabit = localHabits.firstWhere(
        (h) => h.id == cloudHabit.id,
        orElse: () => cloudHabit,
      );

      if (localHabit.id == cloudHabit.id && localHabit != cloudHabit) {
        // Conflict: use last-write-wins
        if (localHabit.updatedAt.isAfter(cloudHabit.updatedAt)) {
          merged[cloudHabit.id] = localHabit;
        } else {
          merged[cloudHabit.id] = cloudHabit.copyWith(syncStatus: 'synced');
        }
      } else {
        merged[cloudHabit.id] = cloudHabit.copyWith(syncStatus: 'synced');
      }
    }

    // Keep local-only habits
    for (final localHabit in localHabits) {
      if (!merged.containsKey(localHabit.id)) {
        merged[localHabit.id] = localHabit;
      }
    }

    await _localStorage.saveMultipleHabits(merged.values.toList());
  }

  /// Merge cloud logs with local, handling conflicts
  Future<void> _mergeAndSaveLogs(List<HabitLogModel> cloudLogs) async {
    final localLogs = _localStorage.getAllHabitLogs();
    final merged = <String, HabitLogModel>{};

    for (final cloudLog in cloudLogs) {
      final localLog = localLogs.firstWhere(
        (l) => l.id == cloudLog.id,
        orElse: () => cloudLog,
      );

      if (localLog.id == cloudLog.id && localLog != cloudLog) {
        // Conflict: use last-write-wins based on createdAt
        if (localLog.createdAt.isAfter(cloudLog.createdAt)) {
          merged[cloudLog.id] = localLog;
        } else {
          merged[cloudLog.id] = cloudLog.copyWith(syncStatus: 'synced');
        }
      } else {
        merged[cloudLog.id] = cloudLog.copyWith(syncStatus: 'synced');
      }
    }

    // Keep local-only logs
    for (final localLog in localLogs) {
      if (!merged.containsKey(localLog.id)) {
        merged[localLog.id] = localLog;
      }
    }

    await _localStorage.saveMultipleHabitLogs(merged.values.toList());
  }
}
