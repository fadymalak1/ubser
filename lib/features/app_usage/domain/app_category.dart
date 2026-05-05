import '../../../core/services/app_usage_service.dart';

/// High-level category for grouping apps by package name (Android).
enum AppCategory {
  social,
  entertainment,
  communication,
  productivity,
  games,
  tools,
  other;

  String get labelAr => switch (this) {
        AppCategory.social => 'تواصل اجتماعي',
        AppCategory.entertainment => 'ترفيه وفيديو وموسيقى',
        AppCategory.communication => 'مراسلة ومكالمات',
        AppCategory.productivity => 'إنتاجية وعمل',
        AppCategory.games => 'ألعاب',
        AppCategory.tools => 'أدوات ومتصفح',
        AppCategory.other => 'أخرى',
      };

  /// Consistent order when two groups have the same total time.
  int get sortKey => switch (this) {
        AppCategory.social => 0,
        AppCategory.entertainment => 1,
        AppCategory.communication => 2,
        AppCategory.productivity => 3,
        AppCategory.games => 4,
        AppCategory.tools => 5,
        AppCategory.other => 6,
      };
}

/// One category bucket with apps sorted by usage (descending).
class CategoryUsageGroup {
  const CategoryUsageGroup({
    required this.category,
    required this.entries,
  });

  final AppCategory category;
  final List<AppUsageEntry> entries;

  int get totalMinutes =>
      entries.fold<int>(0, (sum, e) => sum + e.usageMinutes);

  int get maxMinutesInGroup =>
      entries.isEmpty ? 0 : entries.first.usageMinutes;
}

/// Maps a Play Store package name to a category (best-effort heuristics).
AppCategory resolveAppCategory(String packageName) {
  final p = packageName.toLowerCase();

  final exact = _exactPackageToCategory[p];
  if (exact != null) return exact;

  for (final entry in _prefixRules) {
    if (p.startsWith(entry.$1)) return entry.$2;
  }

  if (_containsAny(p, _gameHints)) return AppCategory.games;
  if (_containsAny(p, _socialHints)) return AppCategory.social;
  if (_containsAny(p, _entertainmentHints)) return AppCategory.entertainment;
  if (_containsAny(p, _communicationHints)) return AppCategory.communication;
  if (_containsAny(p, _productivityHints)) return AppCategory.productivity;
  if (_containsAny(p, _toolsHints)) return AppCategory.tools;

  return AppCategory.other;
}

/// Groups [entries] by [AppCategory], sorts apps inside each group and sorts
/// groups by total time (descending).
List<CategoryUsageGroup> groupAppUsageByCategory(List<AppUsageEntry> entries) {
  final buckets = <AppCategory, List<AppUsageEntry>>{};
  for (final e in entries) {
    final c = resolveAppCategory(e.packageName);
    buckets.putIfAbsent(c, () => []).add(e);
  }
  for (final list in buckets.values) {
    list.sort((a, b) => b.usageMinutes.compareTo(a.usageMinutes));
  }
  final groups = buckets.entries
      .map((e) => CategoryUsageGroup(category: e.key, entries: e.value))
      .toList()
    ..sort((a, b) {
      final t = b.totalMinutes.compareTo(a.totalMinutes);
      if (t != 0) return t;
      return a.category.sortKey.compareTo(b.category.sortKey);
    });
  return groups;
}

bool _containsAny(String p, List<String> hints) {
  for (final h in hints) {
    if (p.contains(h)) return true;
  }
  return false;
}

const _gameHints = [
  'game',
  'games',
  'play.games',
  'unity3d',
  'epicgames',
  'gameloft',
  'supercell',
  'activision',
  'pubg',
  'tencent.ig',
  'ea.gp',
];

const _socialHints = [
  'facebook',
  'instagram',
  'twitter',
  'tiktok',
  'snapchat',
  'reddit',
  'pinterest',
  'linkedin',
  'threads',
  'mastodon',
];

const _entertainmentHints = [
  'youtube',
  'netflix',
  'spotify',
  'twitch',
  'disney',
  'hulu',
  'primevideo',
  'music',
  'video',
  'player',
  'streaming',
  'shahid',
  'watch',
];

const _communicationHints = [
  'whatsapp',
  'telegram',
  'signal',
  'viber',
  'messenger',
  'skype',
  'zoom',
  'meet',
  'slack',
  'discord',
  'dialer',
  'contacts',
  'mms',
  'sms',
];

const _productivityHints = [
  'docs',
  'sheets',
  'slides',
  'drive',
  'office',
  'notion',
  'evernote',
  'calendar',
  'tasks',
  'keep',
  'trello',
  'asana',
  'mail',
  'outlook',
];

const _toolsHints = [
  'chrome',
  'firefox',
  'browser',
  'launcher',
  'settings',
  'file',
  'camera',
  'gallery',
  'photos',
  'keyboard',
  'inputmethod',
];

/// Hand-tuned map for common packages (lowercase keys).
const Map<String, AppCategory> _exactPackageToCategory = {
  'com.instagram.android': AppCategory.social,
  'com.facebook.katana': AppCategory.social,
  'com.facebook.orca': AppCategory.communication,
  'com.twitter.android': AppCategory.social,
  'com.zhiliaoapp.musically': AppCategory.social,
  'com.snapchat.android': AppCategory.social,
  'com.pinterest': AppCategory.social,
  'com.reddit.frontpage': AppCategory.social,
  'com.linkedin.android': AppCategory.social,
  'com.google.android.youtube': AppCategory.entertainment,
  'com.netflix.mediaclient': AppCategory.entertainment,
  'com.spotify.music': AppCategory.entertainment,
  'com.amazon.avod.thirdpartyclient': AppCategory.entertainment,
  'com.disney.disneyplus': AppCategory.entertainment,
  'tv.twitch.android.app': AppCategory.entertainment,
  'com.whatsapp': AppCategory.communication,
  'org.telegram.messenger': AppCategory.communication,
  'org.thoughtcrime.securesms': AppCategory.communication,
  'com.google.android.apps.messaging': AppCategory.communication,
  'com.android.dialer': AppCategory.communication,
  'com.android.contacts': AppCategory.communication,
  'com.google.android.gm': AppCategory.productivity,
  'com.android.chrome': AppCategory.tools,
  'com.android.vending': AppCategory.tools,
  'com.google.android.apps.docs': AppCategory.productivity,
  'com.google.android.apps.sheets': AppCategory.productivity,
};

/// Prefix rules: first match wins (longer prefixes should be listed first).
const List<(String, AppCategory)> _prefixRules = [
  ('com.google.android.apps.youtube', AppCategory.entertainment),
  ('com.google.android.youtube', AppCategory.entertainment),
  ('com.microsoft.office', AppCategory.productivity),
  ('com.microsoft', AppCategory.productivity),
  ('com.android.vending', AppCategory.tools),
];
