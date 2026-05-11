import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../goals/presentation/goal_note_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadLatestAssessment();
      _showGoalsCheckIn();
    });
  }

  Future<void> _showGoalsCheckIn() async {
    final notifier = ref.read(goalNoteProvider.notifier);
    await notifier.load();
    final goals = ref.read(goalNoteProvider).items;
    final completedGoals = goals.where((item) => item.progressPercent >= 100).toList();
    final remainingGoals = goals.where((item) => item.progressPercent < 100).toList();

    String? msg;
    if (completedGoals.isNotEmpty) {
      final completedCount = completedGoals.length;
      final remainingCount = remainingGoals.length;
      final nextGoals = remainingGoals
          .map((g) => g.text.trim())
          .where((t) => t.isNotEmpty)
          .take(2)
          .join('، ');

      if (remainingCount == 0) {
        msg = completedCount == 1
            ? 'رائع! أنجزت هدفك بالكامل 👏 الآن جاهز تبدأ هدف جديد.'
            : 'رائع جدًا! أنجزت $completedCount أهداف بالكامل 👏';
      } else {
        final nextLine = nextGoals.isEmpty ? '' : '\nالتالي: $nextGoals';
        msg =
            'ممتاز! أنجزت $completedCount هدف${completedCount > 1 ? 'ات' : ''}.\n'
            'متبقي عليك $remainingCount هدف${remainingCount > 1 ? 'ات' : ''}، كمل بنفس الحماس 💪$nextLine';
      }
    } else {
      msg = await notifier.buildEntryCheckInMessage();
    }

    if (!mounted || msg == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('متابعة أهدافك'),
        content: Text(msg!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('اغلاق'),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final fullName = authState.name?.trim() ?? '';
    final name = fullName.isEmpty ? '' : fullName.split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(152),
        child: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 152,
          elevation: 0,
          backgroundColor: AppTheme.primaryTealDark,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: _HomeHeader(
            name: name,
            onSettingsTap: () => context.push(AppRoutes.settings),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).loadLatestAssessment(),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: RiskLevelCard(
                  riskLevel: dashboardState.assessment?.riskLevel ??
                      AppConstants.riskMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActionGrid(
                onSurvey: () => context.push(AppRoutes.survey),
                onReports: () => context.push(AppRoutes.reports),
                onUsage: () => context.push(AppRoutes.appUsage),
                onGoals: () => context.push(AppRoutes.goalNote),
              ),
              const SizedBox(height: AppSpacing.md),
              _PrimaryActionCard(
                onTap: () => context.push(AppRoutes.aiGeneratedReport),
              ),
              if (dashboardState.isLoading) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.onSettingsTap,
  });

  final String name;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final visibleName = name.isEmpty ? 'صديقنا' : name;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  visibleName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، $visibleName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تابع استخدامك وأهدافك بسهولة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.onSurvey,
    required this.onReports,
    required this.onUsage,
    required this.onGoals,
  });

  final VoidCallback onSurvey;
  final VoidCallback onReports;
  final VoidCallback onUsage;
  final VoidCallback onGoals;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _FeatureTile(
          title: 'التقييم النفسي',
          subtitle: 'ابدأ تقييم جديد',
          icon: Icons.assignment_rounded,
          color: const Color(0xFF0D9488),
          onTap: onSurvey,
        ),
        _FeatureTile(
          title: 'الاختبارات السابقة',
          subtitle: 'استعرض التقارير',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF4F46E5),
          onTap: onReports,
        ),
        _FeatureTile(
          title: 'استخدام التطبيقات',
          subtitle: 'راجع وقت الشاشة',
          icon: Icons.phone_android_rounded,
          color: const Color(0xFF047857),
          onTap: onUsage,
        ),
        _FeatureTile(
          title: 'أهدافي وملاحظاتي',
          subtitle: 'تذكير ذكي يومي',
          icon: Icons.sticky_note_2_rounded,
          color: const Color(0xFF7C3AED),
          onTap: onGoals,
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.cardColor(context),
            border: Border.all(color: AppTheme.borderColorFor(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor(context),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({required this.onTap});

  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: _radius,
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryTeal,
                Color(0xFF009688),
                AppTheme.primaryTealDark,
              ],
              stops: [0.0, 0.52, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -28,
                left: -24,
                child: IgnorePointer(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -36,
                right: -20,
                child: IgnorePointer(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentPurple.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'مدعوم بالذكاء الاصطناعي',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'تقرير ذكي من تقييماتك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ملخص من تقييماتك السابقة بعد اختيار الفترة.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'أنشئ التقرير',
                              style: TextStyle(
                                color: AppTheme.primaryTealDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppTheme.primaryTealDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
