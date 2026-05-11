import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../data/ai_report_pdf_builder.dart';
import '../domain/saved_ai_report.dart';

/// Renders a saved AI report as a real PDF with built-in actions to:
///   * preview inside the app (paginated zoomable viewer)
///   * download / save to device
///   * share to other apps
///   * print
class AiReportPdfPreviewScreen extends StatelessWidget {
  const AiReportPdfPreviewScreen({super.key, required this.report});

  final SavedAiReport report;

  String get _fileName {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(report.createdAt);
    return 'ubser_report_$stamp.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTealDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معاينة التقرير',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              report.periodLabelAr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: _fileName,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: AppTheme.primaryTealDark,
          iconColor: Colors.white,
          textStyle: TextStyle(color: Colors.white),
        ),
        onError: (context, error) => _PdfFallbackView(
          report: report,
          error: error,
        ),
        build: (format) => AiReportPdfBuilder.build(
          reportText: report.reportText,
          periodLabelAr: report.periodLabelAr,
          createdAt: report.createdAt,
          assessmentsCount: report.assessmentsCount,
        ),
      ),
    );
  }
}

class _PdfFallbackView extends StatelessWidget {
  const _PdfFallbackView({
    required this.report,
    required this.error,
  });

  final SavedAiReport report;
  final Object error;

  Future<void> _copyReport(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: report.reportText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ نص التقرير')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningLightColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تعذر عرض PDF على هذا الجهاز. تم عرض نص التقرير بدلاً من ذلك.\n$error',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondaryColor(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _copyReport(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('نسخ التقرير'),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColorFor(context)),
                  ),
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: Markdown(
                      data: report.reportText,
                      physics: const BouncingScrollPhysics(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
