import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';
import '../services/usage_stats_permission_service.dart';
import '../theme/app_theme.dart';

/// Blocks the rest of the app until the user grants "Usage Access" on Android.
///
/// The popup is rendered as an in-tree `Stack` overlay (not via `showDialog`)
/// because this widget sits ABOVE the `Router`/`Navigator` provided by
/// `MaterialApp.router`. Using a `Stack` works regardless of whether a
/// Navigator ancestor exists.
///
/// Behavior:
///   * On every cold start (and every time the app returns to the foreground)
///     it asks the OS whether Usage Access is granted.
///   * If not granted, an unavoidable card is shown over the app with two
///     choices:
///       - "السماح" → opens the system Usage Access settings page.
///       - "رفض"  → closes the app via `SystemNavigator.pop()`.
///   * Once the permission is detected as granted, the overlay disappears.
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
  bool _granted = !Platform.isAndroid;

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
    if (Platform.isAndroid && state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final granted = await UsageStatsPermissionService.isGranted();
    if (kDebugMode) {
      debugPrint('[UsagePermissionGate] isGranted = $granted');
    }
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _checking = false;
    });
  }

  Future<void> _onAllow() async {
    await UsageStatsPermissionService.openSettings();
    // The lifecycle observer will re-check when the user returns.
  }

  void _onDeny() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.rtl,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_checking)
          const _BlockingSplash()
        else if (!_granted)
          _UsagePermissionOverlay(
            onAllow: _onAllow,
            onDeny: _onDeny,
          ),
      ],
    );
  }
}

class _BlockingSplash extends StatelessWidget {
  const _BlockingSplash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _UsagePermissionOverlay extends StatelessWidget {
  const _UsagePermissionOverlay({
    required this.onAllow,
    required this.onDeny,
  });

  final Future<void> Function() onAllow;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Color(0xCC000000)),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: _UsagePermissionCard(
                  onAllow: onAllow,
                  onDeny: onDeny,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsagePermissionCard extends StatelessWidget {
  const _UsagePermissionCard({
    required this.onAllow,
    required this.onDeny,
  });

  final Future<void> Function() onAllow;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  onPressed: onDeny,
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
                  onPressed: () => onAllow(),
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
    );
  }
}
