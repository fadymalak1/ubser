import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/report_time_range.dart';

/// Shows a bottom sheet to pick which period the AI report should cover.
Future<ReportTimeRange?> showReportPeriodDialog(BuildContext context) {
  return showModalBottomSheet<ReportTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: bottom + AppSpacing.md,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.cardColor(ctx),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColorFor(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'فترة التقرير',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor(ctx),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'اختر الفترة التي تريد تضمين تقييماتها في التقرير',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor(ctx),
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...ReportTimeRange.values.map(
                (r) => ListTile(
                  leading: Icon(
                    Icons.date_range_rounded,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  title: Text(
                    r.labelAr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.of(ctx).pop(r),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
