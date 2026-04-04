import 'dart:async';
import '../../domain/models/models.dart';
import '../../core/enums/enums.dart';
import '../../core/theme/app_colors.dart';
import 'todo_repository.dart';

/// Mock Todo Repository for testing without Firestore
class MockTodoRepository implements TodoRepository {
  // Static storage to persist across provider rebuilds
  static final List<TodoModel> _todos = [
    TodoModel(
      id: '1',
      title: 'Welcome to Todo App',
      description: 'This is a sample task to get you started.',
      categoryId: 'personal',
      color: AppColors.categoryPersonal.value,
      priority: 1,
      status: TodoStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TodoModel(
      id: '2',
      title: 'Try adding a new task',
      description: 'Tap the + button to create a new todo.',
      categoryId: 'work',
      color: AppColors.categoryWork.value,
      priority: 2,
      status: TodoStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now(),
    ),
     TodoModel(
      id: '3',
      title: 'Completed Task',
      description: 'This task is already done.',
      categoryId: 'personal',
      color: AppColors.categoryPersonal.value,
      priority: 3,
      status: TodoStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final _controller = StreamController<List<TodoModel>>.broadcast();

  MockTodoRepository() {
    // Emit initial value
    _controller.add(_todos);
  }

  void _notify() {
    _controller.add(List.from(_todos));
  }
  
  // ignore: unused_element
  List<TodoModel> _filter(bool Function(TodoModel) predicate) {
    return _todos.where(predicate).toList();
  }

  @override
  Stream<List<TodoModel>> watchTodos(String userId) {
    return _controller.stream;
  }

  @override
  Stream<List<TodoModel>> watchPendingTodos(String userId) {
    return _controller.stream.map((todos) => 
      todos.where((t) => t.status == TodoStatus.pending).toList()
    );
  }

  @override
  Stream<List<TodoModel>> watchTodayTodos(String userId) {
    // Simplified: return all pending for mock
    return _controller.stream.map((todos) => 
      todos.where((t) => t.status == TodoStatus.pending).toList()
    );
  }

  @override
  Stream<List<TodoModel>> watchTodosByCategory(String userId, String categoryId) {
    return _controller.stream.map((todos) => 
      todos.where((t) => t.categoryId == categoryId && t.status == TodoStatus.pending).toList()
    );
  }

  @override
  Future<TodoModel?> getTodo(String userId, String todoId) async {
    try {
      return _todos.firstWhere((t) => t.id == todoId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createTodo(String userId, TodoModel todo) async {
    _todos.add(todo);
    _notify();
  }

  @override
  Future<void> updateTodo(String userId, TodoModel todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      _notify();
    }
  }

  @override
  Future<void> deleteTodo(String userId, String todoId) async {
    _todos.removeWhere((t) => t.id == todoId);
    _notify();
  }

  @override
  Future<void> completeTodo(String userId, String todoId) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        status: TodoStatus.completed,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> dismissTodo(String userId, String todoId) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        status: TodoStatus.dismissed,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> reorderTodos(String userId, List<String> todoIds) async {
    // No-op for mock or implement simple reorder
    // For simplicity, skip
  }
}
