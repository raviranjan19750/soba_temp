import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:athari_partners/strategic_area_catalog.dart';

/// Step 2 synthesis outputs shown on the Strategic Areas tab.
class ManagementDiscussionSummary {
  const ManagementDiscussionSummary({
    required this.gapsAndOpportunities,
  });

  final List<String> gapsAndOpportunities;

  bool get hasContent =>
      gapsAndOpportunities.any((entry) => entry.trim().isNotEmpty);
}

class StrategicAreaSuggestionResult {
  const StrategicAreaSuggestionResult({
    required this.suggestedTitles,
    required this.managementDiscussion,
    required this.assessmentTextSample,
  });

  final Set<String> suggestedTitles;
  final ManagementDiscussionSummary managementDiscussion;

  /// Concatenated assessment text used for keyword matching (for debugging/UI).
  final String assessmentTextSample;
}

class StrategicAreaSuggestions {
  static Future<StrategicAreaSuggestionResult> load({
    required String? companyId,
    required bool fetchFromFirestore,
  }) async {
    if (!fetchFromFirestore || companyId == null || companyId.isEmpty) {
      return const StrategicAreaSuggestionResult(
        suggestedTitles: {},
        managementDiscussion: ManagementDiscussionSummary(gapsAndOpportunities: []),
        assessmentTextSample: '',
      );
    }

    final assessmentRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('companyAssessment');

    final results = await Future.wait([
      assessmentRef.doc('management_discussion_output').get(),
      assessmentRef.doc('swot_analysis').get(),
      assessmentRef.doc('external_assessment').get(),
      assessmentRef.doc('historical_financials').get(),
    ]);

    final mgmtData = results[0].data() ?? {};
    final gaps = [
      (mgmtData['output_1'] ?? '').toString(),
      (mgmtData['output_2'] ?? '').toString(),
      (mgmtData['output_3'] ?? '').toString(),
    ];

    final textParts = <String>[
      ...gaps,
      ..._flattenAssessmentDoc(results[1].data()),
      ..._flattenAssessmentDoc(results[2].data()),
      ..._flattenAssessmentDoc(results[3].data()),
    ];

    final combined = textParts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ')
        .toLowerCase();

    return StrategicAreaSuggestionResult(
      suggestedTitles: _matchAreas(combined),
      managementDiscussion: ManagementDiscussionSummary(gapsAndOpportunities: gaps),
      assessmentTextSample: combined,
    );
  }

  static List<String> _flattenAssessmentDoc(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const [];

    final parts = <String>[];
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String) {
        parts.add(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is String) {
            parts.add(item);
          } else if (item is Map) {
            parts.addAll(item.values.map((v) => v?.toString() ?? ''));
          }
        }
      } else if (value is Map) {
        parts.addAll(value.values.map((v) => v?.toString() ?? ''));
      }
    }
    return parts;
  }

  static Set<String> _matchAreas(String combinedLowercaseText) {
    if (combinedLowercaseText.trim().isEmpty) return {};

    final scores = <String, int>{};
    for (final entry in kStrategicAreaSuggestionKeywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (combinedLowercaseText.contains(keyword)) {
          score++;
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    if (scores.isEmpty) return {};

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(4).map((e) => e.key).toSet();
  }
}
