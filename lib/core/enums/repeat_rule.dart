/// Repeat rule for recurring todos.
enum RepeatRule {
  none,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RepeatRule.none:
        return 'Does not repeat';
      case RepeatRule.daily:
        return 'Daily';
      case RepeatRule.weekly:
        return 'Weekly';
      case RepeatRule.monthly:
        return 'Monthly';
    }
  }

  /// Convert to/from Firestore
  String toJson() => name;

  static RepeatRule fromJson(String? json) {
    return RepeatRule.values.firstWhere(
      (e) => e.name == json,
      orElse: () => RepeatRule.none,
    );
  }
}
