import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import 'edit_habit_sheet.dart';

/// Reusable habit card with completion toggle.
class HabitCard extends ConsumerWidget {
  final HabitModel habit;
  final bool isCompletedToday;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streakAsync = ref.watch(habitStreakProvider(habit.id));

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showEditSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompletedToday
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isCompletedToday ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Completion button
              GestureDetector(
                onTap: () => _toggleCompletion(ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompletedToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompletedToday ? Icons.check : Icons.circle_outlined,
                    color: isCompletedToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompletedToday
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Streak
              streakAsync.when(
                data: (streak) => _buildStreakBadge(context, streak),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge(BuildContext context, int streak) {
    if (streak == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = streak >= 7
        ? theme.colorScheme.primary
        : streak >= 3
        ? theme.colorScheme.secondary
        : theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCompletion(WidgetRef ref) {
    ref
        .read(habitNotifierProvider.notifier)
        .toggleCompletion(habit.id, DateTime.now());
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditHabitSheet(habit: habit),
    );
  }
}
