import 'package:equatable/equatable.dart';

/// User preferences model stored within the UserModel
class UserPreferences extends Equatable {
  final List<String> devices;
  final String theme;
  final Map<String, int> categoryColors;

  const UserPreferences({
    this.devices = const [],
    this.theme = 'system',
    this.categoryColors = const {},
  });

  UserPreferences copyWith({
    List<String>? devices,
    String? theme,
    Map<String, int>? categoryColors,
  }) {
    return UserPreferences(
      devices: devices ?? this.devices,
      theme: theme ?? this.theme,
      categoryColors: categoryColors ?? this.categoryColors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devices': devices,
      'theme': theme,
      'categoryColors': categoryColors,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    // Handle categoryColors Map safely from dynamic types
    final Map<String, int> mappedColors = {};
    if (json['categoryColors'] != null) {
      final Map<String, dynamic> rawColors = json['categoryColors'] as Map<String, dynamic>;
      rawColors.forEach((key, value) {
        if (value is int) {
          mappedColors[key] = value;
        }
      });
    }

    return UserPreferences(
      devices: (json['devices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      theme: json['theme'] as String? ?? 'system',
      categoryColors: mappedColors,
    );
  }

  @override
  List<Object?> get props => [devices, theme, categoryColors];
}
