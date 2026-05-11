import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/saved_ai_report.dart';
import 'ai_report_pdf_preview_screen.dart';
import 'report_provider.dart';

/// Lists every AI report the user has generated, newest first.
/// Tapping a card opens a full PDF preview with print / share / download.
class AiReportHistoryScreen extends ConsumerWidget {
  const AiReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('يجب تسجيل الدخول')),
      );
    }

    final service = ref.watch(aiReportHistoryServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
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
                  onTap: () => context.pop(),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تقاريري السابقة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'كل تقرير ذكي قمت بإنشائه — معاينة PDF وتحميل',
                                style: TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text(
              'تقاريري السابقة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StreamBuilder<List<SavedAiReport>>(
            stream: service.watchUserReports(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(error: snapshot.error.toString()),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                );
              }
              final items = snapshot.data ?? const <SavedAiReport>[];
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final r = items[i];
                    return _ReportHistoryCard(
                      report: r,
                      onTap: () => _openPreview(context, r),
                      onDelete: () => _confirmDelete(context, ref, r),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, SavedAiReport r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiReportPdfPreviewScreen(report: r),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAiReport r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التقرير'),
        content: const Text('هل تريد حذف هذا التقرير من سجلك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(aiReportHistoryServiceProvider).deleteReport(r.id);
    }
  }
}

class _ReportHistoryCard extends StatelessWidget {
  const _ReportHistoryCard({
    required this.report,
    required this.onTap,
    required this.onDelete,
  });

  final SavedAiReport report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy', 'ar').format(report.createdAt);
    final timeFmt = DateFormat('HH:mm').format(report.createdAt);
    final preview = _firstParagraph(report.reportText);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderColorFor(context).withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.periodLabelAr.isNotEmpty
                                ? report.periodLabelAr
                                : 'تقرير ذكي',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: Colors.white70,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$dateFmt — $timeFmt',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'حذف',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        height: 1.55,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        if (report.assessmentsCount != null) ...[
                          _MetaChip(
                            icon: Icons.psychology_rounded,
                            label: '${report.assessmentsCount} تقييم',
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        TextButton.icon(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryTeal,
                          ),
                          icon: const Icon(
                            Icons.visibility_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'عرض PDF',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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

  static String _firstParagraph(String md) {
    final lines = md.split('\n');
    for (final raw in lines) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('#') || t == '---') continue;
      // strip simple inline markers
      return t.replaceAll('**', '').replaceAll('- ', '');
    }
    return 'بدون محتوى مرئي';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryPaleColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryTeal,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'لا يوجد تقارير محفوظة',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'قم بإنشاء تقرير ذكي من شاشة "التقرير الذكي" وسيظهر هنا تلقائياً.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.dangerColor,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'تعذر تحميل التقارير',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
