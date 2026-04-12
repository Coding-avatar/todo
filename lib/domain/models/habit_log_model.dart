import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Daily habit completion log.
class HabitLogModel extends Equatable {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;
  
  // Sync metadata
  final int version; // Version counter for conflict resolution
  final String syncStatus; // pending | synced | conflict
  final String? deviceId; // Device that made the change

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.createdAt,
    this.version = 0,
    this.syncStatus = 'synced',
    this.deviceId,
  });

  /// Normalized date (start of day) for comparison
  DateTime get normalizedDate => DateTime(date.year, date.month, date.day);

  HabitLogModel copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
    DateTime? createdAt,
    int? version,
    String? syncStatus,
    String? deviceId,
  }) {
    return HabitLogModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Helper method to update sync metadata
  HabitLogModel copyWithSync({
    String? syncStatus,
    String? deviceId,
    bool? completed,
  }) {
    return copyWith(
      completed: completed,
      version: version + 1,
      syncStatus: syncStatus ?? 'pending',
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'version': version,
      'syncStatus': syncStatus,
      'deviceId': deviceId,
    };
  }

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      completed: json['completed'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      version: json['version'] as int? ?? 0,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      deviceId: json['deviceId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, habitId, date, completed, createdAt, version, syncStatus, deviceId];
}
