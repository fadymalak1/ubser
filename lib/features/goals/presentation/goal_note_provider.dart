import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/notification_service.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import '../data/goal_note_storage.dart';
import '../domain/goal_note_item.dart';

class GoalNoteState {
  const GoalNoteState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<GoalNoteItem> items;
  final bool isLoading;
  final String? error;

  GoalNoteState copyWith({
    List<GoalNoteItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return GoalNoteState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GoalNoteNotifier extends StateNotifier<GoalNoteState> {
  GoalNoteNotifier(this._ref) : super(const GoalNoteState());

  final Ref _ref;
  bool _reminderShownInSession = false;

  GeminiService get _gemini => _ref.read(geminiServiceProvider);

  int _notificationId(String itemId) {
    return (itemId.hashCode.abs() % 800000) + 10000;
  }

  Future<void> _syncReminderNotification(GoalNoteItem item) async {
    final id = _notificationId(item.id);
    await NotificationService.instance.cancelNotification(id);
    if (!item.reminderEnabled) {
      return;
    }

    final title = 'تذكير أهدافك';
    final body = item.text.trim().isEmpty ? 'لديك هدف جديد' : item.text;
    if (item.repeat == GoalReminderRepeat.daily) {
      await NotificationService.instance.scheduleDailyNotification(
        id: id,
        title: title,
        body: body,
        hour: item.reminderHour,
        minute: item.reminderMinute,
        payload: 'goal_note:${item.id}',
      );
      return;
    }

    await NotificationService.instance.scheduleWeeklyNotification(
      id: id,
      title: title,
      body: body,
      weekday: item.weeklyWeekday,
      hour: item.reminderHour,
      minute: item.reminderMinute,
      payload: 'goal_note:${item.id}',
    );
  }

  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final prefs = _ref.read(sharedPreferencesProvider);
      final items = GoalNoteStorage.load(prefs);
      for (final item in items) {
        try {
          await _syncReminderNotification(item);
        } catch (_) {
          // Never block loading goals if reminder scheduling fails.
        }
      }
      state = state.copyWith(items: items, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذر تحميل الملاحظات');
    }
  }

  Future<void> add({
    required String text,
    required DateTime targetDate,
    required int progressPercent,
    required bool reminderEnabled,
    required int reminderHour,
    required int reminderMinute,
    required GoalReminderRepeat repeat,
    required int weeklyWeekday,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return;
    }

    final newItem = GoalNoteItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: cleaned,
      createdAt: DateTime.now(),
      targetDate: targetDate,
      progressPercent: progressPercent.clamp(0, 100),
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      repeat: repeat,
      weeklyWeekday: weeklyWeekday,
    );

    final updated = [newItem, ...state.items];
    final prefs = _ref.read(sharedPreferencesProvider);
    await GoalNoteStorage.save(prefs, updated);
    try {
      await _syncReminderNotification(newItem);
    } catch (_) {
      // Saving the goal must succeed even if notification permission is missing.
    }
    state = state.copyWith(items: updated, error: null);
  }

  Future<void> update(GoalNoteItem item) async {
    final updated = state.items.map((e) => e.id == item.id ? item : e).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final prefs = _ref.read(sharedPreferencesProvider);
    await GoalNoteStorage.save(prefs, updated);
    try {
      await _syncReminderNotification(item);
    } catch (_) {
      // Keep updates persisted when notifications cannot be scheduled.
    }
    state = state.copyWith(items: updated, error: null);
  }

  Future<void> delete(String id) async {
    final updated = state.items.where((e) => e.id != id).toList();
    final prefs = _ref.read(sharedPreferencesProvider);
    await GoalNoteStorage.save(prefs, updated);
    await NotificationService.instance.cancelNotification(_notificationId(id));
    state = state.copyWith(items: updated, error: null);
  }

  GoalNoteItem? consumeReminderNote() {
    if (_reminderShownInSession || state.items.isEmpty) {
      return null;
    }

    GoalNoteItem? current;
    for (final item in state.items) {
      if (item.text.trim().isNotEmpty) {
        current = item;
        break;
      }
    }
    if (current == null) return null;

    _reminderShownInSession = true;
    return current;
  }

  Future<String?> buildEntryCheckInMessage() async {
    if (state.items.isEmpty) {
      return null;
    }
    final goals = state.items.take(3).map((g) {
      return {
        'text': g.text,
        'targetDate': g.targetDate.toIso8601String(),
        'progressPercent': g.progressPercent,
      };
    }).toList();

    final message = await _gemini.generateGoalCheckIn(goals: goals);
    return message.trim().isEmpty ? null : message.trim();
  }
}

final goalNoteProvider = StateNotifierProvider<GoalNoteNotifier, GoalNoteState>(
  (ref) {
    return GoalNoteNotifier(ref);
  },
);
