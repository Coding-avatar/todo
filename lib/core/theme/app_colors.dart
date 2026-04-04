import 'package:flutter/material.dart';

/// App color palette with category colors and theme colors.
class AppColors {
  AppColors._();

  // Primary brand colors
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);

  // Secondary colors
  static const secondary = Color(0xFF22C55E);
  static const secondaryLight = Color(0xFF4ADE80);
  static const secondaryDark = Color(0xFF16A34A);

  // Neutral colors
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF64748B);

  // Dark theme colors
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const surfaceVariantDark = Color(0xFF334155);
  static const onSurfaceDark = Color(0xFFF8FAFC);
  static const onSurfaceVariantDark = Color(0xFF94A3B8);

  // Status colors
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF3B82F6);

  // Category colors (matching defaults)
  static const categoryPersonal = Color(0xFF6366F1);
  static const categoryWork = Color(0xFF3B82F6);
  static const categoryFamily = Color(0xFF22C55E);
  static const categorySocial = Color(0xFFF59E0B);
  static const categorySelfCare = Color(0xFFEC4899);

  // Priority colors for Eisenhower matrix
  static const priorityUrgentImportant = Color(0xFFEF4444);
  static const priorityImportant = Color(0xFFF59E0B);
  static const priorityUrgent = Color(0xFF3B82F6);
  static const priorityLow = Color(0xFF94A3B8);

  /// Available category colors for customization
  static const List<Color> categoryOptions = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF3B82F6), // Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
  ];
}
