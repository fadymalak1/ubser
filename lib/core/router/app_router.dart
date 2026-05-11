import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_usage/presentation/app_usage_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goals/presentation/goal_note_screen.dart';
import '../../features/reports/presentation/ai_generated_report_screen.dart';
import '../../features/reports/presentation/ai_report_history_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/change_password_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/survey/presentation/survey_screen.dart';
import '../../features/survey/presentation/test_result_screen.dart';

/// Application routes
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String survey = '/survey';
  static const String reports = '/reports';
  static const String aiGeneratedReport = '/ai-generated-report';
  static const String aiReportHistory = '/ai-report-history';
  static const String appUsage = '/app-usage';
  static const String testResult = '/test-result';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String goalNote = '/goal-note';
}

/// GoRouter configuration
final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.survey,
      builder: (context, state) => const SurveyScreen(),
    ),
    GoRoute(
      path: AppRoutes.testResult,
      builder: (context, state) => const TestResultScreen(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiGeneratedReport,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiGeneratedReportScreen(),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.appUsage,
      builder: (context, state) => const AppUsageScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiReportHistory,
      builder: (context, state) => const AiReportHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.goalNote,
      builder: (context, state) => const GoalNoteScreen(),
    ),
  ],
);
