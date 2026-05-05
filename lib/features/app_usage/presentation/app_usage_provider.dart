import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/services/app_usage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../goals/data/goal_reminder_service.dart';

// ── Background task names ─────────────────────────────────────────────────────
const _kUsageCheckTask = 'com.abser.usageCheck';
const _kUsageCheckTaskUnique = 'abser_usage_check';
const _kUsageCheckOneOffUnique = 'abser_usage_check_now';

/// Workmanager callback — runs in a separate isolate when app is in background
/// or terminated.  Must call ensureInitialized() before using any Flutter
/// plugins.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Required before using any plugin in a background isolate
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName == _kUsageCheckTask) {
      try {
        await NotificationService.instance.init();
        final entries = await const AppUsageService().getTodayUsage();
        await NotificationService.instance.checkAndAlertOveruse(
          entries.map((e) => e.toMap()).toList(),
        );
        await GoalReminderService.checkAndTriggerDueReminders();
      } catch (e) {
        debugPrint('[Workmanager] Task error: $e');
        return false; // signal failure so WorkManager can retry
      }
    }
    return true;
  });
}

// ── Period filter enum ────────────────────────────────────────────────────────

enum UsagePeriod { today, week }

// ── State ─────────────────────────────────────────────────────────────────────

class AppUsageState {
  const AppUsageState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.period = UsagePeriod.today,
    this.hasPermission = false,
  });

  final List<AppUsageEntry> entries;
  final bool isLoading;
  final String? error;
  final UsagePeriod period;
  final bool hasPermission;

  AppUsageState copyWith({
    List<AppUsageEntry>? entries,
    bool? isLoading,
    String? error,
    UsagePeriod? period,
    bool? hasPermission,
  }) => AppUsageState(
    entries: entries ?? this.entries,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    period: period ?? this.period,
    hasPermission: hasPermission ?? this.hasPermission,
  );

  // Total minutes across all apps
  int get totalMinutes => entries.fold(0, (sum, e) => sum + e.usageMinutes);

  // Top app by usage
  AppUsageEntry? get topApp => entries.isNotEmpty ? entries.first : null;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AppUsageNotifier extends StateNotifier<AppUsageState> {
  AppUsageNotifier() : super(const AppUsageState());

  final _service = const AppUsageService();

  // ── Register periodic background check ───────────────────────────────────
  //
  // Android minimum periodic interval is 15 minutes; we use that minimum.
  // ExistingWorkPolicy.keep means: if already scheduled, do nothing —
  // preventing double-registration on every app open.
  // Call once from main() or on first login; fine to call repeatedly.

  Future<void> registerBackgroundCheck() async {
    await Workmanager().initialize(callbackDispatcher);

    // A one-off check runs shortly after launch to avoid waiting for the first
    // periodic window while still allowing periodic checks in terminated mode.
    await Workmanager().registerOneOffTask(
      _kUsageCheckOneOffUnique,
      _kUsageCheckTask,
      initialDelay: const Duration(minutes: 2),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );

    await Workmanager().registerPeriodicTask(
      _kUsageCheckTaskUnique, // unique task id
      _kUsageCheckTask, // task name passed to executeTask
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  // ── Load usage data ───────────────────────────────────────────────────────

  Future<void> load({UsagePeriod? period}) async {
    final p = period ?? state.period;
    state = state.copyWith(isLoading: true, error: null, period: p);
    try {
      final entries = p == UsagePeriod.today
          ? await _service.getTodayUsage()
          : await _service.getWeekUsage();

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        hasPermission: true,
      );

      // Fire alerts using TODAY'S usage only, so daily thresholds stay correct
      // even when the screen is showing the "last 7 days" period.
      final todayEntries = await _service.getTodayUsage();
      await NotificationService.instance.checkAndAlertOveruse(
        todayEntries.map((e) => e.toMap()).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasPermission: false,
      );
    }
  }

  // ── Change period and reload ──────────────────────────────────────────────

  Future<void> setPeriod(UsagePeriod period) => load(period: period);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final appUsageProvider = StateNotifierProvider<AppUsageNotifier, AppUsageState>(
  (ref) {
    return AppUsageNotifier();
  },
);
