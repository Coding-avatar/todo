import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/models.dart';

/// Repository for todo operations in Firestore.
class TodoRepository {
  final FirebaseFirestore _firestore;

  TodoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get todos collection for a user
  CollectionReference<Map<String, dynamic>> _todosCollection(String userId) =>
      _firestore.collection('todos').doc(userId).collection('items');

  /// Stream all todos for a user
  Stream<List<TodoModel>> watchTodos(String userId) {
    return _todosCollection(userId)
        .orderBy('priority')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TodoModel.fromJson(doc.data())).toList());
  }

  /// Stream pending todos for a user
  Stream<List<TodoModel>> watchPendingTodos(String userId) {
    return _todosCollection(userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('priority')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TodoModel.fromJson(doc.data())).toList());
  }

  /// Stream todos due today
  Stream<List<TodoModel>> watchTodayTodos(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _todosCollection(userId)
        .where('status', isEqualTo: 'pending')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TodoModel.fromJson(doc.data())).toList());
  }

  /// Get todos by category
  Stream<List<TodoModel>> watchTodosByCategory(
    String userId,
    String categoryId,
  ) {
    return _todosCollection(userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'pending')
        .orderBy('priority')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TodoModel.fromJson(doc.data())).toList());
  }

  /// Get single todo
  Future<TodoModel?> getTodo(String userId, String todoId) async {
    final doc = await _todosCollection(userId).doc(todoId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return TodoModel.fromJson(doc.data()!);
  }

  /// Create new todo
  Future<void> createTodo(String userId, TodoModel todo) async {
    await _todosCollection(userId).doc(todo.id).set(todo.toJson());
  }

  /// Update todo
  Future<void> updateTodo(String userId, TodoModel todo) async {
    await _todosCollection(userId).doc(todo.id).update(todo.toJson());
  }

  /// Delete todo
  Future<void> deleteTodo(String userId, String todoId) async {
    await _todosCollection(userId).doc(todoId).delete();
  }

  /// Mark todo as completed
  Future<void> completeTodo(String userId, String todoId) async {
    await _todosCollection(userId).doc(todoId).update({
      'status': 'completed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mark todo as dismissed
  Future<void> dismissTodo(String userId, String todoId) async {
    await _todosCollection(userId).doc(todoId).update({
      'status': 'dismissed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Reorder todos (update priorities)
  Future<void> reorderTodos(
    String userId,
    List<String> todoIds,
  ) async {
    final batch = _firestore.batch();
    for (var i = 0; i < todoIds.length; i++) {
      final docRef = _todosCollection(userId).doc(todoIds[i]);
      batch.update(docRef, {
        'priority': i + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }
}
