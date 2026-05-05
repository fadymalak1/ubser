enum GoalReminderRepeat { daily, weekly }

class GoalNoteItem {
  const GoalNoteItem({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.targetDate,
    required this.progressPercent,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.repeat,
    required this.weeklyWeekday,
    this.lastTriggeredDateKey,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime targetDate;
  final int progressPercent;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final GoalReminderRepeat repeat;
  final int weeklyWeekday;
  final String? lastTriggeredDateKey;

  GoalNoteItem copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? targetDate,
    int? progressPercent,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    GoalReminderRepeat? repeat,
    int? weeklyWeekday,
    String? lastTriggeredDateKey,
  }) {
    return GoalNoteItem(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      progressPercent: progressPercent ?? this.progressPercent,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      repeat: repeat ?? this.repeat,
      weeklyWeekday: weeklyWeekday ?? this.weeklyWeekday,
      lastTriggeredDateKey: lastTriggeredDateKey ?? this.lastTriggeredDateKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'progressPercent': progressPercent,
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'repeat': repeat.name,
      'weeklyWeekday': weeklyWeekday,
      'lastTriggeredDateKey': lastTriggeredDateKey,
    };
  }

  factory GoalNoteItem.fromJson(Map<String, dynamic> json) {
    return GoalNoteItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      targetDate:
          DateTime.tryParse(json['targetDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      progressPercent: (json['progressPercent'] as int? ?? 0).clamp(0, 100),
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 9,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      repeat: _parseRepeat(json['repeat'] as String?),
      weeklyWeekday: json['weeklyWeekday'] as int? ?? DateTime.monday,
      lastTriggeredDateKey: json['lastTriggeredDateKey'] as String?,
    );
  }

  static GoalReminderRepeat _parseRepeat(String? value) {
    switch (value) {
      case 'weekly':
        return GoalReminderRepeat.weekly;
      case 'daily':
      default:
        return GoalReminderRepeat.daily;
    }
  }
}
