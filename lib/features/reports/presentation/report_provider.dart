import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/assessment_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import '../domain/report_time_range.dart';

class ReportState {
  const ReportState({
    this.reportText,
    this.isLoading = false,
    this.error,
    this.lastReportTimeRange,
  });

  final String? reportText;
  final bool isLoading;
  final String? error;
  final ReportTimeRange? lastReportTimeRange;

  ReportState copyWith({
    String? reportText,
    bool? isLoading,
    String? error,
    ReportTimeRange? lastReportTimeRange,
  }) {
    return ReportState(
      reportText: reportText ?? this.reportText,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastReportTimeRange: lastReportTimeRange ?? this.lastReportTimeRange,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier(
    this._assessmentService,
    this._geminiService,
    this._ref,
  ) : super(const ReportState());

  final AssessmentService _assessmentService;
  final GeminiService _geminiService;
  final Ref _ref;

  Future<void> generateReport(ReportTimeRange range) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) {
      state = state.copyWith(error: 'يجب تسجيل الدخول');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final bounds = range.dateBounds(now);
      final list = await _assessmentService.getAssessmentsForReport(
        userId,
        fromInclusive: bounds.$1,
        toInclusive: bounds.$2,
      );
      if (list.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          reportText:
              'لا توجد تقييمات ضمن الفترة المحددة (${range.labelAr}). جرّب فترة أطول أو أضف تقييمات جديدة.',
          lastReportTimeRange: range,
        );
        return;
      }

      final serialized = list.map((m) {
        final copy = Map<String, dynamic>.from(m);
        final date = copy['date'];
        if (date != null && date is Timestamp) {
          copy['date'] = date.toDate().toIso8601String();
        }
        return copy;
      }).toList();

      final report = await _geminiService.generateReportFromAssessments(
        serialized,
        periodLabelAr: range.labelAr,
      );
      state = state.copyWith(
        reportText: report,
        isLoading: false,
        error: null,
        lastReportTimeRange: range,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearReport() {
    state = const ReportState();
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(
    ref.watch(assessmentServiceProvider),
    ref.watch(geminiServiceProvider),
    ref,
  );
});
