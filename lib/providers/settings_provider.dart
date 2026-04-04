import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App settings state
class AppSettings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final TimeOfDay dailyReminderTime;
  final bool aiEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.dailyReminderEnabled = true,
    this.dailyReminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.aiEnabled = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    TimeOfDay? dailyReminderTime,
    bool? aiEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      aiEnabled: aiEnabled ?? this.aiEnabled,
    );
  }
}

/// Settings notifier for persisting app preferences
class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeModeKey = 'theme_mode';
  static const _notificationsKey = 'notifications_enabled';
  static const _dailyReminderKey = 'daily_reminder_enabled';
  static const _reminderHourKey = 'reminder_hour';
  static const _reminderMinuteKey = 'reminder_minute';
  static const _aiEnabledKey = 'ai_enabled';

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    final dailyReminderEnabled = prefs.getBool(_dailyReminderKey) ?? true;
    final reminderHour = prefs.getInt(_reminderHourKey) ?? 9;
    final reminderMinute = prefs.getInt(_reminderMinuteKey) ?? 0;
    final aiEnabled = prefs.getBool(_aiEnabledKey) ?? false;

    state = AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      notificationsEnabled: notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled,
      dailyReminderTime: TimeOfDay(hour: reminderHour, minute: reminderMinute),
      aiEnabled: aiEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderKey, enabled);
    state = state.copyWith(dailyReminderEnabled: enabled);
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);
    state = state.copyWith(dailyReminderTime: time);
  }

  Future<void> setAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledKey, enabled);
    state = state.copyWith(aiEnabled: enabled);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

/// Theme mode provider for easy access
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
