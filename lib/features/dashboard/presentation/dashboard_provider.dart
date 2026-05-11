import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_secrets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/assessment_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../survey/presentation/survey_provider.dart';

class AssessmentData {
  const AssessmentData({
    required this.riskLevel,
    required this.primaryFactor,
    required this.recommendations,
    this.date,
  });

  final String riskLevel;
  final String primaryFactor;
  final List<String> recommendations;
  final DateTime? date;

  factory AssessmentData.fromMap(Map<String, dynamic> map) {
    final ai = map['ai_result'] as Map<String, dynamic>? ?? {};
    return AssessmentData(
      riskLevel: ai['risk_level'] as String? ?? AppConstants.riskMedium,
      primaryFactor: ai['primary_factor'] as String? ?? '',
      recommendations: (ai['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      date: (map['date'] as Timestamp?)?.toDate(),
    );
  }
}

/// Holds the latest survey result for [TestResultScreen] so navigation does not
/// rely on GoRouter `extra` (which is not serialized without a codec).
final testResultPendingProvider = StateProvider<AssessmentData?>((ref) => null);

class DashboardState {
  const DashboardState({
    this.assessment,
    this.isLoading = false,
    this.error,
  });

  final AssessmentData? assessment;
  final bool isLoading;
  final String? error;
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._assessmentService, this._geminiService, this._ref)
      : super(const DashboardState());

  final AssessmentService _assessmentService;
  final GeminiService _geminiService;
  final Ref _ref;

  Future<void> loadLatestAssessment() async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final doc = await _assessmentService.getLatestAssessment(userId);
      if (doc != null && doc.exists) {
        state = state.copyWith(
          assessment: AssessmentData.fromMap(doc.data()!),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Saves the survey as an assessment and returns the result for the result screen.
  /// Returns null on error or if user is not logged in.
  Future<AssessmentData?> saveAssessmentFromSurvey(SurveyState surveyState) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return null;

    state = state.copyWith(isLoading: true);
    try {
      final behavioralMetrics = await _getBehavioralMetrics();
      final psychologicalScores = surveyState.psychologicalScores;

      final aiResult = await _geminiService.analyzeRisk(
        psychologicalScores: psychologicalScores,
        behavioralMetrics: behavioralMetrics,
      );

      await _assessmentService.saveAssessment(
        userId: userId,
        psychologicalScores: psychologicalScores,
        behavioralMetrics: behavioralMetrics,
        aiResult: aiResult,
      );

      final assessment = AssessmentData(
        riskLevel: aiResult['risk_level'] as String,
        primaryFactor: aiResult['primary_factor'] as String,
        recommendations:
            (aiResult['recommendations'] as List<dynamic>).cast<String>(),
        date: DateTime.now(),
      );
      state = state.copyWith(
        assessment: assessment,
        isLoading: false,
      );
      return assessment;
    } catch (e) {
      if (kDebugMode) debugPrint('Save assessment error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>> _getBehavioralMetrics() async {
    if (!Platform.isAndroid) {
      return {
        'total_screen_time': 0,
        'night_usage': false,
        'unlocks': 0,
      };
    }

    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 1));
      final list = await AppUsage().getAppUsage(start, end);

      int totalMinutes = 0;
      bool nightUsage = false;
      final nightStart = DateTime(end.year, end.month, end.day, 22);
      final nightEnd = DateTime(end.year, end.month, end.day + 1, 6);

      for (final u in list) {
        totalMinutes += u.usage.inMinutes;
        if (u.lastForeground.isAfter(nightStart) ||
            u.lastForeground.isBefore(nightEnd)) {
          nightUsage = true;
        }
      }

      return {
        'total_screen_time': totalMinutes,
        'night_usage': nightUsage,
        'unlocks': list.length,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('App usage error: $e');
      return {
        'total_screen_time': 0,
        'night_usage': false,
        'unlocks': 0,
      };
    }
  }
}

extension _DashboardStateCopyWith on DashboardState {
  DashboardState copyWith({
    AssessmentData? assessment,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      assessment: assessment ?? this.assessment,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final assessmentServiceProvider = Provider<AssessmentService>((ref) {
  return AssessmentService(FirebaseFirestore.instance);
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: "AIzaSyA_wKN1yrp0P5GIw1zUpYYKo0i5t5TDUS4");
});

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    ref.watch(assessmentServiceProvider),
    ref.watch(geminiServiceProvider),
    ref,
  );
});
