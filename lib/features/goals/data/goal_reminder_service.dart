import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../domain/goal_note_item.dart';
import 'goal_note_storage.dart';

class GoalReminderService {
  const GoalReminderService._();

  static Future<void> checkAndTriggerDueReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final items = GoalNoteStorage.load(prefs);
    if (items.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final dayKey = _dayKey(now);
    var changed = false;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (!item.reminderEnabled || item.text.trim().isEmpty) {
        continue;
      }

      if (item.lastTriggeredDateKey == dayKey) {
        continue;
      }

      final isWeeklyDayMatch =
          item.repeat != GoalReminderRepeat.weekly ||
          item.weeklyWeekday == now.weekday;
      if (!isWeeklyDayMatch) {
        continue;
      }

      final target = DateTime(
        now.year,
        now.month,
        now.day,
        item.reminderHour,
        item.reminderMinute,
      );

      final diffMinutes = now.difference(target).inMinutes;
      final isInTriggerWindow = diffMinutes >= 0 && diffMinutes <= 15;
      if (!isInTriggerWindow) {
        continue;
      }

      await NotificationService.instance.showNotification(
        id: (item.id.hashCode.abs() % 80000) + 1000,
        title: 'تذكير أهدافك',
        body: item.text,
        payload: 'goal_note:${item.id}',
      );

      items[i] = item.copyWith(lastTriggeredDateKey: dayKey);
      changed = true;
    }

    if (changed) {
      await GoalNoteStorage.save(prefs, items);
    }
  }

  static String _dayKey(DateTime dt) {
    return '${dt.year}-${dt.month}-${dt.day}';
  }
}
