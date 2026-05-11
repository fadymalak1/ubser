import 'package:flutter/material.dart';
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
