import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../../../core/enums/enums.dart';
import '../widgets/todo_card.dart';
import '../widgets/add_todo_sheet.dart';

/// Full todo list screen for intermediate/expert users.
class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveTodosTab(),
          _CompletedTodosTab(),
          _AllTodosTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodo(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddTodoSheet(),
    );
  }
}

class _ActiveTodosTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(pendingTodosProvider);

    return todosAsync.when(
      data: (todos) => _buildList(context, todos),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildList(BuildContext context, List<TodoModel> todos) {
    if (todos.isEmpty) {
      return _buildEmptyState(context);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todos.length,
      onReorder: (oldIndex, newIndex) {
        // Handle reorder
      },
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(todos[index].id),
          padding: const EdgeInsets.only(bottom: 8),
          child: TodoCard(todo: todos[index], showDueDate: true),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No active tasks',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CompletedTodosTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(allTodosProvider);

    return todosAsync.when(
      data: (todos) {
        final completed = todos.where((t) => t.status == TodoStatus.completed).toList();
        return _buildList(context, completed);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildList(BuildContext context, List<TodoModel> todos) {
    if (todos.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No completed tasks yet',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TodoCard(todo: todos[index], showDueDate: true),
        );
      },
    );
  }
}

class _AllTodosTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byCategoryAsync = ref.watch(todosByCategoryProvider);
    final categories = ref.watch(userCategoriesProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final todos = byCategoryAsync[category.id] ?? [];

        if (todos.isEmpty) return const SizedBox.shrink();

        return _CategorySection(category: category, todos: todos);
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Category category;
  final List<TodoModel> todos;

  const _CategorySection({
    required this.category,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              '${todos.length}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...todos.map((todo) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TodoCard(todo: todo, showDueDate: true),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
