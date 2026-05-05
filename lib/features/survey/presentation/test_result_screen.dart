import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../dashboard/presentation/dashboard_provider.dart';

/// Screen shown after the user completes the psychological assessment.
/// Displays risk level, primary factor, and AI recommendations.
class TestResultScreen extends ConsumerWidget {
  const TestResultScreen({super.key});

  void _goDashboard(WidgetRef ref, BuildContext context) {
    ref.read(testResultPendingProvider.notifier).state = null;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(testResultPendingProvider);
    if (assessment == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goDashboard(ref, context);
        },
        child: Scaffold(
        backgroundColor: AppTheme.surfaceColor(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا توجد نتيجة لعرضها',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => _goDashboard(ref, context),
                  child: const Text('الذهاب للوحة التحكم'),
                ),
              ],
            ),
          ),
        ),
        ),
      );
    }

    final data = assessment;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goDashboard(ref, context);
      },
      child: Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppTheme.primaryTealDark,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _goDashboard(ref, context),
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Text(
                                'اكتمل التقييم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'إليك نتائجك',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RiskLevelCard(
                  riskLevel: data.riskLevel,
                  title: 'مستوى الخطر لديك',
                ),
                const SizedBox(height: AppSpacing.md),
                if (data.primaryFactor.isNotEmpty) ...[
                  _PrimaryFactorCard(factor: data.primaryFactor),
                  const SizedBox(height: AppSpacing.md),
                ],
                _RecommendationsCard(recommendations: data.recommendations),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _goDashboard(ref, context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.home_rounded, size: 22),
                    label: const Text('العودة للوحة التحكم'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _PrimaryFactorCard extends StatelessWidget {
  const _PrimaryFactorCard({required this.factor});

  final String factor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'العامل الأساسي',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryTeal,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  factor,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
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

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'التوصيات',
            icon: Icons.lightbulb_rounded,
            subtitle: recommendations.isNotEmpty
                ? '${recommendations.length} توصيات مخصصة'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          if (recommendations.isEmpty)
            Text(
              'حافظ على عاداتك الصحية وراجع بعد التقييم القادم.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                    height: 1.5,
                  ),
            )
          else
            ...recommendations.asMap().entries.map(
                  (e) => _RecommendationItem(
                    index: e.key + 1,
                    text: e.value,
                  ),
                ),
        ],
      ),
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  const _RecommendationItem({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
