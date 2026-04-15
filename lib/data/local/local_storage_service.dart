import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/models.dart';

/// Service for managing local data storage using Hive
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._();

  late Box<TodoModel> _todosBox;
  late Box<HabitModel> _habitsBox;
  late Box<HabitLogModel> _habitLogsBox;
  late Box<String> _syncMetadataBox;

  factory LocalStorageService() => _instance;

  LocalStorageService._();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    // We use openBox here instead of Hive.box because 
    // the service needs to ensure they are ready.
    
    _todosBox = await _openSafeBox<TodoModel>('todos');
    _habitsBox = await _openSafeBox<HabitModel>('habits');
    _habitLogsBox = await _openSafeBox<HabitLogModel>('habitLogs');
    _syncMetadataBox = await _openSafeBox<String>('syncMetadata');
  }

  /// Helper to open boxes safely without "Already Open" errors
  Future<Box<T>> _openSafeBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return await Hive.openBox<T>(name);
  }

  // ============= TODOS =============

  /// Save a single todo
  Future<void> saveTodo(TodoModel todo) async {
    await _todosBox.put(todo.id, todo);
  }

  /// Save multiple todos
  Future<void> saveMultipleTodos(List<TodoModel> todos) async {
    await _todosBox.putAll({for (var t in todos) t.id: t});
  }

  /// Get a single todo by ID
  TodoModel? getTodo(String id) {
    return _todosBox.get(id);
  }

  /// Get all todos
  List<TodoModel> getAllTodos() {
    return _todosBox.values.toList();
  }

  /// Stream todos (for reactive updates)
  Stream<List<TodoModel>> watchTodos() async* {
    yield getAllTodos();
    yield* _todosBox.watch().map((_) => getAllTodos());
  }

  /// Get todos with specific status
  List<TodoModel> getTodosByStatus(String status) {
    return _todosBox.values
        .where((todo) => todo.status.name == status)
        .toList();
  }

  /// Get pending sync todos
  List<TodoModel> getPendingSyncTodos() {
    return _todosBox.values
        .where((todo) => todo.syncStatus == 'pending')
        .toList();
  }

  /// Delete a todo
  Future<void> deleteTodo(String id) async {
    await _todosBox.delete(id);
  }

  /// Delete all todos
  Future<void> deleteAllTodos() async {
    await _todosBox.clear();
  }

  // ============= HABITS =============

  /// Save a single habit
  Future<void> saveHabit(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  /// Save multiple habits
  Future<void> saveMultipleHabits(List<HabitModel> habits) async {
    await _habitsBox.putAll({for (var h in habits) h.id: h});
  }

  /// Get a single habit by ID
  HabitModel? getHabit(String id) {
    return _habitsBox.get(id);
  }

  /// Get all habits
  List<HabitModel> getAllHabits() {
    return _habitsBox.values.toList();
  }

  /// Stream habits (for reactive updates)
  Stream<List<HabitModel>> watchHabits() async* {
    yield getAllHabits();
    yield* _habitsBox.watch().map((_) => getAllHabits());
  }

  /// Get active habits only
  List<HabitModel> getActiveHabits() {
    return _habitsBox.values.where((habit) => habit.active).toList();
  }

  /// Get future/wishlist habits
  List<HabitModel> getFutureHabits() {
    return _habitsBox.values.where((habit) => habit.isFuture).toList();
  }

  /// Get pending sync habits
  List<HabitModel> getPendingSyncHabits() {
    return _habitsBox.values
        .where((habit) => habit.syncStatus == 'pending')
        .toList();
  }

  /// Delete a habit
  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
  }

  /// Delete all habits
  Future<void> deleteAllHabits() async {
    await _habitsBox.clear();
  }

  // ============= HABIT LOGS =============

  /// Save a single habit log
  Future<void> saveHabitLog(HabitLogModel log) async {
    await _habitLogsBox.put(log.id, log);
  }

  /// Save multiple habit logs
  Future<void> saveMultipleHabitLogs(List<HabitLogModel> logs) async {
    await _habitLogsBox.putAll({for (var l in logs) l.id: l});
  }

  /// Get a single habit log by ID
  HabitLogModel? getHabitLog(String id) {
    return _habitLogsBox.get(id);
  }

  /// Get all habit logs
  List<HabitLogModel> getAllHabitLogs() {
    return _habitLogsBox.values.toList();
  }

  /// Stream habit logs (for reactive updates)
  Stream<List<HabitLogModel>> watchHabitLogs() async* {
    yield getAllHabitLogs();
    yield* _habitLogsBox.watch().map((_) => getAllHabitLogs());
  }

  /// Get logs for a specific habit
  List<HabitLogModel> getLogsForHabit(String habitId) {
    return _habitLogsBox.values
        .where((log) => log.habitId == habitId)
        .toList();
  }

  /// Get logs in date range
  List<HabitLogModel> getLogsInRange(DateTime start, DateTime end) {
    final startNormalized = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);
    return _habitLogsBox.values
        .where((log) =>
            log.normalizedDate.isAfter(startNormalized.subtract(Duration(days: 1))) &&
            log.normalizedDate.isBefore(endNormalized.add(Duration(days: 1))))
        .toList();
  }

  /// Get pending sync logs
  List<HabitLogModel> getPendingSyncLogs() {
    return _habitLogsBox.values
        .where((log) => log.syncStatus == 'pending')
        .toList();
  }

  /// Delete a habit log
  Future<void> deleteHabitLog(String id) async {
    await _habitLogsBox.delete(id);
  }

  /// Delete all habit logs for a habit
  Future<void> deleteLogsForHabit(String habitId) async {
    final logsToDelete = _habitLogsBox.values
        .where((log) => log.habitId == habitId)
        .map((log) => log.id)
        .toList();
    for (final id in logsToDelete) {
      await _habitLogsBox.delete(id);
    }
  }

  /// Delete all habit logs
  Future<void> deleteAllHabitLogs() async {
    await _habitLogsBox.clear();
  }

  // ============= SYNC METADATA =============

  /// Save sync metadata
  Future<void> saveSyncMetadata(String key, String value) async {
    await _syncMetadataBox.put(key, value);
  }

  /// Get sync metadata
  String? getSyncMetadata(String key) {
    return _syncMetadataBox.get(key);
  }

  /// Save last sync time
  Future<void> saveLastSyncTime(DateTime time) async {
    await _syncMetadataBox.put('lastSyncTime', time.toIso8601String());
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final timeStr = _syncMetadataBox.get('lastSyncTime');
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  /// Save device ID
  Future<void> saveDeviceId(String deviceId) async {
    await _syncMetadataBox.put('deviceId', deviceId);
  }

  /// Get device ID
  String? getDeviceId() {
    return _syncMetadataBox.get('deviceId');
  }

  // ============= DEBUGGING & MAINTENANCE =============

  /// Get sync status summary (for debugging)
  Map<String, dynamic> getSyncStatusSummary() {
    return {
      'totalTodos': _todosBox.length,
      'pendingTodos': getPendingSyncTodos().length,
      'totalHabits': _habitsBox.length,
      'pendingHabits': getPendingSyncHabits().length,
      'totalLogs': _habitLogsBox.length,
      'pendingLogs': getPendingSyncLogs().length,
      'lastSyncTime': getLastSyncTime()?.toIso8601String(),
      'deviceId': getDeviceId(),
    };
  }

  /// Clear all local data (use with caution!)
  Future<void> clearAllData() async {
    await Future.wait([
      _todosBox.clear(),
      _habitsBox.clear(),
      _habitLogsBox.clear(),
      _syncMetadataBox.clear(),
    ]);
  }
}
