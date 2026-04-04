import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../core/enums/enums.dart';
import '../../../domain/models/models.dart';

/// Insights screen with analytics based on user level.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userLevel = ref.watch(userLevelProvider);
    final allTodosAsync = ref.watch(allTodosProvider);
    final activeHabitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick stats
            _QuickStatsCard(),
            const SizedBox(height: 16),

            // Task completion chart
            _TaskCompletionChart(),
            const SizedBox(height: 16),

            // Habit streak section
            _HabitStreaksCard(),

            // Advanced analytics for intermediate/expert
            if (userLevel != UserLevel.beginner) ...[
              const SizedBox(height: 16),
              _WeeklyTrendChart(),
            ],

            // Heatmap for expert only
            if (userLevel == UserLevel.expert) ...[
              const SizedBox(height: 16),
              _ActivityHeatmap(),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickStatsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allTodosAsync = ref.watch(allTodosProvider);
    final activeHabitsAsync = ref.watch(activeHabitsProvider);
    final todayCompletion = ref.watch(todayCompletionProvider);

    return allTodosAsync.when(
      data: (todos) {
        final completed = todos.where((t) => t.status == TodoStatus.completed).length;
        final pending = todos.where((t) => t.status == TodoStatus.pending).length;
        final completionRate = todos.isEmpty ? 0 : (completed / todos.length * 100).round();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.check_circle,
                        color: theme.colorScheme.primary,
                        value: '$completed',
                        label: 'Completed',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.pending_actions,
                        color: theme.colorScheme.secondary,
                        value: '$pending',
                        label: 'Pending',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.percent,
                        color: theme.colorScheme.tertiary,
                        value: '$completionRate%',
                        label: 'Done',
                      ),
                    ),
                    activeHabitsAsync.when(
                      data: (habits) {
                        final completedToday = todayCompletion.values
                            .where((completed) => completed)
                            .length;
                        return Expanded(
                          child: _StatItem(
                            icon: Icons.repeat,
                            color: const Color(0xFFF59E0B),
                            value: '$completedToday/${habits.length}',
                            label: 'Habits',
                          ),
                        );
                      },
                      loading: () => const Expanded(child: SizedBox.shrink()),
                      error: (_, __) => const Expanded(child: SizedBox.shrink()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(child: Text('Error: $e')),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TaskCompletionChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allTodosAsync = ref.watch(allTodosProvider);

    return allTodosAsync.when(
      data: (todos) {
        final completed = todos.where((t) => t.status == TodoStatus.completed).length;
        final pending = todos.where((t) => t.status == TodoStatus.pending).length;
        final dismissed = todos.where((t) => t.status == TodoStatus.dismissed).length;
        final total = todos.length;

        if (total == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No tasks yet',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Distribution',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: theme.colorScheme.primary,
                          value: completed.toDouble(),
                          title: 'Done',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: theme.colorScheme.secondary,
                          value: pending.toDouble(),
                          title: 'Pending',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        if (dismissed > 0)
                          PieChartSectionData(
                            color: theme.colorScheme.surfaceContainerHighest,
                            value: dismissed.toDouble(),
                            title: 'Dismissed',
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Text('Error: $e')),
    );
  }
}

class _HabitStreaksCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeHabitsAsync = ref.watch(activeHabitsProvider);

    return activeHabitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Habit Streaks',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...habits.take(5).map((habit) => _HabitStreakRow(habit: habit)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HabitStreakRow extends ConsumerWidget {
  final HabitModel habit;

  const _HabitStreakRow({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streakAsync = ref.watch(habitStreakProvider(habit.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.name,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          streakAsync.when(
            data: (streak) => Row(
              children: [
                if (streak > 0) ...[
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: streak >= 7
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$streak days',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Generate sample data for the last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = days[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E').format(day),
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(7, (i) {
                    // Placeholder values
                    final value = (3 + (i * 7) % 5).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: theme.colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Generate placeholder data for heatmap (past 12 weeks)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Heatmap',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 84, // 12 weeks
                itemBuilder: (context, index) {
                  // Placeholder intensity
                  final intensity = (index * 37) % 5;
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: intensity / 5 * 0.8 + 0.1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 4),
                ...List.generate(5, (i) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: i / 5 * 0.8 + 0.1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
