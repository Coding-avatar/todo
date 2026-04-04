import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';

/// Priority matrix screen (Eisenhower matrix) for expert users.
class PriorityMatrixScreen extends ConsumerWidget {
  const PriorityMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todosByPriority = ref.watch(todosByPriorityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Matrix'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Labels row
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Urgent',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Not Urgent',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // Side label
                  RotatedBox(
                    quarterTurns: -1,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.height * 0.4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Not Important',
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(
                            'Important',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Matrix grid
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _MatrixQuadrant(
                                title: 'Do First',
                                color: const Color(0xFFEF4444),
                                todos: todosByPriority[1] ?? [],
                              ),
                              const SizedBox(width: 8),
                              _MatrixQuadrant(
                                title: 'Schedule',
                                color: const Color(0xFFF59E0B),
                                todos: todosByPriority[2] ?? [],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              _MatrixQuadrant(
                                title: 'Delegate',
                                color: const Color(0xFF3B82F6),
                                todos: todosByPriority[3] ?? [],
                              ),
                              const SizedBox(width: 8),
                              _MatrixQuadrant(
                                title: 'Eliminate',
                                color: const Color(0xFF94A3B8),
                                todos: todosByPriority[4] ?? [],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrixQuadrant extends StatelessWidget {
  final String title;
  final Color color;
  final List<TodoModel> todos;

  const _MatrixQuadrant({
    required this.title,
    required this.color,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${todos.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tasks list
            Expanded(
              child: todos.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        return _CompactTodoTile(
                          todo: todos[index],
                          color: color,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTodoTile extends ConsumerWidget {
  final TodoModel todo;
  final Color color;

  const _CompactTodoTile({
    required this.todo,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            // Edit todo
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    ref.read(todoNotifierProvider.notifier).completeTodo(todo.id);
                  },
                  child: Icon(
                    Icons.radio_button_unchecked,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todo.title,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
