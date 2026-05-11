import 'package:cloud_firestore/cloud_firestore.dart';

/// One AI-generated report saved to Firestore under
/// `ai_reports/{auto_id}` (filtered by `user_id`).
class SavedAiReport {
  const SavedAiReport({
    required this.id,
    required this.userId,
    required this.reportText,
    required this.periodLabelAr,
    required this.createdAt,
    this.periodStart,
    this.periodEnd,
    this.assessmentsCount,
  });

  final String id;
  final String userId;

  /// Full markdown content produced by Gemini.
  final String reportText;

  /// Human-readable Arabic label of the time window
  /// (e.g. "آخر 7 أيام").
  final String periodLabelAr;

  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int? assessmentsCount;

  /// Server-set creation timestamp.
  final DateTime createdAt;

  factory SavedAiReport.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SavedAiReport(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      reportText: data['report_text'] as String? ?? '',
      periodLabelAr: data['period_label_ar'] as String? ?? '',
      periodStart: (data['period_start'] as Timestamp?)?.toDate(),
      periodEnd: (data['period_end'] as Timestamp?)?.toDate(),
      assessmentsCount: (data['assessments_count'] as num?)?.toInt(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'report_text': reportText,
        'period_label_ar': periodLabelAr,
        if (periodStart != null) 'period_start': Timestamp.fromDate(periodStart!),
        if (periodEnd != null) 'period_end': Timestamp.fromDate(periodEnd!),
        if (assessmentsCount != null) 'assessments_count': assessmentsCount,
        'created_at': FieldValue.serverTimestamp(),
      };
}
