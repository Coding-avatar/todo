import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
// import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // await Firebase.initializeApp();

  // Initialize notifications
  // await NotificationService().initialize();
  // await NotificationService().requestPermissions();

  runApp(
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}

/// Main app widget.
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Watches the [routerProvider] for changes and rebuilds the widget whenever the provider's state updates.
    ///
    /// [ref.watch] is used to subscribe to a provider and get its current value. When the provider's
    /// state changes, the widget or function using this code will automatically rebuild/re-execute.
    /// This is useful for reactive UI updates based on provider state changes.
    ///
    /// Note: [ref.read] (not shown here) retrieves the provider value without subscribing to changes,
    /// making it suitable for one-time reads or imperative calls where automatic rebuilds aren't needed.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
