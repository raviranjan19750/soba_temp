import 'package:cloud_firestore/cloud_firestore.dart';

import '../strategic_area_catalog.dart';

/// Maps legacy department-style area names to current strategic pillars.
const Map<String, String> kLegacyStrategicAreaMigration = {
  'Management': 'People, Culture & Leadership',
  'Human Resources': 'People, Culture & Leadership',
  'HR': 'People, Culture & Leadership',
  'Human Capital': 'People, Culture & Leadership',
  'Sales & Marketing': 'Revenue & Growth',
  'Sales and Marketing': 'Revenue & Growth',
  'Marketing': 'Brand, Marketing & Communications',
  'Customer Service': 'Customer & Stakeholder Experience',
  'Customer Experience': 'Customer & Stakeholder Experience',
  'Operations': 'Operations & Delivery Excellence',
  'Production': 'Operations & Delivery Excellence',
  'Distribution': 'Supply Chain & Vendor Excellence',
  'Purchasing': 'Supply Chain & Vendor Excellence',
  'Finance': 'Financial Performance & Capital Stewardship',
  'Accounting': 'Financial Performance & Capital Stewardship',
  'IT Support': 'Technology & Digital Enablement',
  'Information Technology': 'Technology & Digital Enablement',
  'Research & Development': 'Innovation & Product/Program Development',
  'Product Development': 'Innovation & Product/Program Development',
  'Market Expansion': 'Revenue & Growth',
  'Fundraising': 'Partnerships, Fundraising & Ecosystem',
  'Legal': 'Risk, Compliance & Governance',
};

String? migrateLegacyStrategicAreaTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return null;
  if (catalogStrategicAreaTitles().contains(trimmed)) return trimmed;
  return kLegacyStrategicAreaMigration[trimmed];
}

List<String> normalizeStrategicAreas(List<String> areas) {
  final seen = <String>{};
  final result = <String>[];
  for (final area in areas) {
    final migrated = migrateLegacyStrategicAreaTitle(area) ?? area.trim();
    if (migrated.isNotEmpty && seen.add(migrated)) {
      result.add(migrated);
    }
  }
  return result;
}

/// Canonical loader for Step 3 strategic areas used across Steps 4–5.
class StrategicAreasRepository {
  static Future<List<String>> loadAreas(
    String? companyId, {
    bool readOnly = false,
  }) async {
    if (companyId == null || companyId.isEmpty) return const [];

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('strategicPlanning')
        .doc('strategic_areas');

    final snap = await docRef.get();

    if (!snap.exists || snap.data() == null) return const [];

    final areas = snap.data()!['areas'];
    if (areas is! List) return const [];

    final raw = areas
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final normalized = normalizeStrategicAreas(raw);
    if (!readOnly && !_listsEqual(raw, normalized)) {
      await docRef.set({'areas': normalized}, SetOptions(merge: true));
    }
    return normalized;
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Goals and initiatives keyed by strategic area from Step 4.
  static Future<Map<String, AreaGoalsData>> loadPerAreaGoals(
    String? companyId, {
    bool readOnly = false,
  }) async {
    if (companyId == null || companyId.isEmpty) return {};

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('goalsAndInitiatives');

    final snap = await docRef.get();

    if (!snap.exists || snap.data() == null) return {};

    final perArea = snap.data()!['perAreaGoals'];
    if (perArea is! Map) return {};

    final result = <String, AreaGoalsData>{};
    final migratedPerArea = <String, dynamic>{};
    var needsMigration = false;

    for (final entry in perArea.entries) {
      final rawKey = entry.key.toString();
      final migratedKey = migrateLegacyStrategicAreaTitle(rawKey) ?? rawKey;
      if (migratedKey != rawKey) needsMigration = true;

      final value = entry.value;
      if (value is! Map) continue;

      final initiativesRaw = value['initiatives'];
      final initiatives = initiativesRaw is List
          ? initiativesRaw.map((e) => e?.toString() ?? '').toList()
          : <String>[];

      final data = AreaGoalsData(
        goal: (value['goal'] ?? '').toString(),
        initiatives: initiatives,
      );

      if (result.containsKey(migratedKey)) {
        final existing = result[migratedKey]!;
        result[migratedKey] = AreaGoalsData(
          goal: existing.goal.trim().isNotEmpty ? existing.goal : data.goal,
          initiatives: [
            ...existing.initiatives,
            ...data.initiatives,
          ].take(3).toList(),
        );
      } else {
        result[migratedKey] = data;
      }

      migratedPerArea[migratedKey] = {
        'goal': result[migratedKey]!.goal,
        'initiatives': result[migratedKey]!.initiatives,
      };
    }

    if (!readOnly && needsMigration) {
      await docRef.set({'perAreaGoals': migratedPerArea}, SetOptions(merge: true));
    }

    return result;
  }

  static int countFilledInitiatives(AreaGoalsData data) =>
      data.initiatives.where((i) => i.trim().isNotEmpty).length;
}

class AreaGoalsData {
  const AreaGoalsData({
    required this.goal,
    required this.initiatives,
  });

  final String goal;
  final List<String> initiatives;

  bool get hasGoal => goal.trim().isNotEmpty;
}
