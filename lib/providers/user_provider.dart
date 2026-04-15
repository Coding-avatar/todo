import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/repositories.dart';
import '../domain/models/models.dart';
import '../core/enums/enums.dart';
import 'auth_provider.dart';

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Stream provider for current user profile
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }
  return ref.watch(userRepositoryProvider).watchUser(userId);
});

/// Provider for current user level
final userLevelProvider = Provider<UserLevel>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.when(
    data: (user) => user?.level ?? UserLevel.beginner,
    loading: () => UserLevel.beginner,
    error: (_, _) => UserLevel.beginner,
  );
});

/// Provider to check if onboarding is complete
final onboardingCompleteProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.when(
    data: (user) => user?.onboardingComplete ?? false,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Provider for the list of categories tailored to the current user's preferences
final userCategoriesProvider = Provider<List<Category>>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  final defaults = Category.defaults;

  return userAsync.when(
    data: (user) {
      if (user == null) return defaults;
      final customColors = user.preferences.categoryColors;
      if (customColors.isEmpty) return defaults;

      return defaults.map((cat) {
        if (customColors.containsKey(cat.id)) {
          return cat.copyWith(color: Color(customColors[cat.id]!));
        }
        return cat;
      }).toList();
    },
    loading: () => defaults,
    error: (_, _) => defaults,
  );
});

/// User notifier for handling user profile updates
class UserNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateLevel(UserLevel level) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(userRepositoryProvider).updateUserLevel(
            userId,
            level.toJson(),
          );
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> completeOnboarding(UserLevel level) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateUserLevel(userId, level.toJson());
      await repo.completeOnboarding(userId);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final fields = <String, dynamic>{};
      if (displayName != null) fields['displayName'] = displayName;
      if (photoUrl != null) fields['photoUrl'] = photoUrl;

      await ref.read(userRepositoryProvider).updateUserFields(userId, fields);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(userRepositoryProvider).updateUserPreferences(userId, preferences);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(userRepositoryProvider).deleteUser(userId);
      await ref.read(authRepositoryProvider).deleteAccount();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, void>(() {
  return UserNotifier();
});
