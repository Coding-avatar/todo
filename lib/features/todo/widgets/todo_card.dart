import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../../../core/enums/enums.dart';
import 'edit_todo_sheet.dart';

/// Reusable todo card with swipe actions.
class TodoCard extends ConsumerWidget {
  final TodoModel todo;
  final bool showDueDate;

  const TodoCard({
    super.key,
    required this.todo,
    this.showDueDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = todo.status == TodoStatus.completed;
    final isDismissed = todo.status == TodoStatus.dismissed;

    return Slidable(
      key: ValueKey(todo.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              ref.read(todoNotifierProvider.notifier).completeTodo(todo.id);
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Complete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              ref.read(todoNotifierProvider.notifier).dismissTodo(todo.id);
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            icon: Icons.close,
            label: 'Dismiss',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showEditSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    if (!isCompleted) {
                      ref.read(todoNotifierProvider.notifier).completeTodo(todo.id);
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Color(todo.color)
                          : Colors.transparent,
                      border: Border.all(
                        color: Color(todo.color),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        todo.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: isCompleted || isDismissed
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted || isDismissed
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),

                      // Description
                      if (todo.description != null &&
                          todo.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          todo.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Meta info
                      if (showDueDate && todo.dueDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: todo.isOverdue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(todo.dueDate!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: todo.isOverdue
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (todo.repeatRule != RepeatRule.none) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.repeat,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Category color indicator
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(todo.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay == today) {
      return 'Today';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow';
    } else if (dueDay.isBefore(today)) {
      return 'Overdue';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditTodoSheet(todo: todo),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
