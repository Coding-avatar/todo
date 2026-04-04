import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/enums/enums.dart';
import '../router/route_names.dart';

/// Adaptive shell with bottom navigation that changes based on user level.
class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLevel = ref.watch(userLevelProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context, userLevel),
    );
  }

  Widget _buildBottomNav(BuildContext context, UserLevel level) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = _getNavItems(level);
    final currentIndex = _getCurrentIndex(location, level);

    // Use Cupertino style on iOS
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;

    if (isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index, level),
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onTap(context, index, level),
      destinations: items
          .map((item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              ))
          .toList(),
    );
  }

  List<_NavItem> _getNavItems(UserLevel level) {
    switch (level) {
      case UserLevel.beginner:
        return [
          _NavItem(
            icon: Icons.today_outlined,
            activeIcon: Icons.today,
            label: 'Today',
            path: RoutePaths.today,
          ),
          _NavItem(
            icon: Icons.add_circle_outline,
            activeIcon: Icons.add_circle,
            label: 'Add',
            path: RoutePaths.today, // Opens add modal instead
            isAddButton: true,
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Me',
            path: RoutePaths.settings,
          ),
        ];

      case UserLevel.intermediate:
        return [
          _NavItem(
            icon: Icons.checklist_outlined,
            activeIcon: Icons.checklist,
            label: 'Todo',
            path: RoutePaths.todoList,
          ),
          _NavItem(
            icon: Icons.repeat_outlined,
            activeIcon: Icons.repeat,
            label: 'Habits',
            path: RoutePaths.habitList,
          ),
          _NavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
            label: 'Insights',
            path: RoutePaths.insights,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            path: RoutePaths.settings,
          ),
        ];

      case UserLevel.expert:
        return [
          _NavItem(
            icon: Icons.checklist_outlined,
            activeIcon: Icons.checklist,
            label: 'Todo',
            path: RoutePaths.todoList,
          ),
          _NavItem(
            icon: Icons.repeat_outlined,
            activeIcon: Icons.repeat,
            label: 'Habits',
            path: RoutePaths.habitList,
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'Matrix',
            path: RoutePaths.matrix,
          ),
          _NavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
            label: 'Insights',
            path: RoutePaths.insights,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            path: RoutePaths.settings,
          ),
        ];
    }
  }

  int _getCurrentIndex(String location, UserLevel level) {
    final items = _getNavItems(level);
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) {
        return i;
      }
    }
    return 0;
  }

  void _onTap(BuildContext context, int index, UserLevel level) {
    final items = _getNavItems(level);
    if (index < 0 || index >= items.length) return;

    final item = items[index];

    // Special handling for beginner's "Add" button
    if (item.isAddButton) {
      _showAddModal(context);
      return;
    }

    context.go(item.path);
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AddOptionsSheet(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final bool isAddButton;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.isAddButton = false,
  });
}

/// Quick add options sheet for beginner mode
class _AddOptionsSheet extends StatelessWidget {
  const _AddOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What would you like to add?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _AddOptionTile(
            icon: Icons.check_circle_outline,
            title: 'New Task',
            subtitle: 'Add something to do',
            color: theme.colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              // Will trigger add todo sheet
              _showAddTodoSheet(context);
            },
          ),
          const SizedBox(height: 12),
          _AddOptionTile(
            icon: Icons.repeat,
            title: 'New Habit',
            subtitle: 'Build a daily routine',
            color: theme.colorScheme.secondary,
            onTap: () {
              Navigator.pop(context);
              // Will trigger add habit sheet
              _showAddHabitSheet(context);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAddTodoSheet(BuildContext context) {
    // This will be handled by the actual add todo sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Add Todo Sheet - Coming in feature implementation'),
      ),
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    // This will be handled by the actual add habit sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Add Habit Sheet - Coming in feature implementation'),
      ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
