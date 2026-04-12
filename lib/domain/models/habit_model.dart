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
  
  // Sync metadata
  final int version; // Version counter for conflict resolution
  final String syncStatus; // pending | synced | conflict
  final String? deviceId; // Device that made the change

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
    this.version = 0,
    this.syncStatus = 'synced',
    this.deviceId,
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
    int? version,
    String? syncStatus,
    String? deviceId,
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
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Helper method to update sync metadata
  HabitModel copyWithSync({
    String? syncStatus,
    String? deviceId,
    String? name,
    String? description,
    bool? active,
    bool? isFuture,
  }) {
    return copyWith(
      name: name,
      description: description,
      active: active,
      isFuture: isFuture,
      version: version + 1,
      syncStatus: syncStatus ?? 'pending',
      deviceId: deviceId ?? this.deviceId,
      updatedAt: DateTime.now(),
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
      'version': version,
      'syncStatus': syncStatus,
      'deviceId': deviceId,
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
      version: json['version'] as int? ?? 0,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      deviceId: json['deviceId'] as String?,
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
        version,
        syncStatus,
        deviceId,
      ];
}
