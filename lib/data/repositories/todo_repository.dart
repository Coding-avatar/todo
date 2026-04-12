import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/enums/enums.dart';
import '../../domain/models/models.dart';
import '../local/local_storage_service.dart';

/// Repository for todo operations with hybrid local-cloud storage.
/// 
/// Strategy:
/// - Reads: Return local cache immediately, sync in background
/// - Writes: Write to local first (instant), push to cloud async
/// - Conflicts: Use last-write-wins based on timestamps
class TodoRepository {
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorage;

  TodoRepository({
    FirebaseFirestore? firestore,
    LocalStorageService? localStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage ?? LocalStorageService();

  /// Get todos collection for a user
  CollectionReference<Map<String, dynamic>> _todosCollection(String userId) =>
      _firestore.collection('todos').doc(userId).collection('items');

  /// Stream all todos for a user (local first, syncs in background)
  Stream<List<TodoModel>> watchTodos(String userId) async* {
    // Emit local data immediately
    yield _localStorage.getAllTodos();
    
    // Listen to cloud changes and sync
    yield* _todosCollection(userId)
        .orderBy('priority')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudTodos = snapshot.docs
              .map((doc) => TodoModel.fromJson(doc.data()))
              .toList();
          
          // Merge with local and save
          await _mergeAndSaveTodos(cloudTodos);
          return _localStorage.getAllTodos();
        });
  }

  /// Stream pending todos for a user (local first)
  Stream<List<TodoModel>> watchPendingTodos(String userId) async* {
    // Emit local pending todos immediately
    yield _localStorage.getTodosByStatus('pending');
    
    // Listen to cloud changes
    yield* _todosCollection(userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('priority')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudTodos = snapshot.docs
              .map((doc) => TodoModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveTodos(cloudTodos);
          return _localStorage.getTodosByStatus('pending');
        });
  }

  /// Stream todos due today (local first)
  Stream<List<TodoModel>> watchTodayTodos(String userId) async* {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Filter local todos
    final localTodos = _localStorage.getAllTodos().where((todo) {
      if (todo.dueDate == null || todo.status.name != 'pending') return false;
      return todo.dueDate!.isAfter(startOfDay) && todo.dueDate!.isBefore(endOfDay);
    }).toList();
    
    yield localTodos;
    
    // Listen to cloud
    yield* _todosCollection(userId)
        .where('status', isEqualTo: 'pending')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudTodos = snapshot.docs
              .map((doc) => TodoModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveTodos(cloudTodos);
          
          // Re-filter after merge
          return _localStorage.getAllTodos().where((todo) {
            if (todo.dueDate == null || todo.status.name != 'pending') return false;
            return todo.dueDate!.isAfter(startOfDay) && todo.dueDate!.isBefore(endOfDay);
          }).toList();
        });
  }

  /// Get todos by category (local first)
  Stream<List<TodoModel>> watchTodosByCategory(
    String userId,
    String categoryId,
  ) async* {
    final localTodos = _localStorage.getAllTodos().where((todo) {
      return todo.categoryId == categoryId && todo.status.name == 'pending';
    }).toList();
    
    yield localTodos;
    
    yield* _todosCollection(userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'pending')
        .orderBy('priority')
        .snapshots()
        .asyncMap((snapshot) async {
          final cloudTodos = snapshot.docs
              .map((doc) => TodoModel.fromJson(doc.data()))
              .toList();
          
          await _mergeAndSaveTodos(cloudTodos);
          
          return _localStorage.getAllTodos().where((todo) {
            return todo.categoryId == categoryId && todo.status.name == 'pending';
          }).toList();
        });
  }

  /// Get single todo (from local cache)
  Future<TodoModel?> getTodo(String userId, String todoId) async {
    return _localStorage.getTodo(todoId);
  }

  /// Create new todo (save locally, push to cloud async)
  Future<void> createTodo(String userId, TodoModel todo) async {
    // Save to local immediately
    final todoToSave = todo.copyWith(
      syncStatus: 'pending',
      version: 0,
      updatedAt: DateTime.now(),
    );
    await _localStorage.saveTodo(todoToSave);
    
    // Push to cloud asynchronously
    _pushTodoToCloud(userId, todoToSave).ignore();
  }

  /// Update todo (save locally, push to cloud async)
  Future<void> updateTodo(String userId, TodoModel todo) async {
    // Update locally with sync metadata
    final todoToSave = todo.copyWithSync(
      syncStatus: 'pending',
      deviceId: _localStorage.getDeviceId(),
    );
    await _localStorage.saveTodo(todoToSave);
    
    // Push to cloud asynchronously
    _pushTodoToCloud(userId, todoToSave).ignore();
  }

  /// Delete todo (remove locally, push to cloud async)
  Future<void> deleteTodo(String userId, String todoId) async {
    // Remove from local
    await _localStorage.deleteTodo(todoId);
    
    // Delete from cloud
    _deleteTodoFromCloud(userId, todoId).ignore();
  }

  /// Mark todo as completed (update locally, push async)
  Future<void> completeTodo(String userId, String todoId) async {
    final todo = _localStorage.getTodo(todoId);
    if (todo != null) {
      final updated = todo.copyWithSync(
        status: TodoStatus.completed,
        syncStatus: 'pending',
        deviceId: _localStorage.getDeviceId(),
      );
      await _localStorage.saveTodo(updated);
      
      // Push to cloud
      _pushTodoToCloud(userId, updated).ignore();
    }
  }

  /// Mark todo as dismissed (update locally, push async)
  Future<void> dismissTodo(String userId, String todoId) async {
    final todo = _localStorage.getTodo(todoId);
    if (todo != null) {
      final updated = todo.copyWithSync(
        status: TodoStatus.dismissed,
        syncStatus: 'pending',
        deviceId: _localStorage.getDeviceId(),
      );
      await _localStorage.saveTodo(updated);
      
      // Push to cloud
      _pushTodoToCloud(userId, updated).ignore();
    }
  }

  /// Reorder todos (update locally, batch push async)
  Future<void> reorderTodos(
    String userId,
    List<String> todoIds,
  ) async {
    // Update locally
    for (var i = 0; i < todoIds.length; i++) {
      final todo = _localStorage.getTodo(todoIds[i]);
      if (todo != null) {
        final updated = todo.copyWith(
          priority: i + 1,
          version: todo.version + 1,
          syncStatus: 'pending',
          updatedAt: DateTime.now(),
        );
        await _localStorage.saveTodo(updated);
      }
    }
    
    // Batch push to cloud
    _batchUpdateTodos(userId, todoIds).ignore();
  }

  // ============= PRIVATE HELPER METHODS =============

  /// Push a single todo to cloud
  Future<void> _pushTodoToCloud(String userId, TodoModel todo) async {
    try {
      await _todosCollection(userId).doc(todo.id).set(
            todo.copyWith(syncStatus: 'synced').toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error pushing todo to cloud: $e');
    }
  }

  /// Delete a todo from cloud
  Future<void> _deleteTodoFromCloud(String userId, String todoId) async {
    try {
      await _todosCollection(userId).doc(todoId).delete();
    } catch (e) {
      debugPrint('Error deleting todo from cloud: $e');
    }
  }

  /// Batch update reordered todos in cloud
  Future<void> _batchUpdateTodos(String userId, List<String> todoIds) async {
    try {
      final batch = _firestore.batch();
      for (var i = 0; i < todoIds.length; i++) {
        final docRef = _todosCollection(userId).doc(todoIds[i]);
        batch.update(docRef, {
          'priority': i + 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'syncStatus': 'synced',
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error batch updating todos: $e');
    }
  }

  /// Merge cloud todos with local, handling conflicts
  Future<void> _mergeAndSaveTodos(List<TodoModel> cloudTodos) async {
    final localTodos = _localStorage.getAllTodos();
    final merged = <String, TodoModel>{};

    // Process cloud todos
    for (final cloudTodo in cloudTodos) {
      final localTodo = localTodos.firstWhere(
        (t) => t.id == cloudTodo.id,
        orElse: () => cloudTodo,
      );

      if (localTodo.id == cloudTodo.id && localTodo != cloudTodo) {
        // Conflict: use last-write-wins
        if (localTodo.updatedAt.isAfter(cloudTodo.updatedAt)) {
          merged[cloudTodo.id] = localTodo;
        } else {
          merged[cloudTodo.id] = cloudTodo.copyWith(syncStatus: 'synced');
        }
      } else {
        merged[cloudTodo.id] = cloudTodo.copyWith(syncStatus: 'synced');
      }
    }

    // Keep local-only todos (not on cloud)
    for (final localTodo in localTodos) {
      if (!merged.containsKey(localTodo.id)) {
        merged[localTodo.id] = localTodo;
      }
    }

    // Save merged todos
    await _localStorage.saveMultipleTodos(merged.values.toList());
  }
}
