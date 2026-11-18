import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth_config.dart';
import 'cascade_plan_session_cache.dart';
import 'goals_session_cache.dart';
import 'kpi_dashboard_tracking.dart';
import 'risk_assessment_repository.dart';
import 'risk_assessment_session_cache.dart';
import 'strategic_areas_repository.dart';
import 'strategic_areas_session_cache.dart';

class CascadeDepartment {
  const CascadeDepartment({required this.key, required this.label});

  final String key;
  final String label;

  static const defaults = [
    CascadeDepartment(key: 'sales', label: 'Sales'),
    CascadeDepartment(key: 'marketing', label: 'Marketing'),
    CascadeDepartment(key: 'product', label: 'Product'),
    CascadeDepartment(key: 'operations', label: 'Operations'),
    CascadeDepartment(key: 'finance', label: 'Finance'),
    CascadeDepartment(key: 'hr', label: 'HR & Talent'),
  ];
}

class CascadeSubInitiative {
  const CascadeSubInitiative({required this.text, required this.status});

  final String text;
  final String status;

  CascadeSubInitiative copyWith({String? text, String? status}) {
    return CascadeSubInitiative(
      text: text ?? this.text,
      status: status ?? this.status,
    );
  }

  Map<String, String> toMap() => {'text': text, 'status': status};

  static CascadeSubInitiative fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return const CascadeSubInitiative(
        text: '',
        status: DashboardInitiativeStatus.notStarted,
      );
    }
    return CascadeSubInitiative(
      text: (raw['text'] ?? '').toString().trim(),
      status: DashboardInitiativeStatus.normalize(
        (raw['status'] ?? '').toString(),
      ),
    );
  }
}

class CascadeAreaPlan {
  const CascadeAreaPlan({
    required this.area,
    required this.companyGoal,
    required this.companyInitiatives,
    required this.subInitiatives,
  });

  final String area;
  final String companyGoal;
  final List<String> companyInitiatives;
  final List<CascadeSubInitiative> subInitiatives;

  String get rollupStatus => CascadePlanRepository.rollupStatus(subInitiatives);

  bool get hasContent =>
      companyGoal.trim().isNotEmpty ||
      companyInitiatives.isNotEmpty ||
      subInitiatives.any((i) => i.text.trim().isNotEmpty);
}

class DepartmentCascadePlan {
  const DepartmentCascadePlan({
    required this.department,
    required this.headName,
    required this.areas,
    required this.riskPlan,
  });

  final CascadeDepartment department;
  final String headName;
  final List<CascadeAreaPlan> areas;
  final CascadeAreaPlan riskPlan;

  Iterable<CascadeSubInitiative> get _allSubInitiatives =>
      [...areas.expand((a) => a.subInitiatives), ...riskPlan.subInitiatives];

  String get rollupStatus => CascadePlanRepository.rollupStatus(_allSubInitiatives);

  int get onTrackCount => _countStatus(DashboardInitiativeStatus.onTrack);
  int get atRiskCount => _countStatus(DashboardInitiativeStatus.atRisk) +
      _countStatus(DashboardInitiativeStatus.behind);
  int get definedCount =>
      _allSubInitiatives.where((i) => i.text.trim().isNotEmpty).length;

  int _countStatus(String status) => _allSubInitiatives
      .where((i) => i.text.trim().isNotEmpty && i.status == status)
      .length;
}

class CascadePlanData {
  const CascadePlanData({
    required this.strategicAreas,
    required this.departments,
    required this.companyRisks,
  });

  final List<String> strategicAreas;
  final List<DepartmentCascadePlan> departments;
  final List<Map<String, dynamic>> companyRisks;
}

class CascadePlanRepository {
  CascadePlanRepository._();

  static const _subInitiativeSlots = 3;

  /// Storage key for risk mitigation sub-initiatives (separate from Step 3 areas).
  static const riskAreaKey = '__risk__';

  /// Column label in the cascade status matrix.
  static const riskAreaLabel = 'Risk';

  static List<String> companyRisksAsInitiatives(
    List<Map<String, dynamic>> risks,
  ) {
    return risks
        .map((risk) {
          final desc = (risk['desc'] ?? '').toString().trim();
          if (desc.isEmpty) return '';
          final severity = (risk['severity'] ?? '').toString().trim();
          final area = (risk['strategicArea'] ?? '').toString().trim();
          final parts = <String>[desc];
          if (severity.isNotEmpty) parts.add('$severity severity');
          if (area.isNotEmpty) parts.add('Linked: $area');
          return parts.join(' · ');
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static CascadeAreaPlan buildRiskPlan({
    required List<Map<String, dynamic>> companyRisks,
    required List<CascadeSubInitiative> subInitiatives,
  }) {
    final riskLines = companyRisksAsInitiatives(companyRisks);
    return CascadeAreaPlan(
      area: riskAreaLabel,
      companyGoal: riskLines.isEmpty
          ? 'No risks documented in Step 4 (optional)'
          : '${riskLines.length} risk${riskLines.length == 1 ? '' : 's'} from Step 4',
      companyInitiatives: riskLines,
      subInitiatives: subInitiatives,
    );
  }

  static Future<List<Map<String, dynamic>>> _loadCompanyRisks(
    String? companyId,
  ) async {
    if (companyId == null || companyId.isEmpty) return const [];
    if (skipFirebasePersistence) return RiskAssessmentSessionCache.risks;
    return RiskAssessmentRepository.loadRisks(companyId);
  }

  static DocumentReference<Map<String, dynamic>> _docRef(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('cascadePlan');
  }

  static String rollupStatus(Iterable<CascadeSubInitiative> items) {
    final defined = items.where((i) => i.text.trim().isNotEmpty).toList();
    if (defined.isEmpty) return DashboardInitiativeStatus.notStarted;

    final applicable = defined
        .where((i) => i.status != DashboardInitiativeStatus.na)
        .toList();
    if (applicable.isEmpty) return DashboardInitiativeStatus.na;

    if (applicable.every((i) => i.status == DashboardInitiativeStatus.complete)) {
      return DashboardInitiativeStatus.complete;
    }
    if (applicable.any((i) => i.status == DashboardInitiativeStatus.behind)) {
      return DashboardInitiativeStatus.behind;
    }
    if (applicable.any((i) => i.status == DashboardInitiativeStatus.atRisk)) {
      return DashboardInitiativeStatus.atRisk;
    }
    if (applicable.every((i) => i.status == DashboardInitiativeStatus.onTrack)) {
      return DashboardInitiativeStatus.onTrack;
    }
    return DashboardInitiativeStatus.notStarted;
  }

  static List<CascadeSubInitiative> _parseSubInitiatives(Object? raw) {
    if (raw is! List) {
      return List.generate(
        _subInitiativeSlots,
        (_) => const CascadeSubInitiative(
          text: '',
          status: DashboardInitiativeStatus.notStarted,
        ),
      );
    }
    final parsed = raw
        .whereType<Map>()
        .map((e) => CascadeSubInitiative.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    while (parsed.length < _subInitiativeSlots) {
      parsed.add(
        const CascadeSubInitiative(
          text: '',
          status: DashboardInitiativeStatus.notStarted,
        ),
      );
    }
    return parsed.take(_subInitiativeSlots).toList();
  }

  static Future<CascadePlanData> load(String? companyId) async {
    final areas = companyId == null
        ? const <String>[]
        : skipFirebasePersistence
            ? StrategicAreasSessionCache.areas
            : await StrategicAreasRepository.loadAreas(companyId, readOnly: true);

    final goalsByArea = companyId == null
        ? const <String, AreaGoalsData>{}
        : skipFirebasePersistence
            ? GoalsSessionCache.perAreaGoals
            : await StrategicAreasRepository.loadPerAreaGoals(
                companyId,
                readOnly: true,
              );

    final companyRisks = await _loadCompanyRisks(companyId);

    Map<String, dynamic> doc = {};
    if (companyId != null && companyId.isNotEmpty) {
      doc = await _loadDoc(companyId);
    }

    final cascadeByDept = _parseCascadeByDept(doc['cascadeByDept']);
    final departments = CascadeDepartment.defaults.map((dept) {
      final headField = '${dept.key}_headName';
      final headName = skipFirebasePersistence
          ? (CascadePlanSessionCache.headNames[dept.key] ?? '')
          : (doc[headField] ?? CascadePlanSessionCache.headNames[dept.key] ?? '')
              .toString()
              .trim();

      final deptAreas = cascadeByDept[dept.key] ?? {};
      final areaPlans = areas.map((area) {
        final goals = goalsByArea[area];
        final companyGoal = goals?.goal.trim() ?? '';
        final companyInitiatives = goals?.initiatives
                .where((i) => i.trim().isNotEmpty)
                .toList() ??
            const <String>[];

        return CascadeAreaPlan(
          area: area,
          companyGoal: companyGoal,
          companyInitiatives: companyInitiatives,
          subInitiatives: _parseSubInitiatives(deptAreas[area]),
        );
      }).toList();

      return DepartmentCascadePlan(
        department: dept,
        headName: headName,
        areas: areaPlans,
        riskPlan: buildRiskPlan(
          companyRisks: companyRisks,
          subInitiatives: _parseSubInitiatives(deptAreas[riskAreaKey]),
        ),
      );
    }).toList();

    return CascadePlanData(
      strategicAreas: areas,
      departments: departments,
      companyRisks: companyRisks,
    );
  }

  static Future<Map<String, dynamic>> _loadDoc(String companyId) async {
    if (skipFirebasePersistence) {
      return {
        for (final d in CascadeDepartment.defaults)
          '${d.key}_headName': CascadePlanSessionCache.headNames[d.key] ?? '',
        'cascadeByDept': CascadePlanSessionCache.cascadeByDept,
      };
    }

    try {
      final snap = await _docRef(companyId).get();
      if (snap.exists && snap.data() != null) return snap.data()!;

      // Legacy nested doc for department head names.
      final legacy = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('executeAndMonitor')
          .doc('cascadePlan')
          .collection('departmentsCollection')
          .doc('departments')
          .get();
      return legacy.data() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Map<String, Map<String, List<Map<String, String>>>> _parseCascadeByDept(
    Object? raw,
  ) {
    if (raw is! Map) return {};
    return raw.map((deptKey, areaValue) {
      if (areaValue is! Map) {
        return MapEntry(deptKey.toString(), <String, List<Map<String, String>>>{});
      }
      final areas = areaValue.map((areaKey, listValue) {
        final items = _parseSubInitiatives(listValue)
            .map((i) => i.toMap())
            .toList();
        return MapEntry(areaKey.toString(), items);
      });
      return MapEntry(deptKey.toString(), areas);
    });
  }

  static Map<String, Map<String, List<Map<String, String>>>> _encodeCascadeByDept(
    List<DepartmentCascadePlan> departments,
    List<String> strategicAreas,
  ) {
    final result = <String, Map<String, List<Map<String, String>>>>{};
    for (final dept in departments) {
      final areaMap = <String, List<Map<String, String>>>{};
      for (final area in strategicAreas) {
        final plan = dept.areas.firstWhere(
          (a) => a.area == area,
          orElse: () => CascadeAreaPlan(
            area: area,
            companyGoal: '',
            companyInitiatives: const [],
            subInitiatives: const [],
          ),
        );
        areaMap[area] = plan.subInitiatives.map((i) => i.toMap()).toList();
      }
      areaMap[riskAreaKey] =
          dept.riskPlan.subInitiatives.map((i) => i.toMap()).toList();
      result[dept.department.key] = areaMap;
    }
    return result;
  }

  static Future<void> save({
    required String companyId,
    required List<DepartmentCascadePlan> departments,
    required List<String> strategicAreas,
  }) async {
    final heads = {
      for (final d in departments) '${d.department.key}_headName': d.headName,
    };
    final cascadeByDept = _encodeCascadeByDept(departments, strategicAreas);

    if (skipFirebasePersistence) {
      CascadePlanSessionCache.update(heads: heads, cascade: cascadeByDept);
      return;
    }

    await _docRef(companyId).set(
      {
        ...heads,
        'cascadeByDept': cascadeByDept,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
