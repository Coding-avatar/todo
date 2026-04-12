import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/local/local_storage_service.dart';
import 'dart:developer' as developer;

/// Sync state
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final int conflicts;
  final String? errorMessage;

  SyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingChanges = 0,
    this.conflicts = 0,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingChanges,
    int? conflicts,
    String? errorMessage,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflicts: conflicts ?? this.conflicts,
      errorMessage: errorMessage,
    );
  }
}

/// Sync notifier for managing sync state
class SyncNotifier extends StateNotifier<SyncState> {
  final LocalStorageService _localStorage;
  Timer? _periodicSyncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncNotifier(this._localStorage) : super(SyncState()) {
    _initialize();
  }

  void _initialize() {
    // Load initial state
    _updatePendingChanges();
    
    // Monitor connectivity
    _monitorConnectivity();
    
    // Start periodic sync (every 15 minutes)
    _startPeriodicSync();
  }

  /// Monitor connectivity changes
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (result) {
        final isOnline = result.contains(ConnectivityResult.none) == false;
        state = state.copyWith(isOnline: isOnline);
        
        if (isOnline) {
          developer.log('Network reconnected, triggering sync');
          // Trigger sync when network returns
          manualSync();
        }
      },
    );
  }

  /// Start periodic sync every 15 minutes
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) async {
        if (state.isOnline && !state.isSyncing) {
          developer.log('Periodic sync triggered');
          await manualSync();
        }
      },
    );
  }

  /// Manual sync (triggered by pull-to-refresh or user action)
  Future<void> manualSync() async {
    if (state.isSyncing) return;
    
    state = state.copyWith(isSyncing: true, errorMessage: null);
    
    try {
      // Get current user ID from auth
      // Note: This is simplified; in real app, get from ref.watch(currentUserIdProvider)
      final deviceId = _localStorage.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        // Generate and save device ID if not exists
        final newDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await _localStorage.saveDeviceId(newDeviceId);
      }
      
      // For now, we'll sync without userId (this should be injected properly)
      developer.log('Manual sync started');
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
      _updatePendingChanges();
      
    } catch (e) {
      developer.log('Sync error: $e');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update pending changes count
  void _updatePendingChanges() {
    final summary = _localStorage.getSyncStatusSummary();
    state = state.copyWith(
      pendingChanges: (summary['pendingTodos'] as int? ?? 0) +
          (summary['pendingHabits'] as int? ?? 0) +
          (summary['pendingLogs'] as int? ?? 0),
      conflicts: 0, // TODO: Count actual conflicts
    );
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for sync state
final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(LocalStorageService());
});

/// Provider for initiating manual sync
final manualSyncProvider = FutureProvider<void>((ref) async {
  final syncNotifier = ref.read(syncStateProvider.notifier);
  await syncNotifier.manualSync();
});
