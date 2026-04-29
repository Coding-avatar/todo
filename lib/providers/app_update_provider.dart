import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/repositories/app_config_repository.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository();
});

class AppUpdateState {
  final bool updateAvailable;
  final bool isMandatory;
  final String? downloadUrl;
  final String currentVersion;
  final String latestVersion;

  AppUpdateState({
    this.updateAvailable = false,
    this.isMandatory = false,
    this.downloadUrl,
    this.currentVersion = '',
    this.latestVersion = '',
  });
}

class AppUpdateNotifier extends AsyncNotifier<AppUpdateState> {
  @override
  Future<AppUpdateState> build() async {
    return _checkForUpdates();
  }

  Future<AppUpdateState> _checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final configRepo = ref.read(appConfigRepositoryProvider);
    final data = await configRepo.getVersionInfo();

    if (data == null) {
      return AppUpdateState(currentVersion: currentVersion);
    }

    String remoteVersion = '';
    String downloadUrl = '';
    
    // Primarily supporting Android for APK download. Handling iOS stub just in case.
    if (Platform.isAndroid) {
      remoteVersion = data['android_latest_version'] as String? ?? '';
      downloadUrl = data['android_download_url'] as String? ?? '';
    } else if (Platform.isIOS) {
      remoteVersion = data['ios_latest_version'] as String? ?? '';
      downloadUrl = data['ios_download_url'] as String? ?? '';
    }

    final isMandatory = data['is_mandatory'] as bool? ?? false;

    if (remoteVersion.isNotEmpty && _isUpdateAvailable(currentVersion, remoteVersion)) {
      return AppUpdateState(
        updateAvailable: true,
        isMandatory: isMandatory,
        downloadUrl: downloadUrl,
        currentVersion: currentVersion,
        latestVersion: remoteVersion,
      );
    }

    return AppUpdateState(currentVersion: currentVersion, latestVersion: remoteVersion);
  }

  bool _isUpdateAvailable(String current, String remote) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final remoteParts = remote.split('.').map(int.parse).toList();

      for (var i = 0; i < currentParts.length; i++) {
        if (i >= remoteParts.length) break;
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
      return remoteParts.length > currentParts.length;
    } catch (_) {
      return false; // Fallback in case of parse error
    }
  }
}

final appUpdateProvider = AsyncNotifierProvider<AppUpdateNotifier, AppUpdateState>(() {
  return AppUpdateNotifier();
});
