import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/models.dart';
import '../local/local_storage_service.dart';
import 'conflict_resolver.dart';

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? errorMessage;
  final int itemsSynced;
  final int conflicts;

  SyncResult({
    required this.success,
    this.errorMessage,
    this.itemsSynced = 0,
    this.conflicts = 0,
  });

  factory SyncResult.success({int itemsSynced = 0, int conflicts = 0}) =>
      SyncResult(success: true, itemsSynced: itemsSynced, conflicts: conflicts);

  factory SyncResult.failure(String error) =>
      SyncResult(success: false, errorMessage: error);
}

/// Core sync engine for handling bidirectional sync between local and cloud
class SyncEngine {
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorage;
  final String _userId;
  final String _deviceId; // ignore: unused_field - Used for tracking which device made changes

  SyncEngine({
    FirebaseFirestore? firestore,
    required LocalStorageService localStorage,
    required String userId,
    required String deviceId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage,
        _userId = userId,
        _deviceId = deviceId;

  /// Main sync method - syncs todos, habits, and logs
  Future<SyncResult> syncAll() async {
    try {
      debugPrint('[SyncEngine] Starting full sync for user: $_userId');
      
      final todoResult = await syncTodos();
      final habitResult = await syncHabits();
      final logResult = await syncHabitLogs();

      final totalSynced = todoResult.itemsSynced + habitResult.itemsSynced + logResult.itemsSynced;
      final totalConflicts = todoResult.conflicts + habitResult.conflicts + logResult.conflicts;

      debugPrint('[SyncEngine] Sync complete. Synced: $totalSynced, Conflicts: $totalConflicts');
      
      // Update last sync time
      await _localStorage.saveLastSyncTime(DateTime.now());

      return SyncResult.success(itemsSynced: totalSynced, conflicts: totalConflicts);
    } catch (e) {
      debugPrint('[SyncEngine] Sync error: $e');
      return SyncResult.failure(e.toString());
    }
  }

  /// Sync todos with Firestore
  Future<SyncResult> syncTodos() async {
    try {
      debugPrint('[SyncEngine] Syncing todos...');
      
      // 1. Get pending local todos
      final pendingLocalTodos = _localStorage.getPendingSyncTodos();
      debugPrint('[SyncEngine] Found ${pendingLocalTodos.length} pending todos');

      // 2. Push pending changes to Cloud
      for (final todo in pendingLocalTodos) {
        try {
          await _pushTodoToCloud(todo);
        } catch (e) {
          debugPrint('[SyncEngine] Failed to push todo ${todo.id}: $e');
        }
      }

      // 3. Pull all todos from Cloud
      final cloudTodos = await _pullTodosFromCloud();
      debugPrint('[SyncEngine] Pulled ${cloudTodos.length} todos from cloud');

      // 4. Merge conflicts with local todos
      final allLocalTodos = _localStorage.getAllTodos();
      final mergedTodos = _mergeTodos(allLocalTodos, cloudTodos);

      // 5. Update local DB with merged results
      await _localStorage.saveMultipleTodos(mergedTodos);

      final conflicts = mergedTodos.where((t) => t.syncStatus == 'conflict').length;
      return SyncResult.success(itemsSynced: mergedTodos.length, conflicts: conflicts);
    } catch (e) {
      return SyncResult.failure('Failed to sync todos: $e');
    }
  }

  /// Sync habits with Firestore
  Future<SyncResult> syncHabits() async {
    try {
      debugPrint('[SyncEngine] Syncing habits...');
      
      final pendingLocalHabits = _localStorage.getPendingSyncHabits();
      debugPrint('[SyncEngine] Found ${pendingLocalHabits.length} pending habits');

      for (final habit in pendingLocalHabits) {
        try {
          await _pushHabitToCloud(habit);
        } catch (e) {
          debugPrint('[SyncEngine] Failed to push habit ${habit.id}: $e');
        }
      }

      final cloudHabits = await _pullHabitsFromCloud();
      debugPrint('[SyncEngine] Pulled ${cloudHabits.length} habits from cloud');

      final allLocalHabits = _localStorage.getAllHabits();
      final mergedHabits = _mergeHabits(allLocalHabits, cloudHabits);

      await _localStorage.saveMultipleHabits(mergedHabits);

      final conflicts = mergedHabits.where((h) => h.syncStatus == 'conflict').length;
      return SyncResult.success(itemsSynced: mergedHabits.length, conflicts: conflicts);
    } catch (e) {
      return SyncResult.failure('Failed to sync habits: $e');
    }
  }

  /// Sync habit logs with Firestore
  Future<SyncResult> syncHabitLogs() async {
    try {
      debugPrint('[SyncEngine] Syncing habit logs...');
      
      final pendingLocalLogs = _localStorage.getPendingSyncLogs();
      debugPrint('[SyncEngine] Found ${pendingLocalLogs.length} pending logs');

      for (final log in pendingLocalLogs) {
        try {
          await _pushHabitLogToCloud(log);
        } catch (e) {
          debugPrint('[SyncEngine] Failed to push log ${log.id}: $e');
        }
      }

      final cloudLogs = await _pullHabitLogsFromCloud();
      debugPrint('[SyncEngine] Pulled ${cloudLogs.length} logs from cloud');

      final allLocalLogs = _localStorage.getAllHabitLogs();
      final mergedLogs = _mergeLogs(allLocalLogs, cloudLogs);

      await _localStorage.saveMultipleHabitLogs(mergedLogs);

      final conflicts = mergedLogs.where((l) => l.syncStatus == 'conflict').length;
      return SyncResult.success(itemsSynced: mergedLogs.length, conflicts: conflicts);
    } catch (e) {
      return SyncResult.failure('Failed to sync habit logs: $e');
    }
  }

  // ============= PUSH OPERATIONS =============

  Future<void> _pushTodoToCloud(TodoModel todo) async {
    final docRef = _firestore.collection('todos').doc(_userId).collection('items').doc(todo.id);
    await docRef.set(todo.toJson(), SetOptions(merge: true));
  }

  Future<void> _pushHabitToCloud(HabitModel habit) async {
    final docRef = _firestore.collection('habits').doc(_userId).collection('items').doc(habit.id);
    await docRef.set(habit.toJson(), SetOptions(merge: true));
  }

  Future<void> _pushHabitLogToCloud(HabitLogModel log) async {
    final docRef = _firestore.collection('habitLogs').doc(_userId).collection('logs').doc(log.id);
    await docRef.set(log.toJson(), SetOptions(merge: true));
  }

  // ============= PULL OPERATIONS =============

  Future<List<TodoModel>> _pullTodosFromCloud() async {
    try {
      final snapshot = await _firestore
          .collection('todos')
          .doc(_userId)
          .collection('items')
          .get();
      
      return snapshot.docs
          .map((doc) => TodoModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[SyncEngine] Error pulling todos from cloud: $e');
      return [];
    }
  }

  Future<List<HabitModel>> _pullHabitsFromCloud() async {
    try {
      final snapshot = await _firestore
          .collection('habits')
          .doc(_userId)
          .collection('items')
          .get();
      
      return snapshot.docs
          .map((doc) => HabitModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[SyncEngine] Error pulling habits from cloud: $e');
      return [];
    }
  }

  Future<List<HabitLogModel>> _pullHabitLogsFromCloud() async {
    try {
      final snapshot = await _firestore
          .collection('habitLogs')
          .doc(_userId)
          .collection('logs')
          .get();
      
      return snapshot.docs
          .map((doc) => HabitLogModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[SyncEngine] Error pulling habit logs from cloud: $e');
      return [];
    }
  }

  // ============= MERGE OPERATIONS =============

  List<TodoModel> _mergeTodos(List<TodoModel> local, List<TodoModel> cloud) {
    final cloudMap = {for (var t in cloud) t.id: t};
    final mergedMap = <String, TodoModel>{};

    // Merge cloud todos
    for (final cloudTodo in cloud) {
      final localTodo = local.firstWhere(
        (t) => t.id == cloudTodo.id,
        orElse: () => cloudTodo,
      );

      if (localTodo.id == cloudTodo.id && localTodo != cloudTodo) {
        // Conflict detected - resolve using last-write-wins
        mergedMap[cloudTodo.id] = ConflictResolver.resolveTodoLastWriteWins(localTodo, cloudTodo);
      } else {
        mergedMap[cloudTodo.id] = cloudTodo.copyWith(syncStatus: 'synced');
      }
    }

    // Add local-only todos (not in cloud)
    for (final localTodo in local) {
      if (!cloudMap.containsKey(localTodo.id)) {
        mergedMap[localTodo.id] = localTodo.copyWith(syncStatus: 'pending');
      }
    }

    return mergedMap.values.toList();
  }

  List<HabitModel> _mergeHabits(List<HabitModel> local, List<HabitModel> cloud) {
    final cloudMap = {for (var h in cloud) h.id: h};
    final mergedMap = <String, HabitModel>{};

    for (final cloudHabit in cloud) {
      final localHabit = local.firstWhere(
        (h) => h.id == cloudHabit.id,
        orElse: () => cloudHabit,
      );

      if (localHabit.id == cloudHabit.id && localHabit != cloudHabit) {
        mergedMap[cloudHabit.id] = ConflictResolver.resolveHabitLastWriteWins(localHabit, cloudHabit);
      } else {
        mergedMap[cloudHabit.id] = cloudHabit.copyWith(syncStatus: 'synced');
      }
    }

    for (final localHabit in local) {
      if (!cloudMap.containsKey(localHabit.id)) {
        mergedMap[localHabit.id] = localHabit.copyWith(syncStatus: 'pending');
      }
    }

    return mergedMap.values.toList();
  }

  List<HabitLogModel> _mergeLogs(List<HabitLogModel> local, List<HabitLogModel> cloud) {
    final cloudMap = {for (var l in cloud) l.id: l};
    final mergedMap = <String, HabitLogModel>{};

    for (final cloudLog in cloud) {
      final localLog = local.firstWhere(
        (l) => l.id == cloudLog.id,
        orElse: () => cloudLog,
      );

      if (localLog.id == cloudLog.id && localLog != cloudLog) {
        mergedMap[cloudLog.id] = ConflictResolver.resolveLogLastWriteWins(localLog, cloudLog);
      } else {
        mergedMap[cloudLog.id] = cloudLog.copyWith(syncStatus: 'synced');
      }
    }

    for (final localLog in local) {
      if (!cloudMap.containsKey(localLog.id)) {
        mergedMap[localLog.id] = localLog.copyWith(syncStatus: 'pending');
      }
    }

    return mergedMap.values.toList();
  }
}
