import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// ── Alert thresholds ──────────────────────────────────────────────────────────

/// Per-app thresholds in minutes — an alert fires when usage FIRST crosses each
const List<int> kAppThresholdsMinutes = [60, 120, 180];

/// Total screen-time thresholds in minutes
const List<int> kTotalScreenThresholdsMinutes = [120, 240, 360];

// ── Shared-prefs key helpers ──────────────────────────────────────────────────

/// Returns the prefs key used to remember that a threshold alert was already
/// sent today for [appKey] at [thresholdMinutes].
String _alertKey(String appKey, int thresholdMinutes) {
  final date = DateTime.now();
  final day = '${date.year}-${date.month}-${date.day}';
  return 'alert_sent:$appKey:${thresholdMinutes}m:$day';
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezoneInitialized = false;

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create the Android notification channel (Android 8+).
    // Must match the channel id used in AndroidManifest.xml.
    const channel = AndroidNotificationChannel(
      'abser_general',
      'إشعارات أبصر',
      description: 'تنبيهات الاستخدام المفرط للتطبيقات',
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      ledColor: Color(0xFF00897B),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _initTimeZones() {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();
    _timezoneInitialized = true;
  }

  // ── Request permission (Android 13+) ─────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  // ── Low-level show ────────────────────────────────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'abser_general',
          'إشعارات أبصر',
          channelDescription: 'تنبيهات الاستخدام المفرط للتطبيقات',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) await init();
    await _plugin.cancel(id);
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _zonedScheduleWithFallback(
      id: id,
      title: title,
      body: body,
      scheduled: scheduled,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _zonedScheduleWithFallback(
      id: id,
      title: title,
      body: body,
      scheduled: scheduled,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
    required DateTimeComponents matchDateTimeComponents,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'abser_general',
        'إشعارات أبصر',
        channelDescription: 'تنبيهات الاستخدام المفرط للتطبيقات',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on PlatformException catch (e) {
      final isExactAlarmPermissionError =
          e.code == 'exact_alarms_not_permitted' ||
          (e.message?.toLowerCase().contains('exact alarms are not permitted') ??
              false);

      if (!isExactAlarmPermissionError) rethrow;

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    }
  }

  // ── Smart usage-alert engine ──────────────────────────────────────────────
  //
  // Rules:
  //  • Each threshold fires at most ONCE per app per day.
  //  • Multiple thresholds are supported (60 / 120 / 180 min per app).
  //  • A separate set of thresholds covers total screen time.
  //  • All "already sent" state is persisted in SharedPreferences so it
  //    survives across Workmanager isolate restarts.

  Future<void> checkAndAlertOveruse(
    List<Map<String, dynamic>> usageList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_initialized) await init();

    int totalMinutes = 0;

    for (final app in usageList) {
      final minutes = (app['usage_minutes'] as num?)?.toInt() ?? 0;
      totalMinutes += minutes;

      final appName =
          app['app_name'] as String? ?? app['package_name'] as String? ?? '?';
      final packageKey = (app['package_name'] as String? ?? appName).replaceAll(
        '.',
        '_',
      );

      for (final threshold in kAppThresholdsMinutes) {
        if (minutes < threshold) continue; // not yet reached

        final key = _alertKey(packageKey, threshold);
        if (prefs.getBool(key) == true) continue; // already alerted today

        await _fireAppAlert(
          appName: appName,
          usageMinutes: minutes,
          thresholdMinutes: threshold,
        );
        await prefs.setBool(key, true);

        if (kDebugMode) {
          debugPrint(
            '[NS] Alert sent: $appName @ ${threshold}m (actual: ${minutes}m)',
          );
        }
      }
    }

    // ── Total screen-time alerts ──────────────────────────────────────────

    for (final threshold in kTotalScreenThresholdsMinutes) {
      if (totalMinutes < threshold) continue;

      final key = _alertKey('__total__', threshold);
      if (prefs.getBool(key) == true) continue;

      await _fireTotalAlert(
        totalMinutes: totalMinutes,
        thresholdMinutes: threshold,
      );
      await prefs.setBool(key, true);

      if (kDebugMode) {
        debugPrint(
          '[NS] Total alert @ ${threshold}m (actual: ${totalMinutes}m)',
        );
      }
    }
  }

  // ── Per-app alert message ─────────────────────────────────────────────────

  Future<void> _fireAppAlert({
    required String appName,
    required int usageMinutes,
    required int thresholdMinutes,
  }) async {
    final duration = _fmt(usageMinutes);
    final threshold = _fmt(thresholdMinutes);

    final title = thresholdMinutes <= 60
        ? '⚠️ تنبيه استخدام: $appName'
        : '🚨 استخدام مفرط: $appName';

    final body =
        'وصلت إلى $duration على "$appName" اليوم '
        '(الحد: $threshold). خذ استراحة للحفاظ على صحتك الرقمية.';

    await showNotification(
      id: ('app_$appName$thresholdMinutes').hashCode.abs() % 90000,
      title: title,
      body: body,
      payload: 'usage_alert:$appName',
    );
  }

  // ── Total screen-time alert message ──────────────────────────────────────

  Future<void> _fireTotalAlert({
    required int totalMinutes,
    required int thresholdMinutes,
  }) async {
    final duration = _fmt(totalMinutes);
    final threshold = _fmt(thresholdMinutes);

    await showNotification(
      id: ('total_$thresholdMinutes').hashCode.abs() % 90000,
      title: '📱 وقت الشاشة اليومي: $duration',
      body:
          'تجاوزت $threshold من وقت الشاشة اليوم. '
          'حاول تقليل الاستخدام للحفاظ على تركيزك وراحتك.',
      payload: 'total_usage_alert',
    );
  }

  // ── Format minutes → "2س 15د" or "45د" ──────────────────────────────────

  static String _fmt(int minutes) {
    if (minutes < 60) return '$minutesد';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$hس $mد' : '$hس';
  }
}
