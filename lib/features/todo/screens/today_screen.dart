import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../widgets/todo_card.dart';
import '../widgets/add_todo_sheet.dart';

/// Today screen for beginner mode - simplified todo view.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayTodosAsync = ref.watch(todayTodosProvider);
    final allTodosAsync = ref.watch(pendingTodosProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: theme.textTheme.titleLarge,
            ),
            Text(
              DateFormat('EEEE, MMMM d').format(today),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: todayTodosAsync.when(
        data: (todayTodos) => allTodosAsync.when(
          data: (allTodos) => _buildContent(context, ref, todayTodos, allTodos),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodo(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
 
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TodoModel> todayTodos,
    List<TodoModel> allTodos,
  ) {
    final theme = Theme.of(context);

    // Separate overdue todos
    final overdueTodos = allTodos.where((t) => t.isOverdue).toList();
    final noDueDateTodos = allTodos.where((t) => t.dueDate == null).toList();

    if (todayTodos.isEmpty && overdueTodos.isEmpty && noDueDateTodos.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overdue section
        if (overdueTodos.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Overdue',
            Icons.warning_amber_rounded,
            theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          ...overdueTodos.map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodoCard(todo: todo, showDueDate: true),
              )),
          const SizedBox(height: 16),
        ],

        // Today section
        if (todayTodos.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Due Today',
            Icons.today,
            theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          ...todayTodos.map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodoCard(todo: todo),
              )),
          const SizedBox(height: 16),
        ],

        // No due date section (show first 5)
        if (noDueDateTodos.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Other Tasks',
            Icons.list,
            theme.colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          ...noDueDateTodos.take(5).map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodoCard(todo: todo),
              )),
          if (noDueDateTodos.length > 5)
            TextButton(
              onPressed: () {},
              child: Text('See ${noDueDateTodos.length - 5} more'),
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All caught up!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks for today. Add something to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
