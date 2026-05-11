import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the platform-specific Usage Access permission (Android only).
///
/// On Android, "Usage Access" is a *special* permission that the user must
/// grant manually from the system settings — it cannot be requested through
/// the runtime permission dialog. We use a method channel to:
///
///   * detect whether the app currently has access (via `AppOpsManager`)
///   * deep-link the user to `Settings.ACTION_USAGE_ACCESS_SETTINGS`
class UsageStatsPermissionService {
  const UsageStatsPermissionService._();

  static const _channel = MethodChannel('abser/usage_stats');

  /// Returns `true` when the OS reports Usage Access as currently granted.
  /// On non-Android platforms (iOS/desktop) returns `true` so the gate is a
  /// no-op there.
  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('isUsageStatsGranted');
      return granted ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('[UsageStatsPermission] check failed: $e');
      return false;
    }
  }

  /// Opens the system "Usage access" settings screen so the user can flip the
  /// toggle for this app. Returns `false` if the platform refuses to launch
  /// the intent (extremely rare).
  static Future<bool> openSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openUsageStatsSettings');
      return ok ?? true;
    } catch (e) {
      if (kDebugMode) debugPrint('[UsageStatsPermission] open failed: $e');
      return false;
    }
  }
}
