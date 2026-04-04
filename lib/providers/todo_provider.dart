import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/repositories.dart';
import '../domain/models/models.dart';
import '../core/enums/enums.dart';
import 'auth_provider.dart';

import '../data/repositories/mock_todo_repository.dart';

const _uuid = Uuid();

/// Provider for TodoRepository
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  if (useMockAuth) {
    return MockTodoRepository();
  }
  return TodoRepository();
});

/// Stream provider for all pending todos
final pendingTodosProvider = StreamProvider<List<TodoModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(todoRepositoryProvider).watchPendingTodos(userId);
});

/// Stream provider for all todos
final allTodosProvider = StreamProvider<List<TodoModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(todoRepositoryProvider).watchTodos(userId);
});

/// Stream provider for today's todos
final todayTodosProvider = StreamProvider<List<TodoModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(todoRepositoryProvider).watchTodayTodos(userId);
});

/// Provider for todos grouped by priority (for matrix view)
final todosByPriorityProvider = Provider<Map<int, List<TodoModel>>>((ref) {
  final todosAsync = ref.watch(pendingTodosProvider);
  return todosAsync.when(
    data: (todos) {
      final grouped = <int, List<TodoModel>>{
        1: [],
        2: [],
        3: [],
        4: [],
      };
      for (final todo in todos) {
        final priority = todo.priority.clamp(1, 4);
        grouped[priority]!.add(todo);
      }
      return grouped;
    },
    loading: () => {1: [], 2: [], 3: [], 4: []},
    error: (_, __) => {1: [], 2: [], 3: [], 4: []},
  );
});

/// Provider for todos grouped by category
final todosByCategoryProvider = Provider<Map<String, List<TodoModel>>>((ref) {
  final todosAsync = ref.watch(pendingTodosProvider);
  return todosAsync.when(
    data: (todos) {
      final grouped = <String, List<TodoModel>>{};
      for (final todo in todos) {
        grouped.putIfAbsent(todo.categoryId, () => []).add(todo);
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Todo notifier for handling todo CRUD operations
class TodoNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTodo({
    required String title,
    String? description,
    required String categoryId,
    required int color,
    int priority = 2,
    DateTime? dueDate,
    DateTime? reminderAt,
    RepeatRule repeatRule = RepeatRule.none,
    String? notes,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      final todo = TodoModel(
        id: _uuid.v4(),
        title: title,
        description: description,
        categoryId: categoryId,
        color: color,
        priority: priority,
        status: TodoStatus.pending,
        dueDate: dueDate,
        reminderAt: reminderAt,
        repeatRule: repeatRule,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(todoRepositoryProvider).createTodo(userId, todo);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateTodo(TodoModel todo) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final updated = todo.copyWith(updatedAt: DateTime.now());
      await ref.read(todoRepositoryProvider).updateTodo(userId, updated);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteTodo(String todoId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(todoRepositoryProvider).deleteTodo(userId, todoId);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> completeTodo(String todoId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(todoRepositoryProvider).completeTodo(userId, todoId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> dismissTodo(String todoId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(todoRepositoryProvider).dismissTodo(userId, todoId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderTodos(List<String> todoIds) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(todoRepositoryProvider).reorderTodos(userId, todoIds);
    } catch (e) {
      rethrow;
    }
  }
}

final todoNotifierProvider = AsyncNotifierProvider<TodoNotifier, void>(() {
  return TodoNotifier();
});
