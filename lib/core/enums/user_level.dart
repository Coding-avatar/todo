/// User experience level enum that determines UI/UX complexity.
/// 
/// - [beginner]: Minimal friction, simple UI with 3 tabs (Today, Add, Me)
/// - [intermediate]: Structured, efficient UI with 4 tabs (Todo, Habits, Insights, Settings)
/// - [expert]: Dense, powerful, customizable UI with 5 tabs (Todo, Habits, Matrix, Insights, Settings)
enum UserLevel {
  beginner,
  intermediate,
  expert;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case UserLevel.beginner:
        return 'Beginner';
      case UserLevel.intermediate:
        return 'Intermediate';
      case UserLevel.expert:
        return 'Expert';
    }
  }

  /// Description for level selection screen
  String get description {
    switch (this) {
      case UserLevel.beginner:
        return 'Simple and clean. Perfect for getting started with minimal distractions.';
      case UserLevel.intermediate:
        return 'Balanced features. Great for building consistent habits and managing tasks.';
      case UserLevel.expert:
        return 'Full power. Priority matrix, detailed analytics, and advanced customization.';
    }
  }

  /// Icon for level selection
  String get iconName {
    switch (this) {
      case UserLevel.beginner:
        return '🌱';
      case UserLevel.intermediate:
        return '🌿';
      case UserLevel.expert:
        return '🌳';
    }
  }

  /// Number of bottom navigation tabs for this level
  int get tabCount {
    switch (this) {
      case UserLevel.beginner:
        return 3;
      case UserLevel.intermediate:
        return 4;
      case UserLevel.expert:
        return 5;
    }
  }

  /// Convert to/from Firestore
  String toJson() => name;

  static UserLevel fromJson(String? json) {
    return UserLevel.values.firstWhere(
      (e) => e.name == json,
      orElse: () => UserLevel.beginner,
    );
  }
}
