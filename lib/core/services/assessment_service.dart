import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class AssessmentService {
  AssessmentService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> saveAssessment({
    required String userId,
    required Map<String, int> psychologicalScores,
    required Map<String, dynamic> behavioralMetrics,
    required Map<String, dynamic> aiResult,
  }) async {
    await _firestore.collection(AppConstants.assessmentsCollection).add({
      'user_id': userId,
      'date': FieldValue.serverTimestamp(),
      'psychological_scores': psychologicalScores,
      'behavioral_metrics': behavioralMetrics,
      'ai_result': aiResult,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAssessmentsStream(
    String userId,
  ) {
    return _firestore
        .collection(AppConstants.assessmentsCollection)
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getLatestAssessment(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection(AppConstants.assessmentsCollection)
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  /// Fetches a list of assessments for AI report generation.
  Future<List<Map<String, dynamic>>> getAssessments(
    String userId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.assessmentsCollection)
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// Assessments for AI report, optionally filtered by [fromInclusive] / [toInclusive]
  /// on the `date` field. If both are null, returns all (up to [maxFetch]).
  Future<List<Map<String, dynamic>>> getAssessmentsForReport(
    String userId, {
    DateTime? fromInclusive,
    DateTime? toInclusive,
    int maxFetch = 500,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.assessmentsCollection)
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(maxFetch)
        .get();

    final list = snapshot.docs.map((d) => d.data()).toList();
    if (fromInclusive == null && toInclusive == null) {
      return list;
    }

    bool inRange(DateTime d) {
      if (fromInclusive != null && d.isBefore(fromInclusive)) return false;
      if (toInclusive != null && d.isAfter(toInclusive)) return false;
      return true;
    }

    return list.where((m) {
      final ts = m['date'] as Timestamp?;
      if (ts == null) return false;
      return inRange(ts.toDate());
    }).toList();
  }
}
