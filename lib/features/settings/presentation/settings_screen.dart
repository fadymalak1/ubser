import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'المظهر',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.light_mode_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('فاتح'),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(v);
                      }
                    },
                  ),
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.dark_mode_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('داكن'),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(v);
                      }
                    },
                  ),
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.brightness_auto_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('تلقائي'),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(v);
                      }
                    },
                  ),
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Account ─────────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'الحساب',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.lock_reset_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('تغيير كلمة المرور'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.dangerColor,
                  ),
                  title: Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
