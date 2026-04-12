import '../../domain/models/models.dart';

/// Enum for conflict resolution outcomes
enum ConflictResolution {
  /// Local version is newer
  keepLocal,

  /// Cloud version is newer
  useCloud,

  /// Merge compatible fields
  merge,

  /// Conflict detected, needs user intervention
  conflict,
}

/// Service for detecting and resolving conflicts between local and cloud data
class ConflictResolver {
  /// Detect conflict between local and cloud todo
  static ConflictResolution detectTodoConflict(TodoModel local, TodoModel cloud) {
    // Compare updatedAt timestamps
    if (local.updatedAt.isAfter(cloud.updatedAt)) {
      return ConflictResolution.keepLocal;
    } else if (cloud.updatedAt.isAfter(local.updatedAt)) {
      return ConflictResolution.useCloud;
    } else {
      // Same timestamp, use version counter as tie-breaker
      if (local.version > cloud.version) {
        return ConflictResolution.keepLocal;
      } else if (cloud.version > local.version) {
        return ConflictResolution.useCloud;
      } else {
        // Complete tie, use device ID as last resort
        return ConflictResolution.conflict;
      }
    }
  }

  /// Detect conflict between local and cloud habit
  static ConflictResolution detectHabitConflict(HabitModel local, HabitModel cloud) {
    if (local.updatedAt.isAfter(cloud.updatedAt)) {
      return ConflictResolution.keepLocal;
    } else if (cloud.updatedAt.isAfter(local.updatedAt)) {
      return ConflictResolution.useCloud;
    } else {
      if (local.version > cloud.version) {
        return ConflictResolution.keepLocal;
      } else if (cloud.version > local.version) {
        return ConflictResolution.useCloud;
      } else {
        return ConflictResolution.conflict;
      }
    }
  }

  /// Detect conflict between local and cloud habit log
  static ConflictResolution detectHabitLogConflict(
    HabitLogModel local,
    HabitLogModel cloud,
  ) {
    if (local.createdAt.isAfter(cloud.createdAt)) {
      return ConflictResolution.keepLocal;
    } else if (cloud.createdAt.isAfter(local.createdAt)) {
      return ConflictResolution.useCloud;
    } else {
      if (local.version > cloud.version) {
        return ConflictResolution.keepLocal;
      } else if (cloud.version > local.version) {
        return ConflictResolution.useCloud;
      } else {
        return ConflictResolution.conflict;
      }
    }
  }

  /// Resolve todo conflict using last-write-wins strategy
  static TodoModel resolveTodoLastWriteWins(TodoModel local, TodoModel cloud) {
    final resolution = detectTodoConflict(local, cloud);
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return local.copyWith(syncStatus: 'synced');
      case ConflictResolution.useCloud:
        return cloud.copyWith(syncStatus: 'synced');
      case ConflictResolution.merge:
      case ConflictResolution.conflict:
        // Default to cloud version for tie-breaking
        return cloud.copyWith(syncStatus: 'conflict');
    }
  }

  /// Resolve habit conflict using last-write-wins strategy
  static HabitModel resolveHabitLastWriteWins(HabitModel local, HabitModel cloud) {
    final resolution = detectHabitConflict(local, cloud);
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return local.copyWith(syncStatus: 'synced');
      case ConflictResolution.useCloud:
        return cloud.copyWith(syncStatus: 'synced');
      case ConflictResolution.merge:
      case ConflictResolution.conflict:
        return cloud.copyWith(syncStatus: 'conflict');
    }
  }

  /// Resolve habit log conflict using last-write-wins strategy
  static HabitLogModel resolveLogLastWriteWins(
    HabitLogModel local,
    HabitLogModel cloud,
  ) {
    final resolution = detectHabitLogConflict(local, cloud);
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return local.copyWith(syncStatus: 'synced');
      case ConflictResolution.useCloud:
        return cloud.copyWith(syncStatus: 'synced');
      case ConflictResolution.merge:
      case ConflictResolution.conflict:
        return cloud.copyWith(syncStatus: 'conflict');
    }
  }

  /// Smart merge strategy for todos (optional enhancement)
  /// Merges non-conflicting fields, uses newest timestamp for conflicting ones
  static TodoModel smartMergeTodos(TodoModel local, TodoModel cloud) {
    // For now, implement simple field-level merge
    // In production, track which fields changed to enable true smart merging
    final newerTime = local.updatedAt.isAfter(cloud.updatedAt) ? local.updatedAt : cloud.updatedAt;
    
    return TodoModel(
      id: cloud.id,
      title: local.updatedAt.isAfter(cloud.updatedAt) ? local.title : cloud.title,
      description: local.updatedAt.isAfter(cloud.updatedAt) ? local.description : cloud.description,
      categoryId: cloud.categoryId, // Usually not changed
      color: cloud.color,
      priority: local.updatedAt.isAfter(cloud.updatedAt) ? local.priority : cloud.priority,
      status: local.updatedAt.isAfter(cloud.updatedAt) ? local.status : cloud.status,
      dueDate: local.updatedAt.isAfter(cloud.updatedAt) ? local.dueDate : cloud.dueDate,
      reminderAt: local.updatedAt.isAfter(cloud.updatedAt) ? local.reminderAt : cloud.reminderAt,
      repeatRule: local.updatedAt.isAfter(cloud.updatedAt) ? local.repeatRule : cloud.repeatRule,
      notes: local.updatedAt.isAfter(cloud.updatedAt) ? local.notes : cloud.notes,
      createdAt: cloud.createdAt,
      updatedAt: newerTime,
      version: max(local.version, cloud.version) + 1,
      syncStatus: 'synced',
      deviceId: local.updatedAt.isAfter(cloud.updatedAt) ? local.deviceId : cloud.deviceId,
    );
  }
}

/// Extension to make max function available
int max(int a, int b) => a > b ? a : b;
