import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_config.dart';
import 'services/assessment_pdf_export.dart';
import 'services/company_profile_service.dart';
import 'services/historical_financial_projection.dart';
import 'services/historical_financial_sync.dart';
import 'services/identity_session_cache.dart';
import 'services/openai_service.dart';
import 'services/plan_progress_service.dart';
import 'utils/currency_input.dart';
import 'utils/debounced_auto_save.dart';

/// [assessmentSection] is used by [StrategicPlanningPage] step 2 tabs:
/// `0` = Internal Assessment (pre-work checklist + SWOT + historical metrics prompts),
/// `1` = External Assessment (customer insights, market research, PESTEL, etc.),
/// `2` = Management Discussion (workshop framework, tips, executive insights + save).
/// `null` = legacy single scroll with everything together.
class CompanyAssessmentPage extends StatefulWidget {
  const CompanyAssessmentPage({
    super.key,
    this.assessmentSection,
    this.onSaveAndContinue,
    this.onAdvanceAssessmentTab,
  });

  /// `null` = full page. `0`–`2` = split tab content (same [State], all fields preserved).
  final int? assessmentSection;

  /// Invoked after a final-tab Save & Continue (management discussion or legacy full page).
  final Future<void> Function()? onSaveAndContinue;

  /// Invoked after Save & Continue on an intermediate assessment tab (0 or 1).
  final Future<void> Function(int nextTabIndex)? onAdvanceAssessmentTab;

  @override
  State<CompanyAssessmentPage> createState() => _CompanyAssessmentPageState();
}

class _CompanyAssessmentPageState extends State<CompanyAssessmentPage> {
  final Map<String, bool> prework = {
    'Executive Management/Employee Survey': false,
    'Gather and analyze historical data': false,
    'Conduct SWOT analysis': false,
    'Financial and key metrics analysis (last 3 years)': false,
  };

  // External assessment
  final customerInsights = TextEditingController();
  final marketResearchKeyTakeaways = TextEditingController();
  final pestelP = TextEditingController();
  final pestelE = TextEditingController();
  final pestelS = TextEditingController();
  final pestelT = TextEditingController();
  final pestelEnv = TextEditingController();
  final pestelL = TextEditingController();

  final porter = TextEditingController();
  final benchmarking = TextEditingController();

  /// Structured Porter's Five Forces (Internal Assessment).
  static const _porterForceIds = [
    'rivalry',
    'new_entrants',
    'substitutes',
    'suppliers',
    'buyers',
  ];
  late final Map<String, TextEditingController> porterForceNotes;
  final Map<String, String> porterForceIntensity = {
    for (final id in _porterForceIds) id: 'Medium',
  };

  static const _porterForceMeta = <String, ({
    String title,
    String subtitle,
    List<String> starters,
  })>{
    'rivalry': (
      title: 'Competitive Rivalry',
      subtitle:
          'How intense is competition among existing players in your market?',
      starters: [
        'Many similar competitors fighting for the same customers',
        'Low differentiation drives price and feature wars',
        'Slow market growth increases share battles',
        'High fixed costs push aggressive volume competition',
        'Customers can switch between rivals with little friction',
      ],
    ),
    'new_entrants': (
      title: 'Threat of New Entrants',
      subtitle: 'How easy is it for new companies to enter and compete?',
      starters: [
        'Low capital or regulatory barriers invite new players',
        'Brand loyalty and switching costs protect us from entrants',
        'Access to distribution or talent is a real barrier',
        'Technology or IP makes entry expensive',
        'Niche focus or local presence limits new competition',
      ],
    ),
    'substitutes': (
      title: 'Threat of Substitutes',
      subtitle:
          'How easily can customers meet the same need another way?',
      starters: [
        'Customers can DIY, outsource, or skip the purchase entirely',
        'Adjacent products/services solve the same job-to-be-done',
        'Price-performance of substitutes is improving quickly',
        'Our value is hard to replace because of outcomes or integration',
        'Switching to substitutes requires major process change',
      ],
    ),
    'suppliers': (
      title: 'Bargaining Power of Suppliers',
      subtitle:
          'How much leverage do critical vendors and partners have over you?',
      starters: [
        'Few qualified suppliers for key inputs or platforms',
        'Switching suppliers is costly or operationally risky',
        'Suppliers could forward-integrate into our space',
        'We have multiple alternatives and strong buying power',
        'Supplier pricing or SLAs materially affect our margins',
      ],
    ),
    'buyers': (
      title: 'Bargaining Power of Buyers',
      subtitle:
          'How much power do customers have to negotiate price and terms?',
      starters: [
        'A few large accounts represent a high share of revenue',
        'Buyers are well-informed and compare us closely to rivals',
        'Low switching costs let customers push for discounts',
        'Our offering is differentiated so buyers have less leverage',
        'Procurement-driven buying increases price pressure',
      ],
    ),
  };

  static const _swotItemCount = 7;

  // SWOT controllers — 7 entries per quadrant
  late final List<TextEditingController> swotStrengths;
  late final List<TextEditingController> swotWeaknesses;
  late final List<TextEditingController> swotOpportunities;
  late final List<TextEditingController> swotThreats;

  /// Historical financial grid: column Firestore ids → row key → controller.
  /// Columns are the last two complete fiscal years plus YTD for the current year.
  late final List<String> _finColumnIds;
  late final List<String> _finColumnLabels;
  int _ytdAsOfQuarter = HistoricalFinancialProjection.defaultCalendarQuarter();
  static const _finRowKeys = [
    'revenue',
    'gross_margin_dollar',
    'gross_margin_pct',
    'ebitda_dollar',
    'ebitda_pct',
  ];
  static const _finRowLabels = [
    'Revenue:',
    'Gross margin \$:',
    'Gross margin %:',
    'EBITDA \$:',
    'EBITDA %:',
  ];
  static const _additionalMetricCount = 5;
  static const _additionalMetricKeys = [
    'custom_1',
    'custom_2',
    'custom_3',
    'custom_4',
    'custom_5',
  ];
  late final Map<String, Map<String, TextEditingController>> finCtrls;
  late final List<TextEditingController> additionalMetricLabels;
  late final Map<String, Map<String, TextEditingController>> additionalMetricCtrls;
  late final List<FinancialMetricFormat> _additionalMetricFormats;
  final historicalAnalysisNotes = TextEditingController();

  /// Captured outcomes from the management discussion session (3–5 gaps/opportunities synthesis).
  final mgmtDiscussionOutput1 = TextEditingController();
  final mgmtDiscussionOutput2 = TextEditingController();
  final mgmtDiscussionOutput3 = TextEditingController();

  bool _exportingPdf = false;
  String? _suggestingExternalField;

  final DebouncedAutoSave _autoSave = DebouncedAutoSave();
  AutoSaveState _saveState = AutoSaveState.idle;
  String? _saveError;
  bool _autoSaveListenersAttached = false;

  @override
  void initState() {
    super.initState();
    _finColumnIds = _buildFinColumnIds();
    _finColumnLabels = _buildFinColumnLabels();
    finCtrls = {
      for (final id in _finColumnIds)
        id: {for (final k in _finRowKeys) k: TextEditingController()},
    };
    additionalMetricLabels =
        List.generate(_additionalMetricCount, (_) => TextEditingController());
    _additionalMetricFormats = List.filled(
      _additionalMetricCount,
      FinancialMetricFormat.number,
    );
    additionalMetricCtrls = {
      for (final id in _finColumnIds)
        id: {
          for (final k in _additionalMetricKeys) k: TextEditingController(),
        },
    };
    swotStrengths = _createSwotControllers();
    swotWeaknesses = _createSwotControllers();
    swotOpportunities = _createSwotControllers();
    swotThreats = _createSwotControllers();
    porterForceNotes = {
      for (final id in _porterForceIds) id: TextEditingController(),
    };
    _attachAutoSaveListeners();
    _loadCompanyId();
  }

  void _attachAutoSaveListeners() {
    if (_autoSaveListenersAttached) return;
    _autoSaveListenersAttached = true;

    void listen(TextEditingController c) => c.addListener(_scheduleAutoSave);

    for (final list in [
      swotStrengths,
      swotWeaknesses,
      swotOpportunities,
      swotThreats,
    ]) {
      for (final c in list) {
        listen(c);
      }
    }
    for (final id in finCtrls.keys) {
      for (final k in _finRowKeys) {
        listen(finCtrls[id]![k]!);
      }
    }
    for (final label in additionalMetricLabels) {
      listen(label);
    }
    for (final id in additionalMetricCtrls.keys) {
      for (final k in _additionalMetricKeys) {
        listen(additionalMetricCtrls[id]![k]!);
      }
    }
    listen(historicalAnalysisNotes);
    listen(customerInsights);
    listen(marketResearchKeyTakeaways);
    listen(pestelP);
    listen(pestelE);
    listen(pestelS);
    listen(pestelT);
    listen(pestelEnv);
    listen(pestelL);
    listen(porter);
    listen(benchmarking);
    for (final c in porterForceNotes.values) {
      listen(c);
    }
    listen(mgmtDiscussionOutput1);
    listen(mgmtDiscussionOutput2);
    listen(mgmtDiscussionOutput3);
  }

  void _scheduleAutoSave() {
    _autoSave.schedule(
      () => _saveAssessment(silent: true),
      () {
        if (mounted) {
          setState(() {
            _saveState = _autoSave.state;
            _saveError = _autoSave.errorMessage;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    for (final id in finCtrls.keys) {
      for (final k in _finRowKeys) {
        finCtrls[id]![k]!.dispose();
      }
    }
    for (final label in additionalMetricLabels) {
      label.dispose();
    }
    for (final id in additionalMetricCtrls.keys) {
      for (final k in _additionalMetricKeys) {
        additionalMetricCtrls[id]![k]!.dispose();
      }
    }
    historicalAnalysisNotes.dispose();
    _disposeSwotControllers(swotStrengths);
    _disposeSwotControllers(swotWeaknesses);
    _disposeSwotControllers(swotOpportunities);
    _disposeSwotControllers(swotThreats);
    customerInsights.dispose();
    marketResearchKeyTakeaways.dispose();
    pestelP.dispose();
    pestelE.dispose();
    pestelS.dispose();
    pestelT.dispose();
    pestelEnv.dispose();
    pestelL.dispose();
    porter.dispose();
    benchmarking.dispose();
    for (final c in porterForceNotes.values) {
      c.dispose();
    }
    mgmtDiscussionOutput1.dispose();
    mgmtDiscussionOutput2.dispose();
    mgmtDiscussionOutput3.dispose();
    _autoSave.dispose();
    super.dispose();
  }

  List<TextEditingController> _createSwotControllers() =>
      List.generate(_swotItemCount, (_) => TextEditingController());

  void _disposeSwotControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  void _loadSwotItems(dynamic value, List<TextEditingController> controllers) {
    if (value == null) return;
    if (value is String) {
      if (value.trim().isNotEmpty) {
        controllers[0].text = value;
      }
      return;
    }
    if (value is List) {
      for (var i = 0; i < controllers.length; i++) {
        controllers[i].text =
            i < value.length ? (value[i]?.toString() ?? '') : '';
      }
    }
  }

  List<String> _swotItemsToSave(List<TextEditingController> controllers) =>
      controllers.map((c) => c.text.trim()).toList();

  static List<String> _buildFinColumnIds([DateTime? asOf]) {
    final year = (asOf ?? DateTime.now()).year;
    return ['${year - 2}', '${year - 1}', 'ytd_$year'];
  }

  static List<String> _buildFinColumnLabels([DateTime? asOf]) {
    final year = (asOf ?? DateTime.now()).year;
    return ['${year - 2}', '${year - 1}', 'YTD $year'];
  }

  static String _buildProjectionColumnLabel([DateTime? asOf]) {
    final year = (asOf ?? DateTime.now()).year;
    return 'Year End Proj. $year';
  }

  static String _ytdColumnId([DateTime? asOf]) {
    final year = (asOf ?? DateTime.now()).year;
    return 'ytd_$year';
  }

  Map<String, String> _ytdValuesByRowKey() {
    final ytdId = _ytdColumnId();
    return {
      for (final k in _finRowKeys) k: finCtrls[ytdId]![k]!.text.trim(),
    };
  }

  String? _projectedFinancialRow(String rowKey) {
    return HistoricalFinancialProjection.projectFinancialRow(
      rowKey: rowKey,
      ytdValuesByRowKey: _ytdValuesByRowKey(),
      quarter: _ytdAsOfQuarter,
    );
  }

  String? _projectedAdditionalMetric(int index, String metricKey) {
    final ytdId = _ytdColumnId();
    return HistoricalFinancialProjection.projectAdditionalMetric(
      ytdText: additionalMetricCtrls[ytdId]![metricKey]!.text.trim(),
      formatKey: _additionalMetricFormats[index].storageKey,
      quarter: _ytdAsOfQuarter,
    );
  }

  List<String> _displayFinColumnLabels() => [
        ..._finColumnLabels,
        _buildProjectionColumnLabel(),
      ];

  static int _compareFinColumnKey(String a, String b) {
    final aYtd = a.startsWith('ytd_');
    final bYtd = b.startsWith('ytd_');
    if (aYtd && !bYtd) return 1;
    if (!aYtd && bYtd) return -1;
    final aYear = aYtd ? int.parse(a.substring(4)) : int.parse(a);
    final bYear = bYtd ? int.parse(b.substring(4)) : int.parse(b);
    return aYear.compareTo(bYear);
  }

  void _loadHistoricalFinancialColumn(
    Map<String, dynamic> columnData,
    String columnId,
  ) {
    for (final k in _finRowKeys) {
      finCtrls[columnId]![k]!.text = (columnData[k] ?? '').toString();
    }
  }

  void _loadHistoricalFinancials(Map<String, dynamic> data) {
    final loaded = List<bool>.filled(_finColumnIds.length, false);

    for (var i = 0; i < _finColumnIds.length; i++) {
      final id = _finColumnIds[i];
      final col = data[id];
      if (col is Map<String, dynamic>) {
        _loadHistoricalFinancialColumn(col, id);
        loaded[i] = true;
      }
    }

    if (loaded.every((value) => value)) return;

    final fallbackKeys = data.keys
        .where((key) => data[key] is Map<String, dynamic>)
        .toList()
      ..sort(_compareFinColumnKey);

    for (var i = 0; i < _finColumnIds.length; i++) {
      if (loaded[i] || i >= fallbackKeys.length) continue;
      final col = data[fallbackKeys[i]];
      if (col is Map<String, dynamic>) {
        _loadHistoricalFinancialColumn(col, _finColumnIds[i]);
      }
    }

    final additionalMetrics = data['additional_metrics'];
    if (additionalMetrics is List) {
      for (var i = 0; i < _additionalMetricCount && i < additionalMetrics.length; i++) {
        final row = additionalMetrics[i];
        if (row is! Map<String, dynamic>) continue;
        additionalMetricLabels[i].text = (row['label'] ?? '').toString();
        final metricKey = _additionalMetricKeys[i];
        for (final colId in _finColumnIds) {
          additionalMetricCtrls[colId]![metricKey]!.text =
              (row[colId] ?? '').toString();
        }
      }
    }

    final formats = data['additional_metric_formats'];
    if (formats is List) {
      for (var i = 0; i < _additionalMetricCount && i < formats.length; i++) {
        _additionalMetricFormats[i] =
            FinancialMetricFormat.fromStored(formats[i]?.toString());
      }
    }

    historicalAnalysisNotes.text =
        (data['historical_analysis_notes'] ?? '').toString();

    final storedQuarter = data['ytd_as_of_quarter'];
    if (storedQuarter is num) {
      _ytdAsOfQuarter = storedQuarter.toInt().clamp(1, 4);
    }
  }

  // Firebase loading/saving
  String? _companyId;

  Future<void> _loadCompanyId() async {
    _companyId = await loadCompanyIdForCurrentUser();
    if (!authBypassEnabled && _companyId != null) {
      await _loadAssessmentValues();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadAssessmentValues() async {
    if (skipFirebasePersistence || _companyId == null) return;

    // Load SWOT
    final swotRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('swot_analysis');

    final swotSnap = await swotRef.get();

    if (swotSnap.exists && swotSnap.data() != null) {
      print("swotSnap \n");
      print(swotSnap);
      final data = swotSnap.data()!;
      print(data);
      _loadSwotItems(data['strengths'], swotStrengths);
      _loadSwotItems(data['weaknesses'], swotWeaknesses);
      _loadSwotItems(data['opportunities'], swotOpportunities);
      _loadSwotItems(data['threats'], swotThreats);
    }

    // Load external assessment
    final extRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('external_assessment');
    final extSnap = await extRef.get();
    if (extSnap.exists && extSnap.data() != null) {
      final d = extSnap.data()!;
      print("Pestel");
      print(d);
      pestelP.text = d['pestel_p'] ?? '';
      pestelE.text = d['pestel_e'] ?? '';
      pestelS.text = d['pestel_s'] ?? '';
      pestelT.text = d['pestel_t'] ?? '';
      pestelEnv.text = d['pestel_env'] ?? '';
      pestelL.text = d['pestel_l'] ?? '';
      porter.text = d['porter'] ?? '';
      benchmarking.text = d['benchmarking'] ?? '';
      customerInsights.text = (d['customer_insights'] ?? '').toString();
      marketResearchKeyTakeaways.text =
          (d['market_research_key_takeaways'] ?? '').toString();
    }

    // Load prework
    final preworkRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('pre_work');

    final preworkSnap = await preworkRef.get();

    if (preworkSnap.exists && preworkSnap.data() != null) {
      final preworkData = preworkSnap.data()!;
      // Iterate through map keys and load from Firestore
      for (final key in prework.keys) {
        prework[key] = preworkData[key] ?? false;
      }
    }

    final histRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('historical_financials');
    final histSnap = await histRef.get();
    if (histSnap.exists && histSnap.data() != null) {
      _loadHistoricalFinancials(histSnap.data()!);
    }

    final mgmtOutRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('management_discussion_output');
    final mgmtOutSnap = await mgmtOutRef.get();
    if (mgmtOutSnap.exists && mgmtOutSnap.data() != null) {
      final d = mgmtOutSnap.data()!;
      mgmtDiscussionOutput1.text = (d['output_1'] ?? '').toString();
      mgmtDiscussionOutput2.text = (d['output_2'] ?? '').toString();
      mgmtDiscussionOutput3.text = (d['output_3'] ?? '').toString();
    }

    final porterRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('porter_five_forces');
    final porterSnap = await porterRef.get();
    if (porterSnap.exists && porterSnap.data() != null) {
      _loadPorterFiveForces(porterSnap.data()!);
    }
  }

  void _loadPorterFiveForces(Map<String, dynamic> data) {
    for (final id in _porterForceIds) {
      final raw = data[id];
      if (raw is Map) {
        final notes = (raw['notes'] ?? '').toString();
        final intensity = (raw['intensity'] ?? 'Medium').toString();
        porterForceNotes[id]!.text = notes;
        if (const ['Low', 'Medium', 'High'].contains(intensity)) {
          porterForceIntensity[id] = intensity;
        }
      } else if (raw != null) {
        porterForceNotes[id]!.text = raw.toString();
      }
    }
  }

  String _porterSummaryText() {
    final lines = <String>[];
    for (final id in _porterForceIds) {
      final meta = _porterForceMeta[id]!;
      final notes = porterForceNotes[id]!.text.trim();
      final intensity = porterForceIntensity[id] ?? 'Medium';
      if (notes.isEmpty && intensity == 'Medium') continue;
      lines.add(
        '${meta.title} ($intensity)${notes.isEmpty ? '' : ': $notes'}',
      );
    }
    return lines.join('\n\n');
  }

  Future<void> _saveHistoricalFinancials() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('historical_financials');
    final payload = <String, dynamic>{
      for (final id in _finColumnIds)
        id: {
          for (final k in _finRowKeys) k: finCtrls[id]![k]!.text.trim(),
        },
      'additional_metrics': List.generate(_additionalMetricCount, (i) {
        final metricKey = _additionalMetricKeys[i];
        return {
          'label': additionalMetricLabels[i].text.trim(),
          for (final colId in _finColumnIds)
            colId: additionalMetricCtrls[colId]![metricKey]!.text.trim(),
        };
      }),
      'additional_metric_formats': _additionalMetricFormats
          .map((format) => format.storageKey)
          .toList(),
      'historical_analysis_notes': historicalAnalysisNotes.text.trim(),
      'ytd_as_of_quarter': _ytdAsOfQuarter,
    };
    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> _savePrework() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('pre_work');
    await ref.set(prework, SetOptions(merge: true));
  }

  Future<void> _saveSwot() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('swot_analysis');
    await ref.set({
      'strengths': _swotItemsToSave(swotStrengths),
      'weaknesses': _swotItemsToSave(swotWeaknesses),
      'opportunities': _swotItemsToSave(swotOpportunities),
      'threats': _swotItemsToSave(swotThreats),
    }, SetOptions(merge: true));
  }

  Future<void> _saveExternalAssessment() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('external_assessment');
    await ref.set({
      'pestel_p': pestelP.text.trim(),
      'pestel_e': pestelE.text.trim(),
      'pestel_s': pestelS.text.trim(),
      'pestel_t': pestelT.text.trim(),
      'pestel_env': pestelEnv.text.trim(),
      'pestel_l': pestelL.text.trim(),
      'porter': porter.text.trim(),
      'benchmarking': benchmarking.text.trim(),
      'customer_insights': customerInsights.text.trim(),
      'market_research_key_takeaways': marketResearchKeyTakeaways.text.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> _savePorterFiveForces() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('porter_five_forces');
    await ref.set({
      for (final id in _porterForceIds)
        id: {
          'intensity': porterForceIntensity[id] ?? 'Medium',
          'notes': porterForceNotes[id]!.text.trim(),
        },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep legacy freeform Porter field in sync when empty so PDF/export stay useful.
    final summary = _porterSummaryText();
    if (summary.isNotEmpty && porter.text.trim().isEmpty) {
      porter.text = summary;
    }
  }

  Future<void> _saveManagementDiscussionOutput() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('management_discussion_output');
    await ref.set({
      'output_1': mgmtDiscussionOutput1.text.trim(),
      'output_2': mgmtDiscussionOutput2.text.trim(),
      'output_3': mgmtDiscussionOutput3.text.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveAssessment({bool silent = false}) async {
    try {
      await _savePrework();
      await _saveSwot();
      await _savePorterFiveForces();
      await _saveHistoricalFinancials();
      await _saveExternalAssessment();
      await _saveManagementDiscussionOutput();
      if (!skipFirebasePersistence && _companyId != null) {
        await PlanProgressService.cacheProgress(_companyId!);
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Assessment saved')));
      }
    } catch (e) {
      if (silent) rethrow;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  AssessmentStep2Snapshot _buildAssessmentPdfSnapshot() {
    final finRowValues = <List<String>>[];
    for (final rowKey in _finRowKeys) {
      finRowValues.add([
        for (final colId in _finColumnIds)
          finCtrls[colId]![rowKey]!.text.trim(),
        _projectedFinancialRow(rowKey) ?? '',
      ]);
    }

    final additionalMetricValueRows = <List<String>>[];
    final additionalLabels = <String>[];
    for (var i = 0; i < _additionalMetricKeys.length; i++) {
      final metricKey = _additionalMetricKeys[i];
      additionalLabels.add(additionalMetricLabels[i].text.trim());
      additionalMetricValueRows.add([
        for (final colId in _finColumnIds)
          additionalMetricCtrls[colId]![metricKey]!.text.trim(),
        _projectedAdditionalMetric(i, metricKey) ?? '',
      ]);
    }

    return AssessmentStep2Snapshot(
      prework: Map<String, bool>.from(prework),
      swotStrengths: swotStrengths.map((c) => c.text.trim()).toList(),
      swotWeaknesses: swotWeaknesses.map((c) => c.text.trim()).toList(),
      swotOpportunities: swotOpportunities.map((c) => c.text.trim()).toList(),
      swotThreats: swotThreats.map((c) => c.text.trim()).toList(),
      finColumnLabels: _displayFinColumnLabels(),
      finRowLabels: List<String>.from(_finRowLabels),
      finRowValues: finRowValues,
      additionalMetricLabels: additionalLabels,
      additionalMetricValues: additionalMetricValueRows,
      historicalAnalysisNotes: historicalAnalysisNotes.text.trim(),
      customerInsights: customerInsights.text.trim(),
      marketResearchKeyTakeaways: marketResearchKeyTakeaways.text.trim(),
      pestelP: pestelP.text.trim(),
      pestelE: pestelE.text.trim(),
      pestelS: pestelS.text.trim(),
      pestelT: pestelT.text.trim(),
      pestelEnv: pestelEnv.text.trim(),
      pestelL: pestelL.text.trim(),
      porter: porter.text.trim().isNotEmpty
          ? porter.text.trim()
          : _porterSummaryText(),
      benchmarking: benchmarking.text.trim(),
    );
  }

  Future<void> _downloadAssessmentPdf() async {
    setState(() => _exportingPdf = true);
    try {
      await AssessmentPdfExport.download(
        companyId: _companyId,
        step2: _buildAssessmentPdfSnapshot(),
        fetchFromFirestore: !skipFirebasePersistence,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Widget _downloadAssessmentPdfButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _exportingPdf ? null : _downloadAssessmentPdf,
        icon: _exportingPdf
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        label: const Text('Download Step 1 & 2 Assessment PDF'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7D32),
          side: const BorderSide(color: Color(0xFF2E7D32)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  List<Widget> _preworkChecklistTiles() {
    return [
      const _Subheader('Pre-Work'),
      ...prework.entries.map(
        (e) => CheckboxListTile(
          value: e.value,
          onChanged: (v) {
            setState(() => prework[e.key] = v ?? false);
            _scheduleAutoSave();
          },
          title: Text(e.key),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];
  }

  /// PESTEL, Porter, benchmarking — used on External Assessment tab and legacy full page.
  List<Widget> _externalAssessmentFields(BuildContext context) {
    return [
      const _Subheader('Key Questions'),
      const _BodyBullets([
        'What external trends (market, tech, regulation, customer behavior) could impact us?',
        'How are customer needs or expectations changing?',
        'Where are competitors gaining ground—or losing it?',
        'What external risks pose the biggest threat to growth?',
        'What opportunities exist to expand or differentiate?',
      ]),
      const SizedBox(height: 20),
      Text(
        'Frameworks and Insights',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
      ),
      const SizedBox(height: 12),
      if (_aiSuggestionsEnabled)
        Text(
          'Use the lightbulbs to draft Customer & Market Research or PESTEL from your '
          'company profile, internal assessment, and industry knowledge. Review and edit before saving.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
        ),
      if (_aiSuggestionsEnabled) const SizedBox(height: 20) else const SizedBox(height: 8),
      _LabeledTextField(
        label: 'Customer Insights',
        hint:
            'Capture satisfaction scores, unmet needs, buying behavior, and other customer findings…',
        controller: customerInsights,
        maxLines: 8,
        labelTrailing: _externalSuggestLightbulb(
          fieldKey: 'customer_insights',
          tooltip: 'Suggest customer insights',
          onPressed: () => _suggestExternalField('customer_insights'),
        ),
      ),
      const SizedBox(height: 20),
      _LabeledTextField(
        label: 'Market Research Key Takeaways',
        hint:
            'Summarize industry trends, competitor benchmarks, pricing insights, and other market research findings…',
        controller: marketResearchKeyTakeaways,
        maxLines: 8,
        labelTrailing: _externalSuggestLightbulb(
          fieldKey: 'market_research',
          tooltip: 'Suggest market research takeaways',
          onPressed: () => _suggestExternalField('market_research'),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Text(
              'PESTEL Analysis:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _externalSuggestLightbulb(
            fieldKey: 'pestel',
            tooltip: 'Suggest full PESTEL analysis',
            onPressed: () => _suggestExternalField('pestel'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _TwoCol(
        left: _LabeledTextField(
          label: 'Political:',
          hint: 'Regulations, tax policies, political stability…',
          controller: pestelP,
        ),
        right: _LabeledTextField(
          label: 'Economic:',
          hint: 'Growth rates, inflation, interest rates…',
          controller: pestelE,
        ),
      ),
      const SizedBox(height: 12),
      _TwoCol(
        left: _LabeledTextField(
          label: 'Social:',
          hint: 'Demographics, lifestyle trends, cultural factors…',
          controller: pestelS,
        ),
        right: _LabeledTextField(
          label: 'Technological:',
          hint: 'Innovation, automation, digital transformation…',
          controller: pestelT,
        ),
      ),
      const SizedBox(height: 12),
      _TwoCol(
        left: _LabeledTextField(
          label: 'Environmental:',
          hint: 'Sustainability, climate, resource use, ESG pressures…',
          controller: pestelEnv,
        ),
        right: _LabeledTextField(
          label: 'Legal:',
          hint: 'Compliance, labor law, industry regulations, litigation risk…',
          controller: pestelL,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        "Porter's Five Forces:",
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 6),
      Text(
        'Structured Low / Medium / High evaluation with starter prompts lives on the '
        'Internal Assessment tab. Use this field for a narrative summary or extra notes.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
      ),
      const SizedBox(height: 8),
      _LabeledTextField(
        label: 'Analyze the competitive forces in your industry…',
        hint:
            'Competitive rivalry, new entrants, substitutes, supplier power, buyer power',
        controller: porter,
        maxLines: 4,
      ),
      const SizedBox(height: 16),
      Text(
        'Customer & Competitor Benchmarking:',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      _LabeledTextField(
        label:
            'Benchmark your company against competitors and customer expectations…',
        hint:
            'Compare NPS, pricing, delivery speed, quality, feature depth, market share, etc.',
        controller: benchmarking,
        maxLines: 4,
      ),
    ];
  }

  bool get _aiSuggestionsEnabled => aiSuggestionsEnabled;

  Widget _externalSuggestLightbulb({
    required String fieldKey,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    if (!_aiSuggestionsEnabled) return const SizedBox.shrink();
    final loading = _suggestingExternalField == fieldKey;
    return IconButton(
      tooltip: tooltip,
      onPressed: loading || _suggestingExternalField != null ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.lightbulb_outline,
              size: 22,
              color: Color(0xFF2563EB),
            ),
    );
  }

  String _joinNonEmpty(List<String> lines) =>
      lines.where((l) => l.trim().isNotEmpty).join('\n');

  String _swotLines(String label, List<TextEditingController> controllers) {
    final items = controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (items.isEmpty) return '';
    return '$label:\n${items.map((i) => '- $i').join('\n')}';
  }

  Future<String> _buildExternalSuggestionContext() async {
    final parts = <String>[];

    void addBlock(String title, String body) {
      final trimmed = body.trim();
      if (trimmed.isNotEmpty) parts.add('## $title\n$trimmed');
    }

    try {
      final profile = await CompanyProfileService.load(_companyId);
      addBlock(
        'Company profile',
        _joinNonEmpty([
          if (profile.companyName.isNotEmpty) 'Name: ${profile.companyName}',
          if (profile.industry.isNotEmpty) 'Industry: ${profile.industry}',
          if (profile.description.isNotEmpty)
            'Description: ${profile.description}',
          if (profile.companySize.isNotEmpty) 'Size: ${profile.companySize}',
          if (profile.website.isNotEmpty) 'Website: ${profile.website}',
          if (profile.city.isNotEmpty || profile.country.isNotEmpty)
            'Location: ${[profile.city, profile.stateRegion, profile.country].where((s) => s.trim().isNotEmpty).join(', ')}',
          if (profile.recentFinancials.revenue.trim().isNotEmpty)
            'Recent revenue: ${profile.recentFinancials.revenue}',
        ]),
      );
    } catch (_) {}

    if (!skipFirebasePersistence &&
        _companyId != null &&
        _companyId!.isNotEmpty) {
      try {
        final bgSnap = await FirebaseFirestore.instance
            .collection('companies')
            .doc(_companyId)
            .collection('companyIdentity')
            .doc('company_background')
            .get();
        final bg = bgSnap.data() ?? {};
        addBlock(
          'Company background (Step 1)',
          _joinNonEmpty([
            if ((bg['products_services'] ?? '').toString().trim().isNotEmpty)
              'Products/services: ${bg['products_services']}',
            if ((bg['customer_problem'] ?? '').toString().trim().isNotEmpty)
              'Customer problem: ${bg['customer_problem']}',
            if ((bg['primary_customers'] ?? '').toString().trim().isNotEmpty)
              'Primary customers: ${bg['primary_customers']}',
            if ((bg['industries_served'] ?? '').toString().trim().isNotEmpty)
              'Industries served: ${bg['industries_served']}',
            if ((bg['revenue_model'] ?? '').toString().trim().isNotEmpty)
              'Revenue model: ${bg['revenue_model']}',
            if ((bg['geographic_area'] ?? '').toString().trim().isNotEmpty)
              'Geography: ${bg['geographic_area']}',
            if ((bg['competitive_advantage'] ?? '').toString().trim().isNotEmpty)
              'Competitive advantage: ${bg['competitive_advantage']}',
          ]),
        );

        final idSnap = await FirebaseFirestore.instance
            .collection('companies')
            .doc(_companyId)
            .collection('companyIdentity')
            .doc('refine_company_identity')
            .get();
        final id = idSnap.data() ?? {};
        addBlock(
          'Mission / vision / values',
          _joinNonEmpty([
            if ((id['mission_str'] ?? '').toString().trim().isNotEmpty)
              'Mission: ${id['mission_str']}',
            if ((id['vision_str'] ?? '').toString().trim().isNotEmpty)
              'Vision: ${id['vision_str']}',
            if ((id['values_str'] ?? '').toString().trim().isNotEmpty)
              'Values: ${id['values_str']}',
          ]),
        );
      } catch (_) {}
    } else {
      addBlock(
        'Mission / vision / values',
        _joinNonEmpty([
          if (IdentitySessionCache.mission.trim().isNotEmpty)
            'Mission: ${IdentitySessionCache.mission}',
          if (IdentitySessionCache.vision.trim().isNotEmpty)
            'Vision: ${IdentitySessionCache.vision}',
          if (IdentitySessionCache.values.trim().isNotEmpty)
            'Values: ${IdentitySessionCache.values}',
        ]),
      );
    }

    addBlock(
      'Internal assessment — SWOT',
      _joinNonEmpty([
        _swotLines('Strengths', swotStrengths),
        _swotLines('Weaknesses', swotWeaknesses),
        _swotLines('Opportunities', swotOpportunities),
        _swotLines('Threats', swotThreats),
      ]),
    );

    addBlock(
      "Porter's Five Forces evaluation",
      _porterSummaryText(),
    );

    addBlock(
      'Historical analysis notes',
      historicalAnalysisNotes.text,
    );

    addBlock(
      'Existing external drafts (other fields)',
      _joinNonEmpty([
        if (customerInsights.text.trim().isNotEmpty)
          'Customer insights: ${customerInsights.text.trim()}',
        if (marketResearchKeyTakeaways.text.trim().isNotEmpty)
          'Market research: ${marketResearchKeyTakeaways.text.trim()}',
        if (porter.text.trim().isNotEmpty) 'Porter: ${porter.text.trim()}',
        if (benchmarking.text.trim().isNotEmpty)
          'Benchmarking: ${benchmarking.text.trim()}',
      ]),
    );

    return parts.join('\n\n');
  }

  Future<void> _suggestExternalField(String fieldKey) async {
    if (!_aiSuggestionsEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI suggestions require an OpenAI API key in .env'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _suggestingExternalField = fieldKey);
    try {
      final contextText = await _buildExternalSuggestionContext();
      if (fieldKey == 'pestel') {
        final pestel = await OpenAIService().generatePestelSuggestion(
          companyContext: contextText,
          existingPestel: {
            'POLITICAL': pestelP.text,
            'ECONOMIC': pestelE.text,
            'SOCIAL': pestelS.text,
            'TECHNOLOGICAL': pestelT.text,
            'ENVIRONMENTAL': pestelEnv.text,
            'LEGAL': pestelL.text,
          },
        );
        if (!mounted) return;
        void apply(String key, TextEditingController controller) {
          final value = pestel[key]?.trim() ?? '';
          if (value.isNotEmpty) controller.text = value;
        }

        apply('POLITICAL', pestelP);
        apply('ECONOMIC', pestelE);
        apply('SOCIAL', pestelS);
        apply('TECHNOLOGICAL', pestelT);
        apply('ENVIRONMENTAL', pestelEnv);
        apply('LEGAL', pestelL);
        _scheduleAutoSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PESTEL suggestions added — review and edit as needed'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final fieldType = fieldKey == 'customer_insights'
          ? 'Customer Insights'
          : 'Market Research Key Takeaways';
      final controller = fieldKey == 'customer_insights'
          ? customerInsights
          : marketResearchKeyTakeaways;

      final suggestion =
          await OpenAIService().generateExternalAssessmentSuggestion(
        fieldType: fieldType,
        existingText: controller.text,
        companyContext: contextText,
      );
      if (!mounted) return;
      controller.text = suggestion;
      _scheduleAutoSave();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Suggested $fieldType added — review and edit as needed'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate suggestion: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _suggestingExternalField = null);
    }
  }

  List<Widget> _managementDiscussionFields() {
    return [
      Text(
        'Bringing It Together: Management Discussion to Identify Strategic Gaps & Opportunities.',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
      ),
      const SizedBox(height: 20),
      const _Subheader('Goal'),
      const SizedBox(height: 6),
      Text(
        'Align leadership on the most critical strategic gaps & opportunities.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      const SizedBox(height: 20),
      const _Subheader('Inputs to Review'),
      const SizedBox(height: 8),
      _TaggedBullets(const [
        (
          tag: 'Management Insights',
          text: 'Survey themes & feedback.',
        ),
        (
          tag: 'SWOT Summary',
          text: 'Strengths, weaknesses, opportunities, threats.',
        ),
        (
          tag: 'Historical Data & Metrics',
          text: 'Financial, customer, operational, people.',
        ),
        (
          tag: 'External Assessment',
          text: 'Market, competitors, macro trends.',
        ),
      ]),
      const SizedBox(height: 16),
      _downloadAssessmentPdfButton(),
      const SizedBox(height: 20),
      const _Subheader('Discussion Questions'),
      const SizedBox(height: 8),
      const _BodyBullets([
        'What gaps or weaknesses most limit our ability to grow?',
        'What external opportunities are most attractive and aligned with our strengths?',
        "Where are we most at risk if we don't act?",
        'Which 2–3 priorities will have the biggest impact in the next 1–3 years?',
      ]),
      const SizedBox(height: 20),
      const _Subheader('Output: 3–5 Strategic Gaps & Opportunities'),
      const SizedBox(height: 8),
      const _BodyBullets([
        'A short list of critical gaps to address and opportunities to pursue.',
        'Shared alignment on where to focus in the next step of strategic planning.',
      ]),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB8D4EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tips',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            const _BodyBullets([
              'Use workshop sessions to discuss and brainstorm utilizing small breakout groups.',
              'May want to host offsite and have the session facilitated.',
              'Ensure pre-work is done and reviewed prior to the session.',
            ]),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const _Subheader('Executive Management Insights'),
      const SizedBox(height: 10),
      Text(
        'Gather Management Insights: Gain insight from management team on where they see gaps '
        'and opportunities. Compile and identify top responses from each section.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
      ),
      const SizedBox(height: 16),
      const _Subheader('Sample questions for management discussion'),
      const SizedBox(height: 10),
      _NumberedLines(const [
        'Reviewing our SWOT and historical metrics together, what themes stand out as most urgent for leadership to address?',
        'Which of our strengths are durable competitive advantages—and which are we under-leveraging today?',
        'What internal weaknesses or capability gaps most constrain our ability to hit our growth and financial targets?',
        'Which external trends or market shifts from our assessment could materially help or hurt us in the next 1–3 years?',
        'Where are competitors outpacing us, and what would meaningful differentiation require?',
        'What customer or stakeholder needs are we meeting well—and where are we falling short of expectations?',
        'If we could only address three internal gaps in the next 12–18 months, which would create the greatest strategic impact?',
        'If we could only pursue three opportunities, which best fit our company identity and current capabilities?',
        'What are we willing to deprioritize or stop doing to create focus for our top strategic priorities?',
        'What people, budget, or operational investments are required to close our highest-priority gaps?',
        'What early warning signs or KPIs should we track to know whether we are making real progress?',
        'What is the one strategic risk we are most exposed to if we fail to act—and what is our mitigation?',
      ]),
      const SizedBox(height: 28),
      const _Subheader('Document discussion output'),
      const SizedBox(height: 6),
      Text(
        'Capture the main gaps, opportunities, or priorities agreed in your management discussion '
        '(align with 3–5 strategic gaps & opportunities).',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.45,
              color: Colors.grey.shade700,
            ),
      ),
      const SizedBox(height: 14),
      _LabeledTextField(
        label: 'Gap / opportunity 1',
        hint:
            'Summarize a critical gap to close or opportunity to pursue, plus any agreed actions…',
        controller: mgmtDiscussionOutput1,
        maxLines: 5,
      ),
      const SizedBox(height: 12),
      _LabeledTextField(
        label: 'Gap / opportunity 2',
        hint: 'Second priority theme from the discussion…',
        controller: mgmtDiscussionOutput2,
        maxLines: 5,
      ),
      const SizedBox(height: 12),
      _LabeledTextField(
        label: 'Gap / opportunity 3',
        hint: 'Third priority theme from the discussion…',
        controller: mgmtDiscussionOutput3,
        maxLines: 5,
      ),
    ];
  }

  Widget _saveAndContinueButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSaveStatusChip(state: _saveState, errorMessage: _saveError),
          if (_saveState != AutoSaveState.idle) const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _onSaveAndContinuePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B7BEC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    );
  }

  Future<void> _onSaveAndContinuePressed() async {
    await _saveAssessment();
    if (!mounted) return;

    final section = widget.assessmentSection;
    if (section == null) {
      await widget.onSaveAndContinue?.call();
      return;
    }

    if (section >= 2) {
      await widget.onSaveAndContinue?.call();
      return;
    }

    await widget.onAdvanceAssessmentTab?.call(section + 1);
  }

  Widget _porterFiveForcesCard() {
    return _SectionCard(
      title: "Porter's Five Forces Evaluation",
      icon: Icons.hub_outlined,
      accentColor: const Color(0xFF0F766E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate each competitive force and capture notes. Tap a starter suggestion '
            'to drop it into your evaluation—then edit it to fit your business.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this before External Assessment so AI and leadership discussion '
            'are grounded in how hard it is to compete in your industry.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _porterForceIds.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _porterForcePanel(_porterForceIds[i]),
          ],
        ],
      ),
    );
  }

  Widget _porterForcePanel(String forceId) {
    final meta = _porterForceMeta[forceId]!;
    final intensity = porterForceIntensity[forceId] ?? 'Medium';
    final notesController = porterForceNotes[forceId]!;

    Color intensityColor(String value) {
      switch (value) {
        case 'High':
          return const Color(0xFFB91C1C);
        case 'Low':
          return const Color(0xFF15803D);
        default:
          return const Color(0xFFB45309);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: intensityColor(intensity).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: intensityColor(intensity).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  intensity,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: intensityColor(intensity),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Force intensity',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const ['Low', 'Medium', 'High'])
                ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: intensity == option
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                  ),
                  selected: intensity == option,
                  onSelected: (_) {
                    setState(() => porterForceIntensity[forceId] = option);
                    _scheduleAutoSave();
                  },
                  selectedColor: intensityColor(option),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: intensity == option
                        ? intensityColor(option)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Starter suggestions',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to add to your notes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final starter in meta.starters)
                ActionChip(
                  avatar: const Icon(
                    Icons.add,
                    size: 16,
                    color: Color(0xFF0F766E),
                  ),
                  label: Text(
                    starter,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF115E59),
                    ),
                  ),
                  backgroundColor: const Color(0xFFCCFBF1),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  onPressed: () {
                    final current = notesController.text.trim();
                    final bullet = '• $starter';
                    if (current.contains(starter)) return;
                    notesController.text =
                        current.isEmpty ? bullet : '$current\n$bullet';
                    notesController.selection = TextSelection.collapsed(
                      offset: notesController.text.length,
                    );
                    _scheduleAutoSave();
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: _roundedDecoration(
              context,
              'Your evaluation notes for ${meta.title.toLowerCase()}…',
            ),
          ),
        ],
      ),
    );
  }

  Widget _historicalDataCard() {
    return _SectionCard(
      title: 'Gather and analyze historical data and metrics',
      icon: Icons.analytics_outlined,
      accentColor: const Color(0xFF06B6D4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Subheader('Suggested Data to Gather'),
          const SizedBox(height: 8),
          const _BodyBullets([
            'Financials: Revenue, gross margin, EBITDA, cash flow trends (2–3 years)',
            'Customer: Retention rates, churn, NPS/satisfaction scores, acquisition cost',
            'Operations: Productivity, throughput, cycle times, quality/defect rates',
            'People: Headcount, turnover, engagement survey results, training investment',
          ]),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: _HistoricalFinancialTable(
                    columnIds: _finColumnIds,
                    columnLabels: _finColumnLabels,
                    projectionColumnLabel: _buildProjectionColumnLabel(),
                    ytdColumnId: _ytdColumnId(),
                    ytdAsOfQuarter: _ytdAsOfQuarter,
                    onYtdAsOfQuarterChanged: (quarter) {
                      setState(() => _ytdAsOfQuarter = quarter);
                      _scheduleAutoSave();
                    },
                    projectFinancialRow: _projectedFinancialRow,
                    projectAdditionalMetric: _projectedAdditionalMetric,
                    rowKeys: _finRowKeys,
                    rowLabels: _finRowLabels,
                    ctrls: finCtrls,
                    additionalMetricKeys: _additionalMetricKeys,
                    additionalMetricLabels: additionalMetricLabels,
                    additionalMetricCtrls: additionalMetricCtrls,
                    additionalMetricFormats: _additionalMetricFormats,
                    onAdditionalMetricFormatChanged: (index, format) {
                      setState(() => _additionalMetricFormats[index] = format);
                      _scheduleAutoSave();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Revenue, gross margin, and EBITDA \$ / % auto-calculate within each column. '
            'Year-end projection annualizes YTD \$ and count metrics using the selected '
            'quarter (YTD × 4 ÷ quarter). Margin and EBITDA % in the projection column '
            'are recalculated from projected dollars when revenue is available.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '* please feel free to do a deeper dive',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 22),
          const _Subheader('Questions to guide Analysis:'),
          const SizedBox(height: 8),
          _TaggedBullets([
            (
              tag: 'Trends',
              text:
                  'What do the last 3–5 years of data tell us—are we growing, flat, or declining?',
            ),
            (
              tag: 'Drivers',
              text:
                  'What factors most influenced these results (internal or external)?',
            ),
            (
              tag: 'Comparisons',
              text:
                  'How do we perform against competitors or industry benchmarks?',
            ),
            (
              tag: 'Variability',
              text:
                  'Where do we see consistency vs. volatility in performance?',
            ),
            (
              tag: 'Implications',
              text:
                  'What strengths can we double down on, and what weak spots need urgent attention?',
            ),
          ]),
          const SizedBox(height: 16),
          _LabeledTextField(
            label: 'Analysis Notes',
            hint:
                'Document your answers, observations, and notes from reviewing historical data…',
            controller: historicalAnalysisNotes,
            maxLines: 8,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.assessmentSection;

    if (section == 0) {
      return _PageScroll(
        children: [
          _SectionCard(
            title: 'Internal Assessment',
            icon: Icons.psychology_outlined,
            accentColor: const Color(0xFF2E7D32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._preworkChecklistTiles(),
                const SizedBox(height: 20),
                const _Subheader('SWOT Analysis'),
                const SizedBox(height: 8),
                _SwotGrid(
                  strengths: swotStrengths,
                  weaknesses: swotWeaknesses,
                  opportunities: swotOpportunities,
                  threats: swotThreats,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _porterFiveForcesCard(),
          const SizedBox(height: 16),
          _historicalDataCard(),
          const SizedBox(height: 24),
          _saveAndContinueButton(),
        ],
      );
    }

    if (section == 1) {
      return _PageScroll(
        children: [
          _SectionCard(
            title: 'External Assessment',
            icon: Icons.public_outlined,
            accentColor: const Color(0xFF2E7D32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _externalAssessmentFields(context),
            ),
          ),
          const SizedBox(height: 24),
          _saveAndContinueButton(),
        ],
      );
    }

    if (section == 2) {
      return _PageScroll(
        children: [
          _SectionCard(
            title: 'Management Discussion',
            icon: Icons.forum_outlined,
            accentColor: const Color(0xFF2E7D32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._managementDiscussionFields(),
                const SizedBox(height: 20),
                _saveAndContinueButton(),
              ],
            ),
          ),
        ],
      );
    }

    // Legacy full page (section == null): pre-work + SWOT in first card, then rest.
    return _PageScroll(
      children: [
        _SectionCard(
          title: 'Company Assessment',
          icon: Icons.psychology_outlined,
          accentColor: const Color(0xFF2E7D32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._preworkChecklistTiles(),
              const SizedBox(height: 20),
              const _Subheader('SWOT Analysis'),
              const SizedBox(height: 8),
              _SwotGrid(
                strengths: swotStrengths,
                weaknesses: swotWeaknesses,
                opportunities: swotOpportunities,
                threats: swotThreats,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _porterFiveForcesCard(),
        const SizedBox(height: 16),
        _historicalDataCard(),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'External Assessment',
          icon: Icons.public_outlined,
          accentColor: const Color(0xFF2E7D32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._externalAssessmentFields(context),
              const SizedBox(height: 16),
              ..._managementDiscussionFields(),
              const SizedBox(height: 20),
              _saveAndContinueButton(),
            ],
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Local widgets ----------------------------- */

class _TwoCol extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoCol({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    if (!wide) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _PageScroll extends StatelessWidget {
  final List<Widget> children;
  const _PageScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    const maxW = 920.0;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFAFBFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.1), width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.1),
                          primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _Subheader extends StatelessWidget {
  final String text;
  const _Subheader(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _BodyBullets extends StatelessWidget {
  final List<String> items;
  const _BodyBullets(this.items);
  @override
  Widget build(BuildContext context) => Column(
    children: items
        .map(
          (t) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(t)),
            ],
          ),
        )
        .toList(),
  );
}

/// Bold tag + body (e.g. "Trends: …") for analysis prompts.
class _TaggedBullets extends StatelessWidget {
  final List<({String tag, String text})> items;
  const _TaggedBullets(this.items);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      TextSpan(
                        text: '${e.tag}: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: e.text),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Input format for a financial metric cell.
enum FinancialMetricFormat {
  currency,
  percent,
  number;

  static FinancialMetricFormat forRowKey(String key) {
    switch (key) {
      case 'gross_margin_pct':
      case 'ebitda_pct':
        return FinancialMetricFormat.percent;
      case 'revenue':
      case 'gross_margin_dollar':
      case 'ebitda_dollar':
        return FinancialMetricFormat.currency;
      default:
        return FinancialMetricFormat.number;
    }
  }

  static FinancialMetricFormat fromStored(String? raw) {
    switch (raw) {
      case 'currency':
        return FinancialMetricFormat.currency;
      case 'percent':
        return FinancialMetricFormat.percent;
      default:
        return FinancialMetricFormat.number;
    }
  }

  String get storageKey {
    switch (this) {
      case FinancialMetricFormat.currency:
        return 'currency';
      case FinancialMetricFormat.percent:
        return 'percent';
      case FinancialMetricFormat.number:
        return 'number';
    }
  }

  String get shortLabel {
    switch (this) {
      case FinancialMetricFormat.currency:
        return '\$';
      case FinancialMetricFormat.percent:
        return '%';
      case FinancialMetricFormat.number:
        return '#';
    }
  }
}

/// Financial metrics for the last two complete fiscal years plus YTD current year
/// and an auto-calculated year-end projection column.
class _HistoricalFinancialTable extends StatefulWidget {
  static const _headerColor = Color(0xFF7D1F2E);
  static const _sectionHeaderColor = Color(0xFF111827);
  static const _projectionFill = Color(0xFFF1F5F9);

  final List<String> columnIds;
  final List<String> columnLabels;
  final String projectionColumnLabel;
  final String ytdColumnId;
  final int ytdAsOfQuarter;
  final ValueChanged<int>? onYtdAsOfQuarterChanged;
  final String? Function(String rowKey) projectFinancialRow;
  final String? Function(int index, String metricKey) projectAdditionalMetric;
  final List<String> rowKeys;
  final List<String> rowLabels;
  final Map<String, Map<String, TextEditingController>> ctrls;
  final List<String> additionalMetricKeys;
  final List<TextEditingController> additionalMetricLabels;
  final Map<String, Map<String, TextEditingController>> additionalMetricCtrls;
  final List<FinancialMetricFormat> additionalMetricFormats;
  final void Function(int index, FinancialMetricFormat format)?
      onAdditionalMetricFormatChanged;

  const _HistoricalFinancialTable({
    required this.columnIds,
    required this.columnLabels,
    required this.projectionColumnLabel,
    required this.ytdColumnId,
    required this.ytdAsOfQuarter,
    required this.projectFinancialRow,
    required this.projectAdditionalMetric,
    required this.rowKeys,
    required this.rowLabels,
    required this.ctrls,
    required this.additionalMetricKeys,
    required this.additionalMetricLabels,
    required this.additionalMetricCtrls,
    required this.additionalMetricFormats,
    this.onYtdAsOfQuarterChanged,
    this.onAdditionalMetricFormatChanged,
  });

  @override
  State<_HistoricalFinancialTable> createState() =>
      _HistoricalFinancialTableState();
}

class _HistoricalFinancialTableState extends State<_HistoricalFinancialTable> {
  final List<VoidCallback> _ytdListeners = [];
  final List<VoidCallback> _syncListeners = [];
  bool _syncingFinancialFields = false;

  @override
  void initState() {
    super.initState();
    _attachYtdListeners();
    _attachFinancialSyncListeners();
  }

  @override
  void didUpdateWidget(covariant _HistoricalFinancialTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ytdColumnId != widget.ytdColumnId) {
      _detachYtdListeners(oldWidget);
      _attachYtdListeners();
    }
    if (oldWidget.columnIds != widget.columnIds ||
        oldWidget.rowKeys != widget.rowKeys) {
      _detachFinancialSyncListeners();
      _attachFinancialSyncListeners();
    }
  }

  @override
  void dispose() {
    _detachYtdListeners(widget);
    _detachFinancialSyncListeners();
    super.dispose();
  }

  void _attachFinancialSyncListeners() {
    for (final columnId in widget.columnIds) {
      final columnCtrls = widget.ctrls[columnId];
      if (columnCtrls == null) continue;

      for (final rowKey in widget.rowKeys) {
        final field = HistoricalFinancialSync.fieldForRowKey(rowKey);
        final controller = columnCtrls[rowKey];
        if (field == null || controller == null) continue;

        void onChanged() => _onFinancialFieldChanged(columnId, field);
        controller.addListener(onChanged);
        _syncListeners.add(() => controller.removeListener(onChanged));
      }
    }
  }

  void _detachFinancialSyncListeners() {
    for (final remove in _syncListeners) {
      remove();
    }
    _syncListeners.clear();
  }

  void _onFinancialFieldChanged(
    String columnId,
    HistoricalFinancialField field,
  ) {
    if (_syncingFinancialFields) return;

    _syncingFinancialFields = true;
    try {
      HistoricalFinancialSync.syncColumn(
        columnCtrls: widget.ctrls[columnId]!,
        source: field,
      );
    } finally {
      _syncingFinancialFields = false;
    }

    if (columnId == widget.ytdColumnId && mounted) {
      setState(() {});
    }
  }

  void _attachYtdListeners() {
    final ytdId = widget.ytdColumnId;
    void onChanged() {
      if (mounted) setState(() {});
    }

    for (final key in widget.rowKeys) {
      final controller = widget.ctrls[ytdId]?[key];
      if (controller == null) continue;
      controller.addListener(onChanged);
      _ytdListeners.add(() => controller.removeListener(onChanged));
    }
    for (final metricKey in widget.additionalMetricKeys) {
      final controller = widget.additionalMetricCtrls[ytdId]?[metricKey];
      if (controller == null) continue;
      controller.addListener(onChanged);
      _ytdListeners.add(() => controller.removeListener(onChanged));
    }
  }

  void _detachYtdListeners(_HistoricalFinancialTable target) {
    for (final remove in _ytdListeners) {
      remove();
    }
    _ytdListeners.clear();
  }

  Widget _metricField({
    required TextEditingController controller,
    required FinancialMetricFormat format,
    required InputDecoration decoration,
  }) {
    final formatters = <TextInputFormatter>[
      if (format == FinancialMetricFormat.currency) CurrencyInputFormatter(),
      if (format == FinancialMetricFormat.percent) PercentInputFormatter(),
    ];

    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: format == FinancialMetricFormat.number,
      ),
      inputFormatters: formatters,
      style: const TextStyle(fontSize: 13),
      decoration: decoration.copyWith(
        suffixText: format == FinancialMetricFormat.percent ? '%' : null,
        hintText: switch (format) {
          FinancialMetricFormat.currency => '0.00',
          FinancialMetricFormat.percent => '0.00',
          FinancialMetricFormat.number => '0',
        },
      ),
    );
  }

  Widget _projectionCell({
    required String? value,
    required FinancialMetricFormat format,
    required BoxDecoration decoration,
  }) {
    final display = value?.trim().isNotEmpty == true ? value!.trim() : '—';
    final suffix = format == FinancialMetricFormat.percent ? '%' : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: decoration,
      child: Text(
        suffix != null && display != '—' ? '$display$suffix' : display,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: display == '—' ? Colors.grey.shade500 : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _columnHeader({
    required String label,
    required TextStyle? headerStyle,
    required String columnId,
  }) {
    if (columnId != widget.ytdColumnId) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Center(child: Text(label, style: headerStyle)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: headerStyle, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: widget.ytdAsOfQuarter.clamp(1, 4),
                isDense: true,
                dropdownColor: _HistoricalFinancialTable._headerColor,
                iconEnabledColor: Colors.white,
                style: headerStyle?.copyWith(fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('As of Q1')),
                  DropdownMenuItem(value: 2, child: Text('As of Q2')),
                  DropdownMenuItem(value: 3, child: Text('As of Q3')),
                  DropdownMenuItem(value: 4, child: Text('As of Q4')),
                ],
                onChanged: widget.onYtdAsOfQuarterChanged == null
                    ? null
                    : (value) {
                        if (value == null) return;
                        widget.onYtdAsOfQuarterChanged!(value);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        );
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
    final border = BorderSide(color: Colors.grey.shade300);
    final inputDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: border,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: border,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
    );
    final projectionDecoration = BoxDecoration(
      color: _HistoricalFinancialTable._projectionFill,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFCBD5E1)),
    );
    final displayColumnCount = widget.columnIds.length + 1;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FlexColumnWidth(1.25),
        for (var i = 0; i < displayColumnCount; i++)
          i + 1: const FlexColumnWidth(1),
      },
      border: TableBorder.all(color: const Color(0xFFE2E8F0)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _HistoricalFinancialTable._headerColor),
          children: [
            const TableCell(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 12, 8, 12),
                child: SizedBox.shrink(),
              ),
            ),
            ...List.generate(widget.columnIds.length, (i) {
              return TableCell(
                child: _columnHeader(
                  label: widget.columnLabels[i],
                  headerStyle: headerStyle,
                  columnId: widget.columnIds[i],
                ),
              );
            }),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Center(
                  child: Text(
                    widget.projectionColumnLabel,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
        ...List.generate(widget.rowKeys.length, (ri) {
          final rowKey = widget.rowKeys[ri];
          final format = FinancialMetricFormat.forRowKey(rowKey);
          return TableRow(
            decoration: BoxDecoration(
              color: ri.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
            ),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                  child: Text(widget.rowLabels[ri], style: labelStyle),
                ),
              ),
              ...List.generate(widget.columnIds.length, (ci) {
                final id = widget.columnIds[ci];
                return TableCell(
                  verticalAlignment: TableCellVerticalAlignment.top,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _metricField(
                      controller: widget.ctrls[id]![rowKey]!,
                      format: format,
                      decoration: inputDecoration,
                    ),
                  ),
                );
              }),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _projectionCell(
                    value: widget.projectFinancialRow(rowKey),
                    format: format,
                    decoration: projectionDecoration,
                  ),
                ),
              ),
            ],
          );
        }),
        TableRow(
          decoration: const BoxDecoration(
            color: _HistoricalFinancialTable._sectionHeaderColor,
          ),
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Text(
                  'Additional Metrics',
                  style: headerStyle,
                ),
              ),
            ),
            ...List.generate(
              displayColumnCount,
              (_) => const TableCell(
                child: SizedBox(height: 44),
              ),
            ),
          ],
        ),
        ...List.generate(widget.additionalMetricKeys.length, (ri) {
          final metricKey = widget.additionalMetricKeys[ri];
          final format = widget.additionalMetricFormats[ri];
          return TableRow(
            decoration: BoxDecoration(
              color: ri.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
            ),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.additionalMetricLabels[ri],
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(
                            hintText: 'Metric name',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<FinancialMetricFormat>(
                        value: widget.additionalMetricFormats[ri],
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: FinancialMetricFormat.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.shortLabel),
                              ),
                            )
                            .toList(),
                        onChanged: widget.onAdditionalMetricFormatChanged == null
                            ? null
                            : (item) {
                                if (item == null) return;
                                widget.onAdditionalMetricFormatChanged!(ri, item);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              ...List.generate(widget.columnIds.length, (ci) {
                final id = widget.columnIds[ci];
                return TableCell(
                  verticalAlignment: TableCellVerticalAlignment.top,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _metricField(
                      controller: widget.additionalMetricCtrls[id]![metricKey]!,
                      format: format,
                      decoration: inputDecoration,
                    ),
                  ),
                );
              }),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _projectionCell(
                    value: widget.projectAdditionalMetric(ri, metricKey),
                    format: format,
                    decoration: projectionDecoration,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _NumberedLines extends StatelessWidget {
  final List<String> items;
  const _NumberedLines(this.items);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: Text('${i + 1}.', style: style),
                ),
                Expanded(child: Text(items[i], style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  final Widget? labelTrailing;
  const _LabeledTextField({
    required this.label,
    required this.hint,
    this.controller,
    this.maxLines = 3,
    this.labelTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (labelTrailing != null) labelTrailing!,
              ],
            ),
          ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _roundedDecoration(context, hint),
        ),
      ],
    );
  }
}

InputDecoration _roundedDecoration(BuildContext context, String hint) {
  final primary = Theme.of(context).colorScheme.primary;
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primary, width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

/* ----------------------------- SWOT + Financial ---------------------------- */

class _SwotGrid extends StatelessWidget {
  final List<TextEditingController> strengths;
  final List<TextEditingController> weaknesses;
  final List<TextEditingController> opportunities;
  final List<TextEditingController> threats;

  const _SwotGrid({
    required this.strengths,
    required this.weaknesses,
    required this.opportunities,
    required this.threats,
  });

  Widget _swotPair(
    BuildContext context, {
    required Widget left,
    required Widget right,
    required bool isWide,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        left,
        const SizedBox(height: 12),
        right,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return Column(
      children: [
        _swotPair(
          context,
          isWide: isWide,
          left: _SwotCell(
            title: 'Strengths',
            color: const Color(0xFF10B981),
            gradient: const LinearGradient(
              colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            itemLabelPrefix: 'Strength',
            guidingQuestions: const [
              'What does your organization currently do well?',
              'What separates you from your competitors?',
              'What are your most valuable internal resources?',
              'What tangible assets do you have?',
              'What is your biggest strength?',
            ],
            controllers: strengths,
          ),
          right: _SwotCell(
            title: 'Weaknesses',
            color: const Color(0xFFEF4444),
            gradient: const LinearGradient(
              colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            itemLabelPrefix: 'Weakness',
            guidingQuestions: const [
              'What does your organization do poorly?',
              'What do you currently lack (product, resource, process)?',
              'What do your competitors do better than you?',
              'What limitations are holding your organization back?',
              'What processes or products need improvement?',
            ],
            controllers: weaknesses,
          ),
        ),
        const SizedBox(height: 12),
        _swotPair(
          context,
          isWide: isWide,
          left: _SwotCell(
            title: 'Opportunities',
            color: const Color(0xFF3B82F6),
            gradient: const LinearGradient(
              colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            itemLabelPrefix: 'Opportunity',
            guidingQuestions: const [
              'What opportunities does your organization have?',
              'How can you leverage your unique company strengths?',
              'Are there trends that you can take advantage of?',
              'How can you capitalize on marketing or press opportunities?',
              'Any emerging needs for your product or service?',
            ],
            controllers: opportunities,
          ),
          right: _SwotCell(
            title: 'Threats',
            color: const Color(0xFFF59E0B),
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            itemLabelPrefix: 'Threat',
            guidingQuestions: const [
              'What emerging competitors should you keep an eye on?',
              'Are there weaknesses exposing your organization to risk?',
              'Have you or could you experience negative press that could reduce market share?',
              'Is there a chance of changing customer attitudes towards your company?',
            ],
            controllers: threats,
          ),
        ),
      ],
    );
  }
}

class _SwotCell extends StatelessWidget {
  final String title;
  final String itemLabelPrefix;
  final Color color;
  final LinearGradient gradient;
  final List<TextEditingController> controllers;
  final List<String> guidingQuestions;

  const _SwotCell({
    required this.title,
    required this.itemLabelPrefix,
    required this.color,
    required this.gradient,
    required this.controllers,
    this.guidingQuestions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bulletStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.35,
          color: Colors.grey.shade800,
        );
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (guidingQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...guidingQuestions.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: bulletStyle),
                    Expanded(child: Text(q, style: bulletStyle)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(controllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < controllers.length - 1 ? 8 : 0,
              ),
              child: TextField(
                controller: controllers[index],
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: _roundedDecoration(
                  context,
                  '$itemLabelPrefix ${index + 1}',
                ).copyWith(
                  fillColor: Colors.white.withOpacity(0.8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

