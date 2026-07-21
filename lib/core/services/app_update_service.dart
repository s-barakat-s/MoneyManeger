import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppUpdatePlatform {
  android,
  windows,
  unsupported,
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.latestBuild,
    required this.latestVersion,
    required this.downloadUrl,
    required this.message,
    required this.forceUpdate,
  });

  final AppUpdatePlatform platform;
  final int latestBuild;
  final String latestVersion;
  final String downloadUrl;
  final String message;
  final bool forceUpdate;
}

class AppUpdateService {
  AppUpdateService({
    FirebaseRemoteConfig? remoteConfig,
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const _latestBuildKey = 'android_latest_build';
  static const _latestVersionKey = 'android_latest_version';
  static const _apkUrlKey = 'android_apk_url';
  static const _forceUpdateKey = 'android_force_update';
  static const _updateMessageKey = 'android_update_message';
  static const _windowsLatestBuildKey = 'windows_latest_build';
  static const _windowsLatestVersionKey = 'windows_latest_version';
  static const _windowsDownloadUrlKey = 'windows_download_url';
  static const _windowsForceUpdateKey = 'windows_force_update';
  static const _windowsUpdateMessageKey = 'windows_update_message';

  final FirebaseRemoteConfig _remoteConfig;

  Future<AppUpdateInfo?> checkForUpdate() async {
    final platform = _currentPlatform();
    if (platform == AppUpdatePlatform.unsupported) {
      return null;
    }

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const {
        _latestBuildKey: 1,
        _latestVersionKey: '1.0.0',
        _apkUrlKey: '',
        _forceUpdateKey: false,
        _updateMessageKey: '',
        _windowsLatestBuildKey: 1,
        _windowsLatestVersionKey: '1.0.0',
        _windowsDownloadUrlKey: '',
        _windowsForceUpdateKey: false,
        _windowsUpdateMessageKey: '',
      });
      await _remoteConfig.fetchAndActivate();

      final packageInfo = await PackageInfo.fromPlatform();
      final keys = _keysFor(platform);
      final latestBuild = _remoteConfig.getInt(keys.latestBuild);
      final latestVersion = _remoteConfig.getString(keys.latestVersion).trim();
      final downloadUrl = _remoteConfig.getString(keys.downloadUrl).trim();

      if (!_isUpdateAvailable(
            installedBuild: packageInfo.buildNumber,
            installedVersion: packageInfo.version,
            latestBuild: latestBuild,
            latestVersion: latestVersion,
          ) ||
          !_isHttpUrl(downloadUrl)) {
        return null;
      }

      return AppUpdateInfo(
        platform: platform,
        latestBuild: latestBuild,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        message: _remoteConfig.getString(keys.message).trim(),
        forceUpdate: _remoteConfig.getBool(keys.forceUpdate),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('App update check failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  Future<bool> openDownloadUrl(String downloadUrl) async {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || !_isHttpUri(uri)) {
      return false;
    }

    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Opening APK URL failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    }
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && _isHttpUri(uri);
  }

  bool _isHttpUri(Uri uri) {
    return uri.hasScheme &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  AppUpdatePlatform _currentPlatform() {
    if (kIsWeb) {
      return AppUpdatePlatform.unsupported;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppUpdatePlatform.android,
      TargetPlatform.windows => AppUpdatePlatform.windows,
      _ => AppUpdatePlatform.unsupported,
    };
  }

  _RemoteConfigKeys _keysFor(AppUpdatePlatform platform) {
    return switch (platform) {
      AppUpdatePlatform.android => const _RemoteConfigKeys(
          latestBuild: _latestBuildKey,
          latestVersion: _latestVersionKey,
          downloadUrl: _apkUrlKey,
          forceUpdate: _forceUpdateKey,
          message: _updateMessageKey,
        ),
      AppUpdatePlatform.windows => const _RemoteConfigKeys(
          latestBuild: _windowsLatestBuildKey,
          latestVersion: _windowsLatestVersionKey,
          downloadUrl: _windowsDownloadUrlKey,
          forceUpdate: _windowsForceUpdateKey,
          message: _windowsUpdateMessageKey,
        ),
      AppUpdatePlatform.unsupported => throw StateError('Unsupported platform'),
    };
  }

  bool _isUpdateAvailable({
    required String installedBuild,
    required String installedVersion,
    required int latestBuild,
    required String latestVersion,
  }) {
    final parsedInstalledBuild = int.tryParse(installedBuild);
    if (parsedInstalledBuild != null) {
      return latestBuild > parsedInstalledBuild;
    }

    return _compareSemanticVersions(latestVersion, installedVersion) > 0;
  }

  int _compareSemanticVersions(String left, String right) {
    final leftParts = _semanticVersionParts(left);
    final rightParts = _semanticVersionParts(right);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxLength; index++) {
      final leftPart = index < leftParts.length ? leftParts[index] : 0;
      final rightPart = index < rightParts.length ? rightParts[index] : 0;
      if (leftPart != rightPart) {
        return leftPart.compareTo(rightPart);
      }
    }

    return 0;
  }

  List<int> _semanticVersionParts(String value) {
    return value
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

class _RemoteConfigKeys {
  const _RemoteConfigKeys({
    required this.latestBuild,
    required this.latestVersion,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.message,
  });

  final String latestBuild;
  final String latestVersion;
  final String downloadUrl;
  final String forceUpdate;
  final String message;
}
