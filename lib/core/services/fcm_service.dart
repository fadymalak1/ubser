import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler — MUST be a top-level function (runs in a separate
// isolate when the app is terminated or in background).
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Flutter plugins are available in background isolates from Firebase SDK v9+,
  // but we still need to show a local notification manually on Android when the
  // message is data-only (no notification payload).
  await NotificationService.instance.init();
  await _showFromRemoteMessage(message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: build a local notification from a RemoteMessage
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _showFromRemoteMessage(RemoteMessage message) async {
  final title = message.notification?.title ??
      message.data['title'] as String? ??
      'أبصر';
  final body = message.notification?.body ??
      message.data['body'] as String? ??
      '';

  if (body.isEmpty) return;

  await NotificationService.instance.showNotification(
    id: message.messageId.hashCode.abs() % 100000,
    title: title,
    body: body,
    payload: message.data['route'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FcmService — registers handlers and manages the FCM token
// ─────────────────────────────────────────────────────────────────────────────
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ── Initialise all FCM listeners ─────────────────────────────────────────

  Future<void> init({String? userId}) async {
    // 1. Request notification permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
    }

    // 2. Set foreground notification presentation options (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Register the top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Foreground messages — app is open
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) debugPrint('[FCM] Foreground: ${message.messageId}');
      await _showFromRemoteMessage(message);
    });

    // 5. Notification tapped while app was in background (resumed)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        debugPrint('[FCM] Opened from background: ${message.data}');
      }
      _handleTap(message);
    });

    // 6. App was terminated — check if launched via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      if (kDebugMode) {
        debugPrint('[FCM] Launched from terminated: ${initial.data}');
      }
      _handleTap(initial);
    }

    // 7. Save / refresh token
    if (userId != null) {
      await saveTokenForUser(userId);
    }

    // 8. Listen for token refreshes (tokens can rotate)
    _fcm.onTokenRefresh.listen((token) async {
      if (userId != null) await _persistToken(userId, token);
    });
  }

  // ── Get current FCM token ─────────────────────────────────────────────────

  Future<String?> getToken() => _fcm.getToken();

  // ── Save token to Firestore so server can push to this device ─────────────

  Future<void> saveTokenForUser(String userId) async {
    final token = await _fcm.getToken();
    if (token == null) return;
    await _persistToken(userId, token);
  }

  Future<void> _persistToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'fcm_token': token, 'token_updated_at': FieldValue.serverTimestamp()},
              SetOptions(merge: true));
      if (kDebugMode) debugPrint('[FCM] Token saved for $userId');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Token save error: $e');
    }
  }

  // ── Handle tap / deep-link routing ───────────────────────────────────────

  void _handleTap(RemoteMessage message) {
    // You can use the 'route' data field from the FCM payload to navigate.
    // Example payload: { "route": "/reports" }
    final route = message.data['route'] as String?;
    if (kDebugMode && route != null) {
      debugPrint('[FCM] Navigate to: $route');
    }
    // Navigation is intentionally not done here to avoid BuildContext issues.
    // The splash screen / auth flow will handle the correct initial route.
  }
}
