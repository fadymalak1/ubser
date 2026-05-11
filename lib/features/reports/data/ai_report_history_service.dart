import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/saved_ai_report.dart';

/// Firestore-backed history for AI-generated reports.
///
/// Documents live under the top-level `ai_reports` collection and are
/// filtered by `user_id` (mirrors the existing `assessments` collection
/// layout so security rules can stay consistent).
class AiReportHistoryService {
  AiReportHistoryService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.aiReportsCollection);

  Future<String> saveReport({
    required String userId,
    required String reportText,
    required String periodLabelAr,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? assessmentsCount,
  }) async {
    final doc = await _col.add({
      'user_id': userId,
      'report_text': reportText,
      'period_label_ar': periodLabelAr,
      if (periodStart != null) 'period_start': Timestamp.fromDate(periodStart),
      if (periodEnd != null) 'period_end': Timestamp.fromDate(periodEnd),
      if (assessmentsCount != null) 'assessments_count': assessmentsCount,
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Live stream of the user's reports, newest first.
  Stream<List<SavedAiReport>> watchUserReports(String userId) {
    return _col
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SavedAiReport.fromDoc).toList());
  }

  Future<void> deleteReport(String reportId) {
    return _col.doc(reportId).delete();
  }
}
