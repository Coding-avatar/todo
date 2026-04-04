import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Daily habit completion log.
class HabitLogModel extends Equatable {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.createdAt,
  });

  /// Normalized date (start of day) for comparison
  DateTime get normalizedDate => DateTime(date.year, date.month, date.day);

  HabitLogModel copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
    DateTime? createdAt,
  }) {
    return HabitLogModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      completed: json['completed'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [id, habitId, date, completed, createdAt];
}
