import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_config.dart';
import 'services/company_profile_session_cache.dart';
import 'services/goals_session_cache.dart';
import 'services/identity_session_cache.dart';
import 'services/plan_progress_service.dart';
import 'services/plan_pdf_export.dart';
import 'services/strategic_areas_repository.dart';
import 'services/strategic_areas_session_cache.dart';
import 'services/year3_targets_session_cache.dart';
import 'utils/currency_input.dart';
import 'utils/strategic_area_visuals.dart';

enum _FinancialTargetField { revenue, grossMarginPct, ebitda, ebitdaPct }

class _YearFinancialTargets {
  _YearFinancialTargets({required this.storagePrefix, required this.label});

  final String storagePrefix;
  final String label;
  final TextEditingController revenue = TextEditingController();
  final TextEditingController grossMarginPct = TextEditingController();
  final TextEditingController ebitda = TextEditingController();
  final TextEditingController ebitdaPct = TextEditingController();

  void dispose() {
    revenue.dispose();
    grossMarginPct.dispose();
    ebitda.dispose();
    ebitdaPct.dispose();
  }
}

class VisualizationPlanPage extends StatefulWidget {
  final VoidCallback onSaveAndContinue;

  const VisualizationPlanPage({super.key, required this.onSaveAndContinue});

  @override
  State<VisualizationPlanPage> createState() => _VisualizationPlanPageState();
}

class _VisualizationPlanPageState extends State<VisualizationPlanPage> {
  String? companyId;
  String _companyName = 'Company';
  bool _loading = true;

  final TextEditingController visionController = TextEditingController();
  final TextEditingController missionController = TextEditingController();
  final TextEditingController value1Controller = TextEditingController();
  final TextEditingController value2Controller = TextEditingController();
  final TextEditingController value3Controller = TextEditingController();
  final TextEditingController value4Controller = TextEditingController();

  final _finY3 = _YearFinancialTargets(storagePrefix: 'fin_y3', label: 'Y3');
  final _finY2 = _YearFinancialTargets(storagePrefix: 'fin_y2', label: 'Y2');
  final _finY1 = _YearFinancialTargets(storagePrefix: 'fin_y1', label: 'Y1');
  bool _syncingFinancials = false;

  List<String> _strategicAreas = [];
  final Map<String, TextEditingController> _goalByArea = {};
  final Map<String, List<TextEditingController>> _initiativeByArea = {};
  bool _exportingOnePager = false;
  VoidCallback? _sessionDataListener;

  static const _focusAreaHeaderHeight = 52.0;

  List<_YearFinancialTargets> get _financialYears => [_finY3, _finY2, _finY1];

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
    if (skipFirebasePersistence) {
      _sessionDataListener = () {
        if (mounted && companyId != null) _loadData();
      };
      StrategicAreasSessionCache.areasNotifier
          .addListener(_sessionDataListener!);
      GoalsSessionCache.goalsNotifier.addListener(_sessionDataListener!);
    }
  }

  @override
  void dispose() {
    if (_sessionDataListener != null) {
      StrategicAreasSessionCache.areasNotifier
          .removeListener(_sessionDataListener!);
      GoalsSessionCache.goalsNotifier.removeListener(_sessionDataListener!);
    }
    for (final c in [
      visionController,
      missionController,
      value1Controller,
      value2Controller,
      value3Controller,
      value4Controller,
      ..._goalByArea.values,
      ..._initiativeByArea.values.expand((list) => list),
    ]) {
      c.dispose();
    }
    for (final row in _financialYears) {
      row.dispose();
    }
    super.dispose();
  }

  String _areaGoalKey(String area) => '${area}_goal';
  String _areaInitiativeKey(String area, int index) => '${area}_initiative$index';

  Future<OnePagerPdfData> _buildOnePagerPdfData() async {
    final areaGoals = <String, AreaGoalsData>{};
    for (final area in _strategicAreas) {
      final initiatives = (_initiativeByArea[area] ?? [])
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      areaGoals[area] = AreaGoalsData(
        goal: _goalByArea[area]?.text.trim() ?? '',
        initiatives: initiatives,
      );
    }

    Uint8List? logoBytes = CompanyProfileSessionCache.logoBytes;
    if ((logoBytes == null || logoBytes.isEmpty) && companyId != null) {
      logoBytes = await PlanPdfExport.resolveLogoBytes(companyId: companyId);
    }

    final coreValues = [
      value1Controller.text.trim(),
      value2Controller.text.trim(),
      value3Controller.text.trim(),
      value4Controller.text.trim(),
    ].where((v) => v.isNotEmpty).toList();

    return OnePagerPdfData(
      companyName: _companyName,
      logoBytes: logoBytes,
      vision: visionController.text.trim(),
      mission: missionController.text.trim(),
      coreValues: coreValues,
      financialRows: _financialYears
          .map(
            (row) => OnePagerFinancialRow(
              yearLabel: row.label,
              revenue: row.revenue.text.trim(),
              grossMarginPct: row.grossMarginPct.text.trim(),
              ebitda: row.ebitda.text.trim(),
              ebitdaPct: row.ebitdaPct.text.trim(),
            ),
          )
          .toList(),
      areas: List<String>.from(_strategicAreas),
      areaGoals: areaGoals,
    );
  }

  Future<void> _loadCompanyId() async {
    final resolvedCompanyId = await loadCompanyIdForCurrentUser();
    if (!mounted) return;
    setState(() => companyId = resolvedCompanyId);
    if (resolvedCompanyId != null) {
      await _loadData();
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<String> _parseValues(String valuesStr) {
    return valuesStr
        .split(RegExp(r'[\n,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _initAreaControllers(
    List<String> areas,
    Map<String, AreaGoalsData> goalsByArea,
    Map<String, dynamic> savedVisualization,
  ) {
    for (final c in [
      ..._goalByArea.values,
      ..._initiativeByArea.values.expand((list) => list),
    ]) {
      c.dispose();
    }
    _goalByArea.clear();
    _initiativeByArea.clear();

    for (final area in areas) {
      final goals = goalsByArea[area];
      final savedGoal = (savedVisualization[_areaGoalKey(area)] ?? '').toString();
      final goalText = savedGoal.isNotEmpty
          ? savedGoal
          : (goals?.goal.trim() ?? '');

      _goalByArea[area] = TextEditingController(text: goalText);

      final step4Initiatives = goals?.initiatives ?? const <String>[];
      _initiativeByArea[area] = [
        for (var i = 0; i < 3; i++)
          TextEditingController(
            text: _firstNonEmpty([
              (savedVisualization[_areaInitiativeKey(area, i + 1)] ?? '')
                  .toString(),
              if (i < step4Initiatives.length) step4Initiatives[i],
            ]),
          ),
      ];
    }
  }

  String _firstNonEmpty(List<String> candidates) {
    for (final c in candidates) {
      if (c.trim().isNotEmpty) return c.trim();
    }
    return '';
  }

  Future<String> _resolveCompanyName(String? id) async {
    if (id == null || id.isEmpty) return 'Company';

    if (skipFirebasePersistence) {
      final cached = CompanyProfileSessionCache.companyName.trim();
      if (cached.isNotEmpty) return cached;
      return 'Company';
    }

    try {
      final companySnap =
          await FirebaseFirestore.instance.collection('companies').doc(id).get();
      final fromCompany =
          (companySnap.data()?['companyName'] ?? '').toString().trim();
      if (fromCompany.isNotEmpty) return fromCompany;
    } catch (_) {
      // Fall through to default when Firestore is unavailable.
    }

    return 'Company';
  }

  Future<void> _loadData() async {
    if (companyId == null) return;

    if (mounted) setState(() => _loading = true);

    try {
      Map<String, dynamic> identity = {};
      Map<String, dynamic> year3 = {};
      Map<String, dynamic> savedVisualization = {};
      Map<String, AreaGoalsData> goalsByArea = {};

      if (skipFirebasePersistence) {
      _strategicAreas = StrategicAreasSessionCache.areas;
      goalsByArea = GoalsSessionCache.perAreaGoals;
      identity = {
        'vision_str': IdentitySessionCache.vision,
        'mission_str': IdentitySessionCache.mission,
        'values_str': IdentitySessionCache.values,
      };
      year3 = {
        'y3R': Year3TargetsSessionCache.y3Revenue,
        'y3G': Year3TargetsSessionCache.y3GrossMargin,
        'y3E': Year3TargetsSessionCache.y3Ebitda,
        'y3M': Year3TargetsSessionCache.y3Margin,
        'y2R': Year3TargetsSessionCache.y2Revenue,
        'y2G': Year3TargetsSessionCache.y2GrossMargin,
        'y2E': Year3TargetsSessionCache.y2Ebitda,
        'y2M': Year3TargetsSessionCache.y2Margin,
        'y1R': Year3TargetsSessionCache.y1Revenue,
        'y1G': Year3TargetsSessionCache.y1GrossMargin,
        'y1E': Year3TargetsSessionCache.y1Ebitda,
        'y1M': Year3TargetsSessionCache.y1Margin,
      };
    } else {
      _strategicAreas = await StrategicAreasRepository.loadAreas(companyId, readOnly: true);
      goalsByArea = await StrategicAreasRepository.loadPerAreaGoals(companyId, readOnly: true);

      final companyRef =
          FirebaseFirestore.instance.collection('companies').doc(companyId);

      final identitySnap = await companyRef
          .collection('companyIdentity')
          .doc('refine_company_identity')
          .get();
      identity = identitySnap.data() ?? {};

      final year3Snap = await companyRef
          .collection('strategicPlanning')
          .doc('year3_targets')
          .get();
      year3 = year3Snap.data() ?? {};

      final docSnap = await companyRef
          .collection('executeAndMonitor')
          .doc('visualization')
          .get();
      savedVisualization = docSnap.data() ?? {};
    }

    visionController.text = _firstNonEmpty([
      (savedVisualization['vision'] ?? '').toString(),
      (identity['vision_str'] ?? '').toString(),
    ]);
    missionController.text = _firstNonEmpty([
      (savedVisualization['mission'] ?? '').toString(),
      (identity['mission_str'] ?? '').toString(),
    ]);

    _applyFinancialRow(
      row: _finY3,
      saved: savedVisualization,
      year3: year3,
      revKey: 'y3R',
      grossKey: 'y3G',
      ebitdaKey: 'y3E',
      marginKey: 'y3M',
      legacyRevKey: 'revenue',
      legacyEbitdaKey: 'ebitda',
    );
    _applyFinancialRow(
      row: _finY2,
      saved: savedVisualization,
      year3: year3,
      revKey: 'y2R',
      grossKey: 'y2G',
      ebitdaKey: 'y2E',
      marginKey: 'y2M',
    );
    _applyFinancialRow(
      row: _finY1,
      saved: savedVisualization,
      year3: year3,
      revKey: 'y1R',
      grossKey: 'y1G',
      ebitdaKey: 'y1E',
      marginKey: 'y1M',
      legacyRevKey: 'year1_revenue',
      legacyEbitdaKey: 'year1_ebitda',
    );

    final values = _parseValues((identity['values_str'] ?? '').toString());
    value1Controller.text = _firstNonEmpty([
      (savedVisualization['value1'] ?? '').toString(),
      if (values.isNotEmpty) values[0],
    ]);
    value2Controller.text = _firstNonEmpty([
      (savedVisualization['value2'] ?? '').toString(),
      if (values.length > 1) values[1],
    ]);
    value3Controller.text = _firstNonEmpty([
      (savedVisualization['value3'] ?? '').toString(),
      if (values.length > 2) values[2],
    ]);
    value4Controller.text = _firstNonEmpty([
      (savedVisualization['value4'] ?? '').toString(),
      if (values.length > 3) values[3],
    ]);

    _initAreaControllers(_strategicAreas, goalsByArea, savedVisualization);
    _companyName = await _resolveCompanyName(companyId);

    if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.text = text;
  }

  void _applyFinancialRow({
    required _YearFinancialTargets row,
    required Map<String, dynamic> saved,
    required Map<String, dynamic> year3,
    required String revKey,
    required String grossKey,
    required String ebitdaKey,
    required String marginKey,
    String? legacyRevKey,
    String? legacyEbitdaKey,
  }) {
    row.revenue.text = _firstNonEmpty([
      (saved['${row.storagePrefix}_revenue'] ?? '').toString(),
      if (legacyRevKey != null) (saved[legacyRevKey] ?? '').toString(),
      (year3[revKey] ?? '').toString(),
    ]);
    row.grossMarginPct.text = _firstNonEmpty([
      (saved['${row.storagePrefix}_gross_margin_pct'] ?? '').toString(),
      (year3[grossKey] ?? '').toString(),
    ]);
    row.ebitda.text = _firstNonEmpty([
      (saved['${row.storagePrefix}_ebitda'] ?? '').toString(),
      if (legacyEbitdaKey != null) (saved[legacyEbitdaKey] ?? '').toString(),
      (year3[ebitdaKey] ?? '').toString(),
    ]);
    row.ebitdaPct.text = _firstNonEmpty([
      (saved['${row.storagePrefix}_ebitda_pct'] ?? '').toString(),
      (year3[marginKey] ?? '').toString(),
    ]);

    final revenue = parseCurrency(row.revenue.text);
    final ebitda = parseCurrency(row.ebitda.text);
    if (row.ebitdaPct.text.trim().isEmpty &&
        revenue != null &&
        revenue > 0 &&
        ebitda != null &&
        ebitda > 0) {
      row.ebitdaPct.text = formatPercentDisplay((ebitda / revenue) * 100);
    }
  }

  void _onFinancialFieldChanged(
    _YearFinancialTargets row,
    _FinancialTargetField source,
  ) {
    if (_syncingFinancials) return;

    _syncingFinancials = true;
    try {
      final revenue = parseCurrency(row.revenue.text);
      final ebitda = parseCurrency(row.ebitda.text);
      final ebitdaPct = parsePercent(row.ebitdaPct.text);

      switch (source) {
        case _FinancialTargetField.revenue:
          if (revenue != null && revenue > 0) {
            if (ebitdaPct != null && ebitdaPct > 0) {
              _setControllerText(
                row.ebitda,
                formatCurrencyDisplay(revenue * ebitdaPct / 100),
              );
            } else if (ebitda != null && ebitda > 0) {
              _setControllerText(
                row.ebitdaPct,
                formatPercentDisplay((ebitda / revenue) * 100),
              );
            }
          }
          break;
        case _FinancialTargetField.ebitda:
          if (revenue != null && revenue > 0 && ebitda != null && ebitda >= 0) {
            _setControllerText(
              row.ebitdaPct,
              formatPercentDisplay((ebitda / revenue) * 100),
            );
          }
          break;
        case _FinancialTargetField.ebitdaPct:
          if (revenue != null &&
              revenue > 0 &&
              ebitdaPct != null &&
              ebitdaPct >= 0) {
            _setControllerText(
              row.ebitda,
              formatCurrencyDisplay(revenue * ebitdaPct / 100),
            );
          }
          break;
        case _FinancialTargetField.grossMarginPct:
          break;
      }
    } finally {
      _syncingFinancials = false;
    }
  }

  Future<void> _saveFinancialRow(_YearFinancialTargets row) async {
    await _saveFields({
      '${row.storagePrefix}_revenue': row.revenue.text,
      '${row.storagePrefix}_gross_margin_pct': row.grossMarginPct.text,
      '${row.storagePrefix}_ebitda': row.ebitda.text,
      '${row.storagePrefix}_ebitda_pct': row.ebitdaPct.text,
    });
  }

  Future<void> _saveField(String key, String value) async {
    if (skipFirebasePersistence || companyId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('visualization');
    await docRef.set(
      {key: value, 'strategicAreas': _strategicAreas},
      SetOptions(merge: true),
    );
  }

  Future<void> _saveFields(Map<String, String> fields) async {
    if (skipFirebasePersistence || companyId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('visualization');
    await docRef.set(
      {...fields, 'strategicAreas': _strategicAreas},
      SetOptions(merge: true),
    );
  }

  Widget _financialTargetsTable() {
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF374151),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final yearWidth = constraints.maxWidth > 720 ? 56.0 : 48.0;
        return Table(
          columnWidths: {
            0: FixedColumnWidth(yearWidth),
            1: const FlexColumnWidth(2),
            2: const FlexColumnWidth(1.5),
            3: const FlexColumnWidth(2),
            4: const FlexColumnWidth(1.5),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              children: [
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Rev \$', style: headerStyle),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Gross Margin %', style: headerStyle),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('EBITDA \$', style: headerStyle),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('EBITDA %', style: headerStyle),
                ),
              ],
            ),
            for (final row in _financialYears)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 10),
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _financialCurrencyCell(
                    row,
                    row.revenue,
                    _FinancialTargetField.revenue,
                  ),
                  _financialPercentCell(
                    row,
                    row.grossMarginPct,
                    _FinancialTargetField.grossMarginPct,
                  ),
                  _financialCurrencyCell(
                    row,
                    row.ebitda,
                    _FinancialTargetField.ebitda,
                  ),
                  _financialPercentCell(
                    row,
                    row.ebitdaPct,
                    _FinancialTargetField.ebitdaPct,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _financialCurrencyCell(
    _YearFinancialTargets row,
    TextEditingController controller,
    _FinancialTargetField field,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) _saveFinancialRow(row);
        },
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (_) => _onFinancialFieldChanged(row, field),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '0.00',
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            prefixText: '\$ ',
            prefixStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _financialPercentCell(
    _YearFinancialTargets row,
    TextEditingController controller,
    _FinancialTargetField field,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) _saveFinancialRow(row);
        },
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [PercentInputFormatter()],
          onChanged: (_) => _onFinancialFieldChanged(row, field),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '0.00',
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            suffixText: '%',
            suffixStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _editableBox(
    TextEditingController controller,
    String placeholder, {
    String? firestoreKey,
    bool compact = false,
    double? fixedHeight,
  }) {
    final textField = TextField(
      controller: controller,
      expands: fixedHeight != null,
      maxLines: fixedHeight != null ? null : null,
      minLines: fixedHeight != null ? null : null,
      textAlignVertical:
          fixedHeight != null ? TextAlignVertical.top : TextAlignVertical.center,
      style: TextStyle(
        fontSize: compact ? 12 : 14,
        color: compact ? Colors.black : null,
        height: compact ? 1.35 : null,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          fontSize: compact ? 11 : 14,
          color: compact ? Colors.black38 : null,
        ),
        filled: true,
        fillColor: compact ? Colors.white.withValues(alpha: 0.65) : Colors.grey.shade200,
        contentPadding: EdgeInsets.all(compact ? 8 : 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 4 : 6),
          borderSide: BorderSide.none,
        ),
      ),
    );

    final input = Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && firestoreKey != null) {
          _saveField(firestoreKey, controller.text);
        }
      },
      child: textField,
    );

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: fixedHeight != null
          ? SizedBox(height: fixedHeight, child: input)
          : input,
    );
  }

  double _initiativeBoxInnerWidth(double columnOuterWidth) {
    const sectionHorizontalPadding = 24.0;
    const checkmarkColumnWidth = 22.0;
    return math.max(80, columnOuterWidth - sectionHorizontalPadding - checkmarkColumnWidth);
  }

  double _measureInitiativeBoxHeight(String text, double innerWidth) {
    const textStyle = TextStyle(fontSize: 12, height: 1.35);
    const verticalPadding = 16.0;

    final painter = TextPainter(
      text: TextSpan(
        text: text.trim().isEmpty ? ' ' : text,
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerWidth);

    return math.max(40.0, painter.size.height + verticalPadding);
  }

  double _uniformInitiativeBoxHeight(double columnOuterWidth) {
    final innerWidth = _initiativeBoxInnerWidth(columnOuterWidth);
    var maxHeight = _measureInitiativeBoxHeight('', innerWidth);
    for (final area in _strategicAreas) {
      for (final controller in _initiativeByArea[area] ?? const []) {
        maxHeight = math.max(
          maxHeight,
          _measureInitiativeBoxHeight(controller.text, innerWidth),
        );
      }
    }
    return maxHeight;
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Color? color,
    bool expanded = true,
    bool stretchBody = false,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: stretchBody ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (stretchBody)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            )
          else
            ...children,
        ],
      ),
    );
    return expanded ? Expanded(child: card) : card;
  }

  Widget _subLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _focusAreaColumn(
    String area, {
    double? width,
    required double initiativeBoxHeight,
  }) {
    final goal = _goalByArea[area]!;
    final initiatives = _initiativeByArea[area]!;
    final theme = strategicAreaVisualTheme(area);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _focusAreaHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: Border.all(color: theme.headerColor.withValues(alpha: 0.85)),
            ),
            child: Text(
              area.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: Colors.white,
                letterSpacing: 0.3,
                height: 1.15,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.bodyColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              border: Border(
                left: BorderSide(color: theme.headerColor.withValues(alpha: 0.35)),
                right: BorderSide(color: theme.headerColor.withValues(alpha: 0.35)),
                bottom: BorderSide(color: theme.headerColor.withValues(alpha: 0.35)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StrategicAreaIconBadge(theme: theme, size: 80),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'GOAL:',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _editableBox(
                        goal,
                        'Goal from Step 4',
                        firestoreKey: _areaGoalKey(area),
                        compact: true,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.headerColor.withValues(alpha: 0.2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < initiatives.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2, right: 6),
                              child: Text(
                                '✓',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Initiative ${i + 1}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _editableBox(
                                    initiatives[i],
                                    'Initiative ${i + 1} from Step 4',
                                    firestoreKey: _areaInitiativeKey(area, i + 1),
                                    compact: true,
                                    fixedHeight: initiativeBoxHeight,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (i < initiatives.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategicFocusAreasSection() {
    if (_strategicAreas.isEmpty) {
      return Text(
        'Save strategic areas in Step 3 and goals in Step 4 to populate this section.',
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        const columnWidth = 240.0;
        final totalWidth =
            _strategicAreas.length * columnWidth +
            (_strategicAreas.length - 1) * gap;
        final fitsInRow = totalWidth <= constraints.maxWidth;
        final columnOuterWidth = fitsInRow
            ? (constraints.maxWidth -
                    (_strategicAreas.length - 1) * gap) /
                _strategicAreas.length
            : columnWidth;
        final initiativeBoxHeight = _uniformInitiativeBoxHeight(columnOuterWidth);

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _strategicAreas.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              if (fitsInRow)
                Expanded(
                  child: _focusAreaColumn(
                    _strategicAreas[i],
                    initiativeBoxHeight: initiativeBoxHeight,
                  ),
                )
              else
                _focusAreaColumn(
                  _strategicAreas[i],
                  width: columnWidth,
                  initiativeBoxHeight: initiativeBoxHeight,
                ),
            ],
          ],
        );

        if (fitsInRow) return row;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (companyId == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Company workspace not loaded. Sign in again or finish account setup, '
            'then return to the Strategic Plan 1 Pager.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB91C1C), height: 1.45),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          const SizedBox(height: 12),
          Text(
            '$_companyName Strategic Plan',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Your one-page strategic summary. Vision, mission, values, and targets '
              'prefill from Steps 1 and 3; focus areas and goals pull from Steps 3 and 4. '
              'Edit anything before sharing or downloading.',
              style: TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 22),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionCard(
                  title: 'Vision',
                  color: const Color(0xFFEFF6FF),
                  stretchBody: true,
                  children: [
                    Expanded(
                      child: _editableBox(
                        visionController,
                        'Your vision statement here',
                        firestoreKey: 'vision',
                      ),
                    ),
                  ],
                ),
                _sectionCard(
                  title: 'Mission',
                  color: const Color(0xFFEFF6FF),
                  stretchBody: true,
                  children: [
                    Expanded(
                      child: _editableBox(
                        missionController,
                        'Your mission statement here',
                        firestoreKey: 'mission',
                      ),
                    ),
                  ],
                ),
                _sectionCard(
                  title: 'Core Values',
                  color: const Color(0xFFF0FDF4),
                  stretchBody: true,
                  children: [
                    _editableBox(value1Controller, 'Value 1', firestoreKey: 'value1'),
                    _editableBox(value2Controller, 'Value 2', firestoreKey: 'value2'),
                    _editableBox(value3Controller, 'Value 3', firestoreKey: 'value3'),
                    _editableBox(value4Controller, 'Value 4', firestoreKey: 'value4'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: _sectionCard(
              title: 'Financial Targets',
              expanded: false,
              children: [
                _financialTargetsTable(),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Strategic Focus Areas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _strategicFocusAreasSection(),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _exportingOnePager
                  ? null
                  : () async {
                      setState(() => _exportingOnePager = true);
                      try {
                        await PlanPdfExport.downloadOnePager(
                          data: await _buildOnePagerPdfData(),
                          companyId: companyId,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not generate PDF: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _exportingOnePager = false);
                      }
                    },
              icon: _exportingOnePager
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Download Strategic One-Pager PDF'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (companyId != null && !skipFirebasePersistence) {
                    await PlanProgressService.cacheProgress(companyId!);
                  }
                  widget.onSaveAndContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7BEC),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
    );
  }
}

