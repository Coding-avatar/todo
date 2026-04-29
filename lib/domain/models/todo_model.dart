import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/enums/enums.dart';

/// Todo item model with all required fields.
class TodoModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final int color;
  final int priority; // 1-4 for Eisenhower matrix (1=urgent+important, 4=neither)
  final TodoStatus status;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final RepeatRule repeatRule;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Sync metadata
  final int version; // Version counter for conflict resolution
  final String syncStatus; // pending | synced | conflict
  final String? deviceId; // Device that made the change

  TodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.color,
    this.priority = 2,
    this.status = TodoStatus.pending,
    this.dueDate,
    this.reminderAt,
    this.repeatRule = RepeatRule.none,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.version = 0,
    this.syncStatus = 'synced',
    this.deviceId,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Todo title cannot be empty');
    }
    if (title.trim().split(RegExp(r'\s+')).length > 15) {
      throw ArgumentError('Todo title cannot exceed 15 words');
    }
  }

  /// Whether the todo is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Whether the todo is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(todayStart) && status == TodoStatus.pending;
  }

  /// Priority label for Eisenhower matrix
  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Normal';
      case 1:
        return 'Urgent & Important';
      case 2:
        return 'Important';
      case 3:
        return 'Urgent';
      case 4:
        return 'Low Priority';
      default:
        return 'Normal';
    }
  }

  /// Helper method to update sync metadata
  TodoModel copyWithSync({
    String? syncStatus,
    String? deviceId,
    String? title,
    String? description,
    int? priority,
    TodoStatus? status,
    DateTime? dueDate,
    DateTime? reminderAt,
    RepeatRule? repeatRule,
    String? notes,
  }) {
    return copyWith(
      title: title,
      description: description,
      priority: priority,
      status: status,
      dueDate: dueDate,
      reminderAt: reminderAt,
      repeatRule: repeatRule,
      notes: notes,
      version: version + 1,
      syncStatus: syncStatus ?? 'pending',
      deviceId: deviceId ?? this.deviceId,
      updatedAt: DateTime.now(),
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    int? color,
    int? priority,
    TodoStatus? status,
    DateTime? dueDate,
    DateTime? reminderAt,
    RepeatRule? repeatRule,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? syncStatus,
    String? deviceId,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      repeatRule: repeatRule ?? this.repeatRule,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'color': color,
      'priority': priority,
      'status': status.toJson(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'repeatRule': repeatRule.toJson(),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'version': version,
      'syncStatus': syncStatus,
      'deviceId': deviceId,
    };
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String,
      color: json['color'] as int,
      priority: json['priority'] as int? ?? 2,
      status: TodoStatus.fromJson(json['status'] as String?),
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : null,
      reminderAt: json['reminderAt'] != null
          ? (json['reminderAt'] as Timestamp).toDate()
          : null,
      repeatRule: RepeatRule.fromJson(json['repeatRule'] as String?),
      notes: json['notes'] as String?,
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
        title,
        description,
        categoryId,
        color,
        priority,
        status,
        dueDate,
        reminderAt,
        repeatRule,
        notes,
        createdAt,
        updatedAt,
        version,
        syncStatus,
        deviceId,
      ];
}
