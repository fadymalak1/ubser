import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';

/// One entry of per-app usage data
class AppUsageEntry {
  const AppUsageEntry({
    required this.packageName,
    required this.appName,
    required this.usageMinutes,
    required this.lastUsed,
  });

  final String packageName;
  final String appName;
  final int usageMinutes;
  final DateTime lastUsed;

  Map<String, dynamic> toMap() => {
        'package_name': packageName,
        'app_name': appName,
        'usage_minutes': usageMinutes,
        'last_used': lastUsed.toIso8601String(),
      };
}

/// Fetches per-app screen-time data using the app_usage plugin (Android only)
class AppUsageService {
  const AppUsageService();

  // ── Fetch usage for a given range ─────────────────────────────────────────

  Future<List<AppUsageEntry>> getUsage({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!Platform.isAndroid) return [];

    try {
      final raw = await AppUsage().getAppUsage(start, end);

      final entries = raw
          .where((u) => u.usage.inSeconds > 0)
          .map((u) => AppUsageEntry(
                packageName: u.packageName,
                appName: _friendlyName(u.packageName),
                usageMinutes: u.usage.inMinutes,
                lastUsed: u.lastForeground,
              ))
          .toList()
        ..sort((a, b) => b.usageMinutes.compareTo(a.usageMinutes));

      return entries;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUsageService] Error: $e');
      return [];
    }
  }

  // ── Convenience: today's usage ────────────────────────────────────────────

  Future<List<AppUsageEntry>> getTodayUsage() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getUsage(start: startOfDay, end: now);
  }

  // ── Convenience: last 7 days ──────────────────────────────────────────────

  Future<List<AppUsageEntry>> getWeekUsage() {
    final now = DateTime.now();
    return getUsage(start: now.subtract(const Duration(days: 7)), end: now);
  }

  // ── Friendly name from package name ──────────────────────────────────────
  // Maps well-known packages; falls back to a capitalized package suffix

  static String _friendlyName(String packageName) {
    const known = {
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'Twitter / X',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.snapchat.android': 'Snapchat',
      'com.whatsapp': 'WhatsApp',
      'com.google.android.youtube': 'YouTube',
      'com.google.android.gm': 'Gmail',
      'com.google.android.apps.messaging': 'Messages',
      'com.android.chrome': 'Chrome',
      'org.telegram.messenger': 'Telegram',
      'com.netflix.mediaclient': 'Netflix',
      'com.spotify.music': 'Spotify',
      'com.linkedin.android': 'LinkedIn',
      'com.pinterest': 'Pinterest',
      'com.reddit.frontpage': 'Reddit',
    };
    if (known.containsKey(packageName)) return known[packageName]!;

    // Fallback: last segment of package name, capitalised
    final parts = packageName.split('.');
    final last = parts.isNotEmpty ? parts.last : packageName;
    return last[0].toUpperCase() + last.substring(1);
  }
}
