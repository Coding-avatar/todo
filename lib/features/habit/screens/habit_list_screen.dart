import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_sheet.dart';

/// Habit list screen for tracking daily habits.
class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(activeHabitsProvider);
    final futureHabitsAsync = ref.watch(futureHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => _showFutureHabits(context, ref),
            tooltip: 'Wishlist',
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) => _buildContent(context, ref, habits),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabit(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<HabitModel> habits,
  ) {
    if (habits.isEmpty) {
      return _buildEmptyState(context);
    }

    final todayCompletion = ref.watch(todayCompletionProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isCompletedToday = todayCompletion[habit.id] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HabitCard(
            habit: habit,
            isCompletedToday: isCompletedToday,
          ),
        );
      },
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
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No habits yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Build consistency by creating daily habits.\nSmall steps lead to big changes!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddHabit(context),
              icon: const Icon(Icons.add),
              label: const Text('Create First Habit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddHabitSheet(),
    );
  }

  void _showFutureHabits(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _FutureHabitsSheet(),
    );
  }
}

class _FutureHabitsSheet extends ConsumerWidget {
  const _FutureHabitsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final futureHabitsAsync = ref.watch(futureHabitsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Habit Wishlist',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Habits you want to build in the future',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          futureHabitsAsync.when(
            data: (habits) {
              if (habits.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No wishlist habits yet.\nAdd habits you want to start later!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: habits.map((habit) {
                  return ListTile(
                    title: Text(habit.name),
                    subtitle: habit.description != null
                        ? Text(habit.description!)
                        : null,
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(habitNotifierProvider.notifier).updateHabit(
                              habit.copyWith(isFuture: false),
                            );
                      },
                      child: const Text('Start'),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const AddHabitSheet(isFuture: true),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Wishlist'),
          ),
        ],
      ),
    );
  }
}
