import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/report_time_range.dart';
import 'report_provider.dart';
import 'show_report_period_dialog.dart';

/// Full-screen experience for AI-generated reports from past assessments.
class AiGeneratedReportScreen extends ConsumerStatefulWidget {
  const AiGeneratedReportScreen({super.key});

  @override
  ConsumerState<AiGeneratedReportScreen> createState() =>
      _AiGeneratedReportScreenState();
}

class _AiGeneratedReportScreenState extends ConsumerState<AiGeneratedReportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestGenerateReport() async {
    final range = await showReportPeriodDialog(context);
    if (range == null || !mounted) return;
    await ref.read(reportProvider.notifier).generateReport(range);
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ التقرير'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);
    final notifier = ref.read(reportProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _StaticReportAppBar(onBack: () => context.pop()),
      body: Stack(
        children: [
          _AmbientBackground(isDark: isDark),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.isLoading) ...[
                  _LoadingBlock(controller: _pulseController),
                ] else if (state.error != null) ...[
                  _ErrorPanel(
                    message: state.error!,
                    onRetry: _requestGenerateReport,
                  ),
                ] else if (state.reportText != null &&
                    state.reportText!.trim().isNotEmpty) ...[
                  _ReportContentCard(
                    text: state.reportText!,
                    isDark: isDark,
                    periodLabel: state.lastReportTimeRange?.labelAr,
                  ),
                ] else ...[
                  _EmptyHero(onGenerate: _requestGenerateReport),
                ],
              ],
            ),
          ),
          if (state.reportText != null &&
              state.reportText!.trim().isNotEmpty &&
              !state.isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomActionBar(
                onRegenerate: _requestGenerateReport,
                onCopy: () => _copyToClipboard(state.reportText!),
                onClear: () {
                  notifier.clearReport();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم مسح التقرير من العرض'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(AppSpacing.md),
                      ),
                    );
                  }
                },
                isLoading: state.isLoading,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fixed-height header (does not scroll or collapse with content).
class _StaticReportAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StaticReportAppBar({required this.onBack});

  final VoidCallback onBack;

  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0D9488),
        Color(0xFF0F766E),
        Color(0xFF115E59),
      ],
    ),
  );

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      child: Container(
        decoration: _gradient,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, AppSpacing.lg, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير ذكي',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'من تقييماتك السابقة',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(color: AppTheme.surfaceColor(context)),
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryTeal.withValues(alpha: isDark ? 0.12 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentPurple.withValues(alpha: isDark ? 0.08 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(
                        alpha: 0.25 + controller.value * 0.15,
                      ),
                      blurRadius: 28 + controller.value * 12,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                  ),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'جاري تحليل تقييماتك',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor(context),
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'نركّز على الاتجاهات والتوصيات العملية…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: AppTheme.borderColorFor(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColorFor(context)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.dangerColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            'تعذّر إنشاء التقرير',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardColor(context),
            AppTheme.primaryPaleColor(context),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColorFor(context)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ملخص ذكي من سجلك',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor(context),
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'يحلّل الذكاء الاصطناعي تقييماتك السابقة ويقدّم اتجاهات وتوصيات عملية — دون استبدال رأي مختص عند الحاجة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGenerate,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 22),
              label: const Text(
                'إنشاء التقرير الآن',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ReportContentCard extends StatelessWidget {
  const _ReportContentCard({
    required this.text,
    required this.isDark,
    this.periodLabel,
  });

  final String text;
  final bool isDark;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderColorFor(context).withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.view_agenda_rounded,
                color: AppTheme.primaryTeal,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقريرك المنظم',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أقسام وعناوين وقوائم — يمكنك تحديد النص ونسخه',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor(context),
                            height: 1.35,
                          ),
                    ),
                    if (periodLabel != null && periodLabel!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'الفترة: $periodLabel',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Directionality(
            textDirection: TextDirection.rtl,
            child: MarkdownBody(
              data: text,
              selectable: true,
              shrinkWrap: true,
              styleSheet: _reportMarkdownStyleSheet(context),
            ),
          ),
        ],
      ),
    );
  }

}

MarkdownStyleSheet _reportMarkdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  final primary = AppTheme.textPrimaryColor(context);
  final secondary = AppTheme.textSecondaryColor(context);
  final base = MarkdownStyleSheet.fromTheme(theme);
  return base.copyWith(
    p: theme.textTheme.bodyLarge?.copyWith(
      height: 1.68,
      color: primary,
      fontSize: 15.5,
    ),
    pPadding: const EdgeInsets.only(bottom: 6),
    h1: theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: primary,
      height: 1.25,
    ),
    h1Padding: const EdgeInsets.only(top: 8, bottom: 10),
    h2: theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppTheme.primaryTeal,
      height: 1.3,
    ),
    h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
    h3: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: primary,
      height: 1.35,
    ),
    h3Padding: const EdgeInsets.only(top: 12, bottom: 6),
    h4: theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    h4Padding: const EdgeInsets.only(top: 8, bottom: 4),
    strong: TextStyle(
      fontWeight: FontWeight.w800,
      color: primary,
    ),
    em: TextStyle(
      fontStyle: FontStyle.italic,
      color: secondary,
    ),
    blockSpacing: 12,
    listIndent: 28,
    listBullet: theme.textTheme.bodyLarge?.copyWith(
      color: AppTheme.primaryTeal,
      fontWeight: FontWeight.w800,
    ),
    listBulletPadding: const EdgeInsets.only(right: 8),
    blockquote: theme.textTheme.bodyMedium?.copyWith(
      color: secondary,
      height: 1.55,
    ),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    blockquoteDecoration: BoxDecoration(
      color: AppTheme.primaryPaleColor(context),
      borderRadius: BorderRadius.circular(10),
    ),
    code: theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontSize: 13.5,
      backgroundColor: AppTheme.borderColorFor(context).withValues(alpha: 0.45),
      color: primary,
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: AppTheme.cardColor(context),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.borderColorFor(context)),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: AppTheme.borderColorFor(context),
          width: 1,
        ),
      ),
    ),
  );
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onRegenerate,
    required this.onCopy,
    required this.onClear,
    required this.isLoading,
  });

  final VoidCallback onRegenerate;
  final VoidCallback onCopy;
  final VoidCallback onClear;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final barColor = isLight ? Colors.white : Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.22),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          16,
          AppSpacing.lg,
          bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onRegenerate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: AppTheme.primaryTeal, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('تحديث'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: isLoading ? null : onCopy,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('نسخ'),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              elevation: 1,
              shadowColor: Colors.black26,
              child: IconButton(
                onPressed: isLoading ? null : onClear,
                tooltip: 'مسح العرض',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
