import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/repositories.dart';
import '../domain/models/models.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

/// Provider for HabitRepository
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

/// Stream provider for active habits
final activeHabitsProvider = StreamProvider<List<HabitModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(habitRepositoryProvider).watchHabits(userId);
});

/// Stream provider for future/wishlist habits
final futureHabitsProvider = StreamProvider<List<HabitModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(habitRepositoryProvider).watchFutureHabits(userId);
});

/// Stream provider for habit logs in last 30 days (for insights)
final recentLogsProvider = StreamProvider<List<HabitLogModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }

  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  return ref.watch(habitRepositoryProvider).watchLogsInRange(
        userId,
        thirtyDaysAgo,
        now,
      );
});

/// Provider for today's completion status for all habits
final todayCompletionProvider = Provider<Map<String, bool>>((ref) {
  final logsAsync = ref.watch(recentLogsProvider);
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);

  return logsAsync.when(
    data: (logs) {
      final todayLogs = logs.where((log) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        return logDate == normalizedToday;
      });

      return {
        for (final log in todayLogs) log.habitId: log.completed,
      };
    },
    loading: () => {},
    error: (_, _) => {},
  );
});

/// Habit notifier for handling habit CRUD and completion
class HabitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createHabit({
    required String name,
    String? description,
    String? categoryId,
    DateTime? startDate,
    bool isFuture = false,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      final habit = HabitModel(
        id: _uuid.v4(),
        name: name,
        description: description,
        categoryId: categoryId,
        startDate: startDate ?? now,
        active: true,
        isFuture: isFuture,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(habitRepositoryProvider).createHabit(userId, habit);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final updated = habit.copyWith(updatedAt: DateTime.now());
      await ref.read(habitRepositoryProvider).updateHabit(userId, updated);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(habitRepositoryProvider).deleteHabit(userId, habitId);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleHabitActive(String habitId, bool active) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(habitRepositoryProvider).toggleHabitActive(
            userId,
            habitId,
            active,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleCompletion(String habitId, DateTime date) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      // Check current status
      final log = await ref.read(habitRepositoryProvider).getLog(
            userId,
            habitId,
            date,
          );

      final newStatus = !(log?.completed ?? false);

      await ref.read(habitRepositoryProvider).toggleCompletion(
            userId,
            habitId,
            date,
            newStatus,
            log?.id ?? _uuid.v4(),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getStreak(String habitId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return 0;

    return ref.read(habitRepositoryProvider).calculateStreak(userId, habitId);
  }

  Future<Map<String, int>> getStats(String habitId, int days) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return {'total': 0, 'completed': 0, 'missed': 0};
    }

    return ref.read(habitRepositoryProvider).getCompletionStats(
          userId,
          habitId,
          days,
        );
  }
}

final habitNotifierProvider = AsyncNotifierProvider<HabitNotifier, void>(() {
  return HabitNotifier();
});

/// Provider for individual habit streak
final habitStreakProvider = FutureProvider.family<int, String>((ref, habitId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  return ref.read(habitRepositoryProvider).calculateStreak(userId, habitId);
});
