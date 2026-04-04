import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/enums/enums.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/level_selection_screen.dart';
import '../../features/todo/screens/today_screen.dart';
import '../../features/todo/screens/todo_list_screen.dart';
import '../../features/todo/screens/priority_matrix_screen.dart';
import '../../features/habit/screens/habit_list_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../core/widgets/adaptive_shell.dart';
import 'route_names.dart';

/// GoRouter provider with auth redirect logic
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userProfile = ref.read(userProfileProvider);

      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      final hasError = authState.hasError;
      final user = userProfile.value;
      final onboardingComplete = user?.onboardingComplete ?? false;

      final currentPath = state.matchedLocation;
      
      final isAuthRoute = currentPath == RoutePaths.login ||
          currentPath == RoutePaths.signup ||
          currentPath == RoutePaths.forgotPassword;
      final isOnboardingRoute = currentPath == RoutePaths.onboarding ||
          currentPath == RoutePaths.levelSelection;
      final isSplash = currentPath == RoutePaths.splash;

      // Still loading auth state
      if (isLoading && isSplash) {
        return null;
      }

      // Not logged in - redirect to login
      if (!isLoggedIn) {
        if (isAuthRoute) {
          return null;
        }
        return RoutePaths.login;
      }

      // Logged in but onboarding not complete
      if (!onboardingComplete) {
        if (isOnboardingRoute) {
          return null;
        }
        return RoutePaths.onboarding;
      }

      // Logged in and onboarding complete - redirect away from auth/onboarding
      if (isAuthRoute || isOnboardingRoute || isSplash) {
        return _getHomeRoute(user?.level ?? UserLevel.beginner);
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Onboarding routes
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.levelSelection,
        name: RouteNames.levelSelection,
        builder: (context, state) => const LevelSelectionScreen(),
      ),

      // Main app with shell (bottom navigation)
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          // Today (beginner home)
          GoRoute(
            path: RoutePaths.today,
            name: RouteNames.today,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const TodayScreen(),
            ),
          ),

          // Todo list
          GoRoute(
            path: RoutePaths.todoList,
            name: RouteNames.todoList,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const TodoListScreen(),
            ),
          ),

          // Habit list
          GoRoute(
            path: RoutePaths.habitList,
            name: RouteNames.habitList,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const HabitListScreen(),
            ),
          ),

          // Priority matrix (expert only)
          GoRoute(
            path: RoutePaths.matrix,
            name: RouteNames.matrix,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const PriorityMatrixScreen(),
            ),
          ),

          // Insights
          GoRoute(
            path: RoutePaths.insights,
            name: RouteNames.insights,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const InsightsScreen(),
            ),
          ),

          // Settings
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// Get the home route based on user level
String _getHomeRoute(UserLevel level) {
  switch (level) {
    case UserLevel.beginner:
      return RoutePaths.today;
    case UserLevel.intermediate:
    case UserLevel.expert:
      return RoutePaths.todoList;
  }
}

/// Refresh notifier for GoRouter to react to auth state changes
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
