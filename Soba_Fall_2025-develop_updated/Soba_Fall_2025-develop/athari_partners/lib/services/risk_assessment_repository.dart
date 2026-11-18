import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth_config.dart';
import 'risk_assessment_session_cache.dart';

/// Persists Step 4 risks on `yearOnePlan/riskAssessment` as a `risks` array
/// (avoids nested subcollections blocked by one-level Firestore rules).
class RiskAssessmentRepository {
  RiskAssessmentRepository._();

  static DocumentReference<Map<String, dynamic>> _docRef(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('riskAssessment');
  }

  static List<Map<String, dynamic>> _parseRiskList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => (item['desc'] ?? '').toString().trim().isNotEmpty)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> loadRisks(String companyId) async {
    if (skipFirebasePersistence) return RiskAssessmentSessionCache.risks;

    final snap = await _docRef(companyId).get();
    return _parseRiskList(snap.data()?['risks'])
        .map((risk) => {...risk, 'id': (risk['id'] ?? '').toString()})
        .where((risk) => risk['id'].toString().isNotEmpty)
        .toList();
  }

  static Future<void> addRisk({
    required String companyId,
    required Map<String, dynamic> riskData,
  }) async {
    if (skipFirebasePersistence) {
      RiskAssessmentSessionCache.addRisk(riskData);
      return;
    }

    final ref = _docRef(companyId);
    final id = FirebaseFirestore.instance.collection('_').doc().id;
    final snap = await ref.get();
    final existing = _parseRiskList(snap.data()?['risks']);

    await ref.set(
      {
        'risks': [
          ...existing,
          {...riskData, 'id': id},
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> removeRisk({
    required String companyId,
    required String riskId,
  }) async {
    if (skipFirebasePersistence) {
      RiskAssessmentSessionCache.removeRisk(riskId);
      return;
    }

    final ref = _docRef(companyId);
    final snap = await ref.get();
    final existing = _parseRiskList(snap.data()?['risks']);
    final updated = existing
        .where((risk) => (risk['id'] ?? '').toString() != riskId)
        .toList();

    await ref.set(
      {
        'risks': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
