import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../core/enums/enums.dart';
import '../../../core/router/route_names.dart';

/// Settings screen with options based on user level.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.valueOrNull;
    final userLevel = ref.watch(userLevelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userLevel.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Experience Level
          _SettingsSection(
            title: 'Experience Level',
            children: [
              _LevelSelector(currentLevel: userLevel),
            ],
          ),
          const SizedBox(height: 16),

          // Appearance
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: 'System default',
                onTap: () => _showThemeDialog(context, ref),
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Category Colors',
                subtitle: 'Customize category colors',
                onTap: () {
                  // TODO: Navigate to color customization
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notifications
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Reminders',
                subtitle: 'Task and habit reminders',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Toggle notifications
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.access_time,
                title: 'Daily Reminder',
                subtitle: 'Reminder at 9:00 AM',
                onTap: () {
                  // TODO: Set daily reminder time
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Export Data',
                subtitle: 'Download your data as JSON',
                onTap: () {
                  // TODO: Export data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.sync,
                title: 'Sync Status',
                subtitle: 'Last synced just now',
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Features (placeholder)
          _SettingsSection(
            title: 'AI Features',
            children: [
              _SettingsTile(
                icon: Icons.auto_awesome,
                title: 'Smart Suggestions',
                subtitle: 'AI-powered task suggestions',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // TODO: Navigate to change password
                },
              ),
              _SettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                textColor: theme.colorScheme.error,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App version
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: 'system',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: 'system',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: 'system',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: textColor ?? theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

class _LevelSelector extends ConsumerWidget {
  final UserLevel currentLevel;

  const _LevelSelector({required this.currentLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: UserLevel.values.map((level) {
          final isSelected = level == currentLevel;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  await ref.read(userNotifierProvider.notifier).updateLevel(level);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(level.iconName, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.displayName,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              '${level.tabCount} navigation tabs',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
