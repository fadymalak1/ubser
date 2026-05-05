import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/services/app_usage_service.dart';
import '../../../core/services/notification_service.dart'
    show NotificationService, kAppThresholdsMinutes;
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/app_category.dart';
import 'app_usage_provider.dart';

/// Height for [SliverAppBar.bottom] header (title + period tabs). Must match
/// the constrained layout inside [_ScreenHeader].
const double _kAppUsageHeaderHeight = 100;

class AppUsageScreen extends ConsumerStatefulWidget {
  const AppUsageScreen({super.key});

  @override
  ConsumerState<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends ConsumerState<AppUsageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Request notification permission (shows system dialog on Android 13+)
    await NotificationService.instance.requestPermission();

    // Load usage data (also fires any pending threshold alerts)
    await ref.read(appUsageProvider.notifier).load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUsageProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar + sticky title/tabs (single pinned sliver avoids
          //     SliverGeometry layoutExtent > paintExtent with two pins)
          SliverAppBar(
            pinned: true,
            toolbarHeight: kToolbarHeight,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: AppTheme.primaryTealDark,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        ref.read(appUsageProvider.notifier).load(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_kAppUsageHeaderHeight),
              child: _ScreenHeader(
                period: state.period,
                onChanged: (p) =>
                    ref.read(appUsageProvider.notifier).setPeriod(p),
                totalMinutes:
                    state.isLoading ? null : state.totalMinutes,
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              ),
            )
          else if (state.error != null)
            SliverFillRemaining(child: _PermissionError(onRetry: _init))
          else if (state.entries.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Builder(
                    builder: (context) {
                      final groups = groupAppUsageByCategory(state.entries);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ThresholdInfoCard(),
                          const SizedBox(height: AppSpacing.md),
                          SectionTitle(
                            title: 'الاستخدام حسب الفئة',
                            icon: Icons.category_rounded,
                            subtitle:
                                '${state.entries.length} تطبيق في ${groups.length} فئة — ${_formatMinutes(state.totalMinutes)} إجمالي',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...groups.map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _CategoryExpandableSection(group: g),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ── Period Tab Bar ────────────────────────────────────────────────────────────

class _PeriodTabBar extends StatelessWidget {
  const _PeriodTabBar({required this.current, required this.onChanged});
  final UsagePeriod current;
  final ValueChanged<UsagePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          _Tab(
            label: 'اليوم',
            selected: current == UsagePeriod.today,
            onTap: () => onChanged(UsagePeriod.today),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Tab(
            label: 'آخر 7 أيام',
            selected: current == UsagePeriod.week,
            onTap: () => onChanged(UsagePeriod.week),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryTeal.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : AppTheme.borderColorFor(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Theme.of(context).colorScheme.primary : AppTheme.textSecondaryColor(context),
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Threshold Info Card ───────────────────────────────────────────────────────

class _ThresholdInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningLightColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppTheme.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'ستصلك إشعار تحذيري عند تجاوز أي تطبيق ساعة واحدة من الاستخدام اليومي',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category group (expandable: total + per-app times) ────────────────────────

class _CategoryExpandableSection extends StatelessWidget {
  const _CategoryExpandableSection({required this.group});

  final CategoryUsageGroup group;

  @override
  Widget build(BuildContext context) {
    final maxInGroup = group.maxMinutesInGroup;
    final barMax = maxInGroup > 0 ? maxInGroup : 1;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _categoryIcon(group.category),
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            group.category.labelAr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${group.entries.length} تطبيق • ${_formatMinutes(group.totalMinutes)} إجمالي الفئة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                  ),
            ),
          ),
          children: [
            for (var i = 0; i < group.entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AppUsageCard(
                  entry: group.entries[i],
                  rank: i + 1,
                  maxMinutes: barMax,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(AppCategory c) {
  switch (c) {
    case AppCategory.social:
      return Icons.groups_rounded;
    case AppCategory.entertainment:
      return Icons.movie_rounded;
    case AppCategory.communication:
      return Icons.chat_rounded;
    case AppCategory.productivity:
      return Icons.work_rounded;
    case AppCategory.games:
      return Icons.sports_esports_rounded;
    case AppCategory.tools:
      return Icons.handyman_rounded;
    case AppCategory.other:
      return Icons.apps_rounded;
  }
}

// ── App Usage Card ────────────────────────────────────────────────────────────

class _AppUsageCard extends StatelessWidget {
  const _AppUsageCard({
    required this.entry,
    required this.rank,
    required this.maxMinutes,
  });

  final AppUsageEntry entry;
  final int rank;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final ratio = maxMinutes > 0
        ? (entry.usageMinutes / maxMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isOverThreshold =
        entry.usageMinutes >= kAppThresholdsMinutes.first;

    final barColor = isOverThreshold
        ? AppTheme.dangerColor
        : entry.usageMinutes >= 30
            ? AppTheme.warningColor
            : AppTheme.successColor;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: rank <= 3 ? AppTheme.primaryGradient : null,
              color: rank > 3 ? AppTheme.surfaceColor(context) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : AppTheme.textSecondaryColor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // App info + bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.appName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOverThreshold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerLightColor(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: AppTheme.dangerColor, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              'مفرط',
                              style: const TextStyle(
                                color: AppTheme.dangerColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: AppTheme.borderColorFor(context),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMinutes(entry.usageMinutes),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission Error ──────────────────────────────────────────────────────────

class _PermissionError extends StatelessWidget {
  const _PermissionError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warningLightColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.warningColor,
                size: 44,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'مطلوب إذن الاستخدام',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'يحتاج التطبيق إلى إذن "بيانات الاستخدام" لعرض إحصائيات التطبيقات.\n'
              'اذهب إلى الإعدادات ← التطبيقات الخاصة ← بيانات الاستخدام.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondaryColor(context), height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                await openAppSettings();
                onRetry();
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.phone_android_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'لا توجد بيانات',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'لم يتم تسجيل استخدام للتطبيقات في هذه الفترة',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen header (title + period tabs) ──────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.period,
    required this.onChanged,
    this.totalMinutes,
  });
  final UsagePeriod period;
  final ValueChanged<UsagePeriod> onChanged;
  final int? totalMinutes;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor(context),
      child: SizedBox(
        height: _kAppUsageHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'استخدام التطبيقات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (totalMinutes != null && totalMinutes! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMinutes(totalMinutes!),
                            style: const TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'إجمالي',
                            style: TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _PeriodTabBar(current: period, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

String _formatMinutes(int minutes) {
  if (minutes < 60) return '$minutesد';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '$hس $mد' : '$hس';
}
