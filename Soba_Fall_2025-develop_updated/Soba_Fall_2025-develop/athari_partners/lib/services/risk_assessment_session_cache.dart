import 'package:flutter/foundation.dart';

/// In-memory risk list for local dev when Firebase persistence is skipped.
class RiskAssessmentSessionCache {
  RiskAssessmentSessionCache._();

  static final ValueNotifier<List<Map<String, dynamic>>> risksNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static List<Map<String, dynamic>> get risks =>
      List<Map<String, dynamic>>.from(risksNotifier.value);

  static void addRisk(Map<String, dynamic> risk) {
    final id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    risksNotifier.value = [
      ...risksNotifier.value,
      {...risk, 'id': id},
    ];
  }

  static void removeRisk(String id) {
    risksNotifier.value = risksNotifier.value
        .where((r) => r['id']?.toString() != id)
        .toList();
  }

  static void clear() {
    risksNotifier.value = [];
  }
}
