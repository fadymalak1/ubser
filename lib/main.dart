import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/firebase/firebase_init.dart';
import 'core/permissions/usage_permission_gate.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/app_usage/presentation/app_usage_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts to fetch & cache IBM Plex Sans Arabic on first run
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Arabic locale data required by DateFormat('ar')
  await initializeDateFormatting('ar');

  // Initialise local notifications (must be before FCM and Workmanager)
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await initializeFirebase();

  // Initialise FCM — registers background handler + foreground listener.
  // Token is saved per-user inside auth_provider after login/checkAuth.
  await FcmService.instance.init();

  // Register the hourly background usage-check once (idempotent).
  // Runs even when the app is closed thanks to WorkManager.
  await AppUsageNotifier().registerBackgroundCheck();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const UbserApp(),
    ),
  );
}

class UbserApp extends ConsumerWidget {
  const UbserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'UBSER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: UsagePermissionGate(child: child!),
        );
      },
    );
  }
}
