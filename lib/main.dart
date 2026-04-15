import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
import 'services/notification_service.dart';
import 'data/local/local_storage_service.dart';
import 'data/local/hive_adapters/hive_todo_adapter.dart';
import 'data/local/hive_adapters/hive_habit_adapter.dart';
import 'data/local/hive_adapters/hive_habit_log_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await _initHive();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize notifications
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}

/// Initialize Hive for local storage
Future<void> _initHive() async {
  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);
  
  // Register adapters
  Hive.registerAdapter(TodoModelAdapter());
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(HabitLogModelAdapter());
  
  // Initialize LocalStorageService
  await LocalStorageService().initialize();
}

/// Main app widget.
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
