import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth_config.dart';
import 'goals_session_cache.dart';
import 'kpi_dashboard_session_cache.dart';
import 'strategic_areas_repository.dart';
import 'strategic_areas_session_cache.dart';

class DashboardInitiativeStatus {
  DashboardInitiativeStatus._();

  static const notStarted = 'Not Started';
  static const onTrack = 'On Track';
  static const atRisk = 'At Risk';
  static const behind = 'Behind';
  static const complete = 'Complete';
  static const na = 'N/A';

  static const options = [
    notStarted,
    onTrack,
    atRisk,
    behind,
    complete,
    na,
  ];

  static String normalize(String? raw) {
    final value = raw?.trim() ?? '';
    return options.contains(value) ? value : notStarted;
  }
}

class DashboardTrackingRow {
  const DashboardTrackingRow({
    required this.rowId,
    required this.area,
    required this.goal,
    required this.initiativeIndex,
    required this.initiative,
    required this.measures,
    required this.targets,
    required this.owner,
    required this.status,
    required this.q1Target,
    required this.q2Target,
    required this.q3Target,
    required this.q4Target,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.fullYear,
  });

  final String rowId;
  final String area;
  final String goal;
  final int initiativeIndex;
  final String initiative;
  /// Key metric name or definition.
  final String measures;
  /// Legacy annual target; migrated into [q1Target] when empty.
  final String targets;
  final String owner;
  final String status;
  final String q1Target;
  final String q2Target;
  final String q3Target;
  final String q4Target;
  final String q1;
  final String q2;
  final String q3;
  final String q4;
  final String fullYear;

  String quarterTarget(int quarter) => switch (quarter) {
        1 => q1Target,
        2 => q2Target,
        3 => q3Target,
        4 => q4Target,
        _ => '',
      };

  String quarterActual(int quarter) => switch (quarter) {
        1 => q1,
        2 => q2,
        3 => q3,
        4 => q4,
        _ => '',
      };

  /// Fills [fullYear] when empty: sums numeric quarters or joins text values.
  DashboardTrackingRow withComputedYtd() {
    if (fullYear.trim().isNotEmpty) return this;

    final parts = [q1, q2, q3, q4].where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return this;

    final nums = parts.map((p) => double.tryParse(p.trim())).toList();
    if (nums.every((n) => n != null)) {
      final sum = nums.fold<double>(0, (a, b) => a + (b ?? 0));
      final asInt = sum == sum.roundToDouble();
      return copyWith(fullYear: asInt ? sum.round().toString() : sum.toString());
    }

    return copyWith(fullYear: parts.join(' | '));
  }

  DashboardTrackingRow copyWith({
    String? measures,
    String? targets,
    String? owner,
    String? status,
    String? q1Target,
    String? q2Target,
    String? q3Target,
    String? q4Target,
    String? q1,
    String? q2,
    String? q3,
    String? q4,
    String? fullYear,
  }) {
    return DashboardTrackingRow(
      rowId: rowId,
      area: area,
      goal: goal,
      initiativeIndex: initiativeIndex,
      initiative: initiative,
      measures: measures ?? this.measures,
      targets: targets ?? this.targets,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      q1Target: q1Target ?? this.q1Target,
      q2Target: q2Target ?? this.q2Target,
      q3Target: q3Target ?? this.q3Target,
      q4Target: q4Target ?? this.q4Target,
      q1: q1 ?? this.q1,
      q2: q2 ?? this.q2,
      q3: q3 ?? this.q3,
      q4: q4 ?? this.q4,
      fullYear: fullYear ?? this.fullYear,
    );
  }

  Map<String, String> toTrackingMap() => {
        'measures': measures,
        'targets': targets,
        'owner': owner,
        'status': status,
        'q1Target': q1Target,
        'q2Target': q2Target,
        'q3Target': q3Target,
        'q4Target': q4Target,
        'q1': q1,
        'q2': q2,
        'q3': q3,
        'q4': q4,
        'fullYear': fullYear,
      };

  static DashboardTrackingRow fromParts({
    required String rowId,
    required String area,
    required String goal,
    required int initiativeIndex,
    required String initiative,
    Map<String, dynamic>? saved,
  }) {
    final data = saved ?? {};
    String field(String key) => (data[key] ?? '').toString().trim();
    final legacyTarget = field('targets');
    String quarterTargetField(int q) {
      final value = field('q${q}Target');
      if (value.isNotEmpty) return value;
      return legacyTarget;
    }

    return DashboardTrackingRow(
      rowId: rowId,
      area: area,
      goal: goal,
      initiativeIndex: initiativeIndex,
      initiative: initiative,
      measures: field('measures'),
      targets: legacyTarget,
      owner: field('owner'),
      status: DashboardInitiativeStatus.normalize(field('status')),
      q1Target: quarterTargetField(1),
      q2Target: quarterTargetField(2),
      q3Target: quarterTargetField(3),
      q4Target: quarterTargetField(4),
      q1: field('q1'),
      q2: field('q2'),
      q3: field('q3'),
      q4: field('q4'),
      fullYear: field('fullYear'),
    );
  }
}

/// Calendar quarter (1–4) from the current date.
int dashboardCurrentQuarter([DateTime? date]) {
  final month = (date ?? DateTime.now()).month;
  return ((month - 1) ~/ 3) + 1;
}

class DashboardAreaGroup {
  const DashboardAreaGroup({
    required this.area,
    required this.goal,
    required this.rows,
  });

  final String area;
  final String goal;
  final List<DashboardTrackingRow> rows;
}

class KpiDashboardTrackingService {
  static String rowId(String area, int initiativeIndex) =>
      '${_slug(area)}_init$initiativeIndex';

  static String _slug(String area) =>
      area.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

  static Future<List<DashboardAreaGroup>> loadGroups(String? companyId) async {
    if (companyId == null || companyId.isEmpty) return const [];

    final areas = skipFirebasePersistence
        ? StrategicAreasSessionCache.areas
        : await StrategicAreasRepository.loadAreas(companyId, readOnly: true);
    final goalsByArea = skipFirebasePersistence
        ? GoalsSessionCache.perAreaGoals
        : await StrategicAreasRepository.loadPerAreaGoals(companyId, readOnly: true);
    final tracking = await _loadTrackingMap(companyId);

    if (areas.isEmpty) return const [];

    final groups = <DashboardAreaGroup>[];
    for (final area in areas) {
      final goals = goalsByArea[area];
      final goalText = goals?.goal.trim() ?? '';
      final initiatives = goals?.initiatives ?? const <String>[];
      final rows = <DashboardTrackingRow>[];

      for (var i = 0; i < 3; i++) {
        final initiative = i < initiatives.length ? initiatives[i].trim() : '';
        final id = rowId(area, i + 1);
        rows.add(
          DashboardTrackingRow.fromParts(
            rowId: id,
            area: area,
            goal: goalText.isEmpty ? '—' : goalText,
            initiativeIndex: i + 1,
            initiative: initiative.isEmpty ? 'Initiative ${i + 1}' : initiative,
            saved: tracking[id],
          ),
        );
      }

      groups.add(
        DashboardAreaGroup(
          area: area,
          goal: goalText.isEmpty ? '—' : goalText,
          rows: rows,
        ),
      );
    }

    return groups;
  }

  static Future<Map<String, Map<String, dynamic>>> _loadTrackingMap(
    String companyId,
  ) async {
    if (skipFirebasePersistence) {
      return KpiDashboardSessionCache.initiativeTracking;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('executeAndMonitor')
          .doc('kpisAndDashboard')
          .get();
      final raw = snap.data()?['initiativeTracking'];
      if (raw is! Map) return {};

      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map
              ? Map<String, dynamic>.from(value)
              : <String, dynamic>{},
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveGroups(
    String companyId,
    List<DashboardAreaGroup> groups,
  ) async {
    final tracking = <String, Map<String, String>>{};
    for (final group in groups) {
      for (final row in group.rows) {
        tracking[row.rowId] = row.toTrackingMap();
      }
    }

    if (skipFirebasePersistence) {
      KpiDashboardSessionCache.saveInitiativeTracking(tracking);
      return;
    }

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('kpisAndDashboard')
        .set({'initiativeTracking': tracking}, SetOptions(merge: true));
  }
}
