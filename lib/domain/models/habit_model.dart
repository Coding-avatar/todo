import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Habit model for tracking recurring habits.
class HabitModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final DateTime startDate;
  final bool active;
  final bool isFuture; // For wishlist/future habits
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitModel({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    required this.startDate,
    this.active = true,
    this.isFuture = false,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    DateTime? startDate,
    bool? active,
    bool? isFuture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      active: active ?? this.active,
      isFuture: isFuture ?? this.isFuture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'startDate': Timestamp.fromDate(startDate),
      'active': active,
      'isFuture': isFuture,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      startDate: (json['startDate'] as Timestamp).toDate(),
      active: json['active'] as bool? ?? true,
      isFuture: json['isFuture'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        categoryId,
        startDate,
        active,
        isFuture,
        createdAt,
        updatedAt,
      ];
}
