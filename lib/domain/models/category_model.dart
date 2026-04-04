import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Category model for organizing todos and habits.
class Category extends Equatable {
  final String id;
  final String name;
  final Color color;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.order = 0,
  });

  /// Default categories as specified in requirements
  static List<Category> get defaults => [
        const Category(
          id: 'personal',
          name: 'Personal / Household',
          color: Color(0xFF6366F1), // Indigo
          order: 0,
        ),
        const Category(
          id: 'work',
          name: 'Office / Career / Learning',
          color: Color(0xFF3B82F6), // Blue
          order: 1,
        ),
        const Category(
          id: 'family',
          name: 'Family / Friends',
          color: Color(0xFF22C55E), // Green
          order: 2,
        ),
        const Category(
          id: 'social',
          name: 'Social / Optional',
          color: Color(0xFFF59E0B), // Amber
          order: 3,
        ),
        const Category(
          id: 'selfcare',
          name: 'Self-Care / Emotional',
          color: Color(0xFFEC4899), // Pink
          order: 4,
        ),
      ];

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    int? order,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'order': order,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, color, order];
}
