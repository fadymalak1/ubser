import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/goal_note_item.dart';
import 'goal_note_provider.dart';

class GoalNoteScreen extends ConsumerStatefulWidget {
  const GoalNoteScreen({super.key});

  @override
  ConsumerState<GoalNoteScreen> createState() => _GoalNoteScreenState();
}

class _GoalNoteScreenState extends ConsumerState<GoalNoteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(goalNoteProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalNoteProvider);
    final total = state.items.length;
    final activeReminders = state.items.where((e) => e.reminderEnabled).length;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('إضافة هدف'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: AppTheme.primaryTealDark,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'أهدافي وملاحظاتي',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'سجل أهدافك مع تذكير ذكي في الوقت الذي تحدده',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _HeaderStatPill(label: 'الأهداف', value: '$total'),
                            const SizedBox(width: AppSpacing.sm),
                            _HeaderStatPill(
                              label: 'التذكيرات',
                              value: '$activeReminders',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.items.isEmpty)
            SliverFillRemaining(
              child: _EmptyGoalsState(onAdd: () => _openEditor(context, ref)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              sliver: SliverList.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _GoalNoteCard(
                      item: item,
                      onEdit: () => _openEditor(context, ref, initial: item),
                      onDelete: () async {
                        await ref.read(goalNoteProvider.notifier).delete(item.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حذف الهدف')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    GoalNoteItem? initial,
  }) async {
    final payload = await Navigator.of(context).push<_GoalEditorPayload>(
      MaterialPageRoute(
        builder: (_) => _GoalEditorScreen(initial: initial),
      ),
    );
    if (!mounted || payload == null) return;

    if (initial == null) {
      await ref.read(goalNoteProvider.notifier).add(
            text: payload.text,
            targetDate: payload.targetDate,
            progressPercent: payload.progressPercent,
            reminderEnabled: payload.reminderEnabled,
            reminderHour: payload.time.hour,
            reminderMinute: payload.time.minute,
            repeat: payload.repeat,
            weeklyWeekday: payload.weeklyWeekday,
          );
    } else {
      final wasDone = initial.progressPercent >= 100;
      final isDoneNow = payload.progressPercent >= 100;
      await ref.read(goalNoteProvider.notifier).update(
            initial.copyWith(
              text: payload.text,
              targetDate: payload.targetDate,
              progressPercent: payload.progressPercent,
              reminderEnabled: payload.reminderEnabled,
              reminderHour: payload.time.hour,
              reminderMinute: payload.time.minute,
              repeat: payload.repeat,
              weeklyWeekday: payload.weeklyWeekday,
            ),
          );

      if (!mounted) return;
      if (!wasDone && isDoneNow) {
        final items = ref.read(goalNoteProvider).items;
        final remaining = items.where((e) => e.progressPercent < 100).length;
        final message = remaining == 0
            ? 'ممتاز! أنجزت كل أهدافك الحالية 👏'
            : 'أحسنت! أنهيت هذا الهدف، ومتَبقي $remaining هدف. خلّيك مستمر 💪';
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          initial == null ? 'تم حفظ الهدف والتذكير' : 'تم تحديث الهدف والتذكير',
        ),
      ),
    );
  }
}

class _GoalEditorPayload {
  const _GoalEditorPayload({
    required this.text,
    required this.targetDate,
    required this.progressPercent,
    required this.reminderEnabled,
    required this.time,
    required this.repeat,
    required this.weeklyWeekday,
  });

  final String text;
  final DateTime targetDate;
  final int progressPercent;
  final bool reminderEnabled;
  final TimeOfDay time;
  final GoalReminderRepeat repeat;
  final int weeklyWeekday;
}

class _GoalEditorScreen extends StatefulWidget {
  const _GoalEditorScreen({this.initial});

  final GoalNoteItem? initial;

  @override
  State<_GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends State<_GoalEditorScreen> {
  late final TextEditingController _controller;
  late bool _reminderEnabled;
  late TimeOfDay _selectedTime;
  late GoalReminderRepeat _repeat;
  late int _weeklyDay;
  late DateTime _targetDate;
  late double _progressPercent;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _controller = TextEditingController(text: initial?.text ?? '');
    _reminderEnabled = initial?.reminderEnabled ?? false;
    _selectedTime = TimeOfDay(
      hour: initial?.reminderHour ?? 9,
      minute: initial?.reminderMinute ?? 0,
    );
    _repeat = initial?.repeat ?? GoalReminderRepeat.daily;
    _weeklyDay = initial?.weeklyWeekday ?? DateTime.monday;
    _targetDate = initial?.targetDate ?? DateTime.now().add(const Duration(days: 30));
    _progressPercent = (initial?.progressPercent ?? 0).toDouble();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(widget.initial == null ? 'إضافة هدف' : 'تعديل الهدف'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'تفاصيل الهدف',
              hintText: 'مثال: التوقف عن استخدام الهاتف بعد 11 مساءً',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                initialDate: _targetDate,
              );
              if (picked != null) {
                setState(() => _targetDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(
              'المدة/التاريخ المستهدف: ${DateFormat('d MMM yyyy', 'ar').format(_targetDate)}',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppTheme.primaryTeal.withValues(alpha: 0.06),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نسبة الإنجاز الحالية: ${_progressPercent.round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Slider(
                  value: _progressPercent,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => setState(() => _progressPercent = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              value: _reminderEnabled,
              title: const Text('تفعيل التذكير'),
              subtitle: const Text('سيصلك إشعار في الوقت المحدد تمامًا'),
              onChanged: (value) async {
                if (value) {
                  await NotificationService.instance.requestPermission();
                }
                if (!mounted) return;
                setState(() => _reminderEnabled = value);
              },
            ),
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
              icon: const Icon(Icons.schedule_rounded),
              label: Text('وقت التذكير: ${_selectedTime.format(context)}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<GoalReminderRepeat>(
              initialValue: _repeat,
              decoration: const InputDecoration(labelText: 'التكرار'),
              items: const [
                DropdownMenuItem(
                  value: GoalReminderRepeat.daily,
                  child: Text('يومي'),
                ),
                DropdownMenuItem(
                  value: GoalReminderRepeat.weekly,
                  child: Text('أسبوعي'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _repeat = value);
                }
              },
            ),
            if (_repeat == GoalReminderRepeat.weekly) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: _weeklyDay,
                decoration: const InputDecoration(labelText: 'اليوم الأسبوعي'),
                items: const [
                  DropdownMenuItem(value: DateTime.monday, child: Text('الإثنين')),
                  DropdownMenuItem(value: DateTime.tuesday, child: Text('الثلاثاء')),
                  DropdownMenuItem(value: DateTime.wednesday, child: Text('الأربعاء')),
                  DropdownMenuItem(value: DateTime.thursday, child: Text('الخميس')),
                  DropdownMenuItem(value: DateTime.friday, child: Text('الجمعة')),
                  DropdownMenuItem(value: DateTime.saturday, child: Text('السبت')),
                  DropdownMenuItem(value: DateTime.sunday, child: Text('الأحد')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _weeklyDay = value);
                  }
                },
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.initial == null ? 'حفظ الهدف' : 'تحديث الهدف'),
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('اكتب تفاصيل الهدف أولًا')),
                );
                return;
              }
              Navigator.of(context).pop(
                _GoalEditorPayload(
                  text: text,
                  targetDate: _targetDate,
                  progressPercent: _progressPercent.round(),
                  reminderEnabled: _reminderEnabled,
                  time: _selectedTime,
                  repeat: _repeat,
                  weeklyWeekday: _weeklyDay,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  const _HeaderStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalNoteCard extends StatelessWidget {
  const _GoalNoteCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final GoalNoteItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('d MMM yyyy - HH:mm', 'ar').format(item.createdAt);
    final targetText = DateFormat('d MMM yyyy', 'ar').format(item.targetDate);
    final reminderLabel = _reminderText(context, item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColorFor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppTheme.primaryTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'هدف',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaChip(
                icon: Icons.calendar_month_rounded,
                text: dateText,
              ),
              _MetaChip(
                icon: Icons.flag_circle_rounded,
                text: 'الهدف حتى: $targetText',
              ),
              _MetaChip(
                icon: Icons.trending_up_rounded,
                text: 'الإنجاز: ${item.progressPercent}%',
              ),
              _MetaChip(
                icon: item.reminderEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                text: reminderLabel,
                color: item.reminderEnabled
                    ? AppTheme.primaryTeal.withValues(alpha: 0.12)
                    : AppTheme.borderColorFor(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _reminderText(BuildContext context, GoalNoteItem item) {
    if (!item.reminderEnabled) return 'التذكير غير مفعل';
    final time = TimeOfDay(hour: item.reminderHour, minute: item.reminderMinute);
    if (item.repeat == GoalReminderRepeat.daily) {
      return 'يومي - ${time.format(context)}';
    }
    return '${_weekdayLabel(item.weeklyWeekday)} - ${time.format(context)}';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      default:
        return 'غير محدد';
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondaryColor(context)),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'ابدأ أول هدف لك',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أضف هدفًا جديدًا، واختر وقت التذكير لتصلك الإشعارات تلقائيًا.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة هدف'),
            ),
          ],
        ),
      ),
    );
  }
}
