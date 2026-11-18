import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth_config.dart';
import 'goals_session_cache.dart';
import 'strategic_areas_repository.dart';
import 'strategic_areas_session_cache.dart';
import 'year3_targets_session_cache.dart';

class KpiMetricTile {
  const KpiMetricTile({
    required this.title,
    required this.value,
    required this.deltaText,
    required this.deltaPositive,
    required this.sublabel,
    this.pillStyle = false,
  });

  final String title;
  final String value;
  final String deltaText;
  final bool deltaPositive;
  final String sublabel;
  final bool pillStyle;
}

class KpiGoalRow {
  const KpiGoalRow({
    required this.area,
    required this.goal,
    required this.initiatives,
  });

  final String area;
  final String goal;
  final List<String> initiatives;
}

class KpiInitiativeRow {
  const KpiInitiativeRow({
    required this.area,
    required this.initiative,
    required this.index,
  });

  final String area;
  final String initiative;
  final int index;
}

class KpiDashboardSnapshot {
  const KpiDashboardSnapshot({
    required this.tiles,
    required this.goalRows,
    required this.initiativeRows,
    required this.currentYear,
  });

  final List<KpiMetricTile> tiles;
  final List<KpiGoalRow> goalRows;
  final List<KpiInitiativeRow> initiativeRows;
  final int currentYear;

  static KpiDashboardSnapshot empty() {
    final year = DateTime.now().year;
    return KpiDashboardSnapshot(
      currentYear: year,
      tiles: const [
        KpiMetricTile(
          title: 'Revenue YTD',
          value: '—',
          deltaText: 'Set targets',
          deltaPositive: true,
          sublabel: 'Add Year 1 targets in Step 3',
        ),
        KpiMetricTile(
          title: 'EBITDA YTD',
          value: '—',
          deltaText: 'Set targets',
          deltaPositive: true,
          sublabel: 'Add Year 1 targets in Step 3',
        ),
        KpiMetricTile(
          title: 'Strategic Goals',
          value: '0',
          deltaText: 'Pending',
          deltaPositive: false,
          sublabel: 'Save goals in Step 4',
        ),
        KpiMetricTile(
          title: 'Strategic Initiatives',
          value: '0/0',
          deltaText: 'Pending',
          deltaPositive: false,
          sublabel: 'Add initiatives in Step 4',
          pillStyle: true,
        ),
      ],
      goalRows: const [],
      initiativeRows: const [],
    );
  }
}

class KpiDashboardDataService {
  static Future<KpiDashboardSnapshot> load(String? companyId) async {
    if (companyId == null || companyId.isEmpty) {
      return KpiDashboardSnapshot.empty();
    }

    try {
      if (skipFirebasePersistence) {
        return _buildFromSessionCaches();
      }
      return await _buildFromFirestore(companyId);
    } catch (_) {
      return KpiDashboardSnapshot.empty();
    }
  }

  static KpiDashboardSnapshot _buildFromSessionCaches() {
    final areas = StrategicAreasSessionCache.areas;
    final goalsByArea = GoalsSessionCache.perAreaGoals;
    final year3 = {
      'y1R': Year3TargetsSessionCache.y1Revenue,
      'y1E': Year3TargetsSessionCache.y1Ebitda,
    };
    return _buildSnapshot(
      areas: areas,
      goalsByArea: goalsByArea,
      year3: year3,
      revenueYtd: '',
      ebitdaYtd: '',
    );
  }

  static Future<KpiDashboardSnapshot> _buildFromFirestore(String companyId) async {
    final ref = FirebaseFirestore.instance.collection('companies').doc(companyId);
    final year = DateTime.now().year;
    final ytdKey = 'ytd_$year';

    final year3Snap =
        await ref.collection('strategicPlanning').doc('year3_targets').get();
    final historicalSnap = await ref
        .collection('companyAssessment')
        .doc('historical_financials')
        .get();

    final areas = await StrategicAreasRepository.loadAreas(companyId);
    final goalsByArea = await StrategicAreasRepository.loadPerAreaGoals(companyId);

    final year3 = year3Snap.data() ?? {};
    final historical = historicalSnap.data() ?? {};

    final ytdCol = historical[ytdKey];
    final revenueYtd = _readMetric(ytdCol, 'revenue');
    final ebitdaYtd = _readMetric(ytdCol, 'ebitda_dollar');

    return _buildSnapshot(
      areas: areas,
      goalsByArea: goalsByArea,
      year3: year3,
      revenueYtd: revenueYtd,
      ebitdaYtd: ebitdaYtd,
    );
  }

  static KpiDashboardSnapshot _buildSnapshot({
    required List<String> areas,
    required Map<String, AreaGoalsData> goalsByArea,
    required Map<String, dynamic> year3,
    required String revenueYtd,
    required String ebitdaYtd,
  }) {
    final year = DateTime.now().year;
    final year1RevenueTarget = (year3['y1R'] ?? '').toString();
    final year1EbitdaTarget = (year3['y1E'] ?? '').toString();

    var goalsFilled = 0;
    var initiativesFilled = 0;
    var initiativeSlots = 0;
    final goalRows = <KpiGoalRow>[];
    final initiativeRows = <KpiInitiativeRow>[];

    for (final area in areas) {
      final data = goalsByArea[area];
      final goal = data?.goal.trim() ?? '';
      final initiatives = data?.initiatives ?? const [];
      if (goal.isNotEmpty) goalsFilled++;
      initiativeSlots += 3;
      for (var i = 0; i < initiatives.length && i < 3; i++) {
        final text = initiatives[i].trim();
        if (text.isNotEmpty) {
          initiativesFilled++;
          initiativeRows.add(
            KpiInitiativeRow(area: area, initiative: text, index: i + 1),
          );
        }
      }
      if (goal.isNotEmpty || initiatives.any((i) => i.trim().isNotEmpty)) {
        goalRows.add(
          KpiGoalRow(
            area: area,
            goal: goal.isEmpty ? '—' : goal,
            initiatives: initiatives.where((i) => i.trim().isNotEmpty).toList(),
          ),
        );
      }
    }

    final revenueProgress = _progressPct(revenueYtd, year1RevenueTarget);
    final ebitdaProgress = _progressPct(ebitdaYtd, year1EbitdaTarget);
    final initiativeProgress = initiativeSlots == 0
        ? 0
        : ((initiativesFilled / initiativeSlots) * 100).round();

    return KpiDashboardSnapshot(
      currentYear: year,
      tiles: [
        KpiMetricTile(
          title: 'Revenue YTD',
          value: _formatCurrency(revenueYtd),
          deltaText: revenueProgress > 0 ? '$revenueProgress%' : 'YTD',
          deltaPositive: revenueProgress >= 50,
          sublabel: year1RevenueTarget.isEmpty
              ? 'Set Year 1 revenue target in Step 3'
              : '$revenueProgress% of Year 1 target (\$$year1RevenueTarget)',
        ),
        KpiMetricTile(
          title: 'EBITDA YTD',
          value: _formatCurrency(ebitdaYtd),
          deltaText: ebitdaProgress > 0 ? '$ebitdaProgress%' : 'YTD',
          deltaPositive: ebitdaProgress >= 50,
          sublabel: year1EbitdaTarget.isEmpty
              ? 'Set Year 1 EBITDA target in Step 3'
              : '$ebitdaProgress% of Year 1 target (\$$year1EbitdaTarget)',
        ),
        KpiMetricTile(
          title: 'Strategic Goals',
          value: areas.isEmpty ? '0' : '$goalsFilled/${areas.length}',
          deltaText: goalsFilled == areas.length && areas.isNotEmpty
              ? 'Complete'
              : 'In progress',
          deltaPositive: areas.isNotEmpty && goalsFilled == areas.length,
          sublabel: areas.isEmpty
              ? 'Save strategic areas in Step 3'
              : '$goalsFilled goals defined across ${areas.length} areas',
        ),
        KpiMetricTile(
          title: 'Strategic Initiatives',
          value: initiativeSlots == 0
              ? '0/0'
              : '$initiativesFilled/$initiativeSlots',
          deltaText: initiativeProgress >= 70 ? 'On Track' : 'Building',
          deltaPositive: initiativeProgress >= 50,
          sublabel: initiativeSlots == 0
              ? 'Add initiatives in Step 4'
              : '$initiativeProgress% initiative slots filled',
          pillStyle: true,
        ),
      ],
      goalRows: goalRows,
      initiativeRows: initiativeRows,
    );
  }

  static String _readMetric(dynamic column, String key) {
    if (column is! Map) return '';
    return (column[key] ?? '').toString().trim();
  }

  static int _progressPct(String actual, String target) {
    final a = _parseNumber(actual);
    final t = _parseNumber(target);
    if (a == null || t == null || t <= 0) return 0;
    return ((a / t) * 100).clamp(0, 999).round();
  }

  static double? _parseNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }

  static String _formatCurrency(String raw) {
    if (raw.trim().isEmpty) return '—';
    if (raw.contains('\$')) return raw;
    final n = _parseNumber(raw);
    if (n == null) return raw;
    if (n >= 1000000) return '\$${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '\$${(n / 1000).toStringAsFixed(0)}K';
    return '\$${n.toStringAsFixed(0)}';
  }

  static String goalCheckId(String area) =>
      'goal-${area.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}';
}
