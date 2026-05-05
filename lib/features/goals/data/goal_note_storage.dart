import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/goal_note_item.dart';

const String kGoalNotesStorageKey = 'goal_notes_v2';

class GoalNoteStorage {
  const GoalNoteStorage._();

  static List<GoalNoteItem> load(SharedPreferences prefs) {
    final raw = prefs.getString(kGoalNotesStorageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => GoalNoteItem.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(
    SharedPreferences prefs,
    List<GoalNoteItem> items,
  ) async {
    final payload = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(kGoalNotesStorageKey, payload);
  }
}
