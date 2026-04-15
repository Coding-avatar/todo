/// Route name constants for type-safe navigation.
class RouteNames {
  RouteNames._();

  // Auth routes
  static const splash = 'splash';
  static const login = 'login';
  static const signup = 'signup';
  static const forgotPassword = 'forgot-password';
  static const phoneAuth = 'phone-auth';

  // Onboarding routes
  static const onboarding = 'onboarding';
  static const levelSelection = 'level-selection';

  // Main app routes
  static const home = 'home';
  static const today = 'today';
  static const todoList = 'todo-list';
  static const habitList = 'habit-list';
  static const matrix = 'matrix';
  static const insights = 'insights';
  static const settings = 'settings';

  // Settings sub-routes
  static const categorySettings = 'category-settings';
  static const account = 'account';
  static const notifications = 'notifications-settings';
}

/// Route path constants
class RoutePaths {
  RoutePaths._();

  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const phoneAuth = '/phone-auth';

  static const onboarding = '/onboarding';
  static const levelSelection = '/level-selection';

  // ShellRoute paths (for bottom navigation)
  static const today = '/today';
  static const todoList = '/todos';
  static const habitList = '/habits';
  static const matrix = '/matrix';
  static const insights = '/insights';
  static const settings = '/settings';

  // Settings sub-paths
  static const categorySettings = 'categories';
  static const account = 'account';
  static const notifications = 'notifications';
}
