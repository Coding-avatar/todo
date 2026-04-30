import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../../../core/router/route_names.dart';
import '../widgets/todo_card.dart';
import '../../habit/widgets/habit_card.dart';
import '../../settings/widgets/update_prompt_dialog.dart';

/// Today screen for beginner mode - tasks and habits view.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Listen for app updates
    ref.listen(appUpdateProvider, (previous, next) {
      if (next case AsyncData(:final value)) {
        if (value.updateAvailable && value.downloadUrl != null && value.downloadUrl!.isNotEmpty) {
          UpdatePromptDialog.show(
            context,
            latestVersion: value.latestVersion,
            currentVersion: value.currentVersion,
            downloadUrl: value.downloadUrl!,
            isMandatory: value.isMandatory,
          );
        }
      }
    });

    final todayTodosAsync = ref.watch(allTodosProvider);
    final activeHabitsAsync = ref.watch(activeHabitsProvider);
    final todayCompletion = ref.watch(todayCompletionProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: theme.textTheme.titleLarge),
            Text(
              DateFormat('EEEE, MMMM d').format(today),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(RoutePaths.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: todayTodosAsync.when(
        data: (todos) => activeHabitsAsync.when(
          data: (habits) => _buildContent(context, ref, todos, habits, todayCompletion),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading habits: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading tasks: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TodoModel> todos,
    List<HabitModel> habits,
    Map<String, bool> todayCompletion,
  ) {
    final theme = Theme.of(context);

    if (todos.isEmpty && habits.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Tasks Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSectionHeader(
                  context,
                  'Tasks',
                  Icons.task_alt,
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (todos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'No tasks yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else ...[
                      ...todos.map(
                        (todo) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TodoCard(todo: todo),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Divider
        const Divider(height: 1),

        // Habits Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSectionHeader(
                  context,
                  'Habits',
                  Icons.repeat,
                  theme.colorScheme.secondary,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (habits.isEmpty)
                      Text(
                        'No habits yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...habits.map(
                        (habit) {
                          final isCompletedToday = todayCompletion[habit.id] ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: HabitCard(
                              habit: habit,
                              isCompletedToday: isCompletedToday,
                            ),
                          );
                        }
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
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
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('All caught up!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'No tasks or habits for today. Add something to get started.',
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
}
