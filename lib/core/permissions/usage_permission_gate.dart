import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';
import '../services/usage_stats_permission_service.dart';
import '../theme/app_theme.dart';

/// Blocks the rest of the app until the user grants "Usage Access" on Android.
///
/// Behavior:
///   * On every cold start (and every time the app returns to the foreground)
///     it asks the OS whether Usage Access is granted.
///   * If not granted, an unavoidable dialog is shown with two choices:
///       - "السماح"  → opens the system Usage Access settings page.
///       - "رفض"   → closes the app via `SystemNavigator.pop()`.
///   * Once the permission is detected as granted the dialog is dismissed
///     and the wrapped [child] is shown.
///
/// On non-Android platforms the gate is a no-op and just shows [child].
class UsagePermissionGate extends StatefulWidget {
  const UsagePermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<UsagePermissionGate> createState() => _UsagePermissionGateState();
}

class _UsagePermissionGateState extends State<UsagePermissionGate>
    with WidgetsBindingObserver {
  bool _checking = Platform.isAndroid;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from the Settings screen (or from anywhere)
    // re-check the permission so we can dismiss the dialog automatically.
    if (Platform.isAndroid && state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final granted = await UsageStatsPermissionService.isGranted();
    if (!mounted) return;
    if (_checking) {
      setState(() => _checking = false);
    }

    if (granted) {
      // Permission flipped on while the dialog was open → close it.
      if (_dialogOpen && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        _dialogOpen = false;
      }
    } else if (!_dialogOpen) {
      _showPrompt();
    }
  }

  Future<void> _showPrompt() async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const _UsagePermissionDialog(),
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const _BlockingSplash();
    }
    // Even when the dialog is open we still render the child below so the
    // app structure stays mounted (no GoRouter re-runs, no flicker).
    return widget.child;
  }
}

class _BlockingSplash extends StatelessWidget {
  const _BlockingSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _UsagePermissionDialog extends StatelessWidget {
  const _UsagePermissionDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.cardColor(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'إذن استخدام التطبيقات',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'يحتاج التطبيق إلى صلاحية "الوصول إلى بيانات الاستخدام" '
                'حتى يقدر يقيس وقت الشاشة ويحلّل سلوكك الرقمي.\n'
                'بدون هذه الصلاحية لن يعمل التطبيق.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerColor,
                        side: BorderSide(
                          color: AppTheme.dangerColor.withValues(alpha: 0.5),
                          width: 1.4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => SystemNavigator.pop(),
                      child: const Text(
                        'رفض',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await UsageStatsPermissionService.openSettings();
                        // Do NOT pop here — the gate observes the lifecycle
                        // and closes the dialog automatically once the user
                        // toggles the permission and returns to the app.
                      },
                      icon: const Icon(Icons.settings_rounded, size: 20),
                      label: const Text(
                        'السماح',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
