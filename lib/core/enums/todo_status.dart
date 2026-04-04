/// Status of a todo item.
enum TodoStatus {
  pending,
  completed,
  dismissed;

  String get displayName {
    switch (this) {
      case TodoStatus.pending:
        return 'Pending';
      case TodoStatus.completed:
        return 'Completed';
      case TodoStatus.dismissed:
        return 'Dismissed';
    }
  }

  /// Convert to/from Firestore
  String toJson() => name;

  static TodoStatus fromJson(String? json) {
    return TodoStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TodoStatus.pending,
    );
  }
}
