import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'company_profile_session_cache.dart';
import 'strategic_areas_repository.dart';

/// One row of financial targets on the strategic one-pager.
class OnePagerFinancialRow {
  const OnePagerFinancialRow({
    required this.yearLabel,
    required this.revenue,
    required this.grossMarginPct,
    required this.ebitda,
    required this.ebitdaPct,
  });

  final String yearLabel;
  final String revenue;
  final String grossMarginPct;
  final String ebitda;
  final String ebitdaPct;
}

/// Snapshot of strategic one-pager fields for PDF export.
class OnePagerPdfData {
  const OnePagerPdfData({
    required this.companyName,
    this.logoBytes,
    required this.vision,
    required this.mission,
    required this.coreValues,
    required this.financialRows,
    required this.areas,
    required this.areaGoals,
  });

  final String companyName;
  final Uint8List? logoBytes;
  final String vision;
  final String mission;
  final List<String> coreValues;
  final List<OnePagerFinancialRow> financialRows;
  final List<String> areas;
  final Map<String, AreaGoalsData> areaGoals;

  OnePagerPdfData copyWith({Uint8List? logoBytes}) => OnePagerPdfData(
        companyName: companyName,
        logoBytes: logoBytes ?? this.logoBytes,
        vision: vision,
        mission: mission,
        coreValues: coreValues,
        financialRows: financialRows,
        areas: areas,
        areaGoals: areaGoals,
      );

  static OnePagerFinancialRow _financialRowFromMaps({
    required String yearLabel,
    required String storagePrefix,
    required Map<String, dynamic> saved,
    required Map<String, dynamic> year3,
    required String revKey,
    required String grossKey,
    required String ebitdaKey,
    required String marginKey,
    String? legacyRevKey,
    String? legacyEbitdaKey,
  }) {
    String firstNonEmpty(List<String> candidates) {
      for (final c in candidates) {
        if (c.trim().isNotEmpty) return c.trim();
      }
      return '';
    }

    return OnePagerFinancialRow(
      yearLabel: yearLabel,
      revenue: firstNonEmpty([
        (saved['${storagePrefix}_revenue'] ?? '').toString(),
        if (legacyRevKey != null) (saved[legacyRevKey] ?? '').toString(),
        (year3[revKey] ?? '').toString(),
      ]),
      grossMarginPct: firstNonEmpty([
        (saved['${storagePrefix}_gross_margin_pct'] ?? '').toString(),
        (year3[grossKey] ?? '').toString(),
      ]),
      ebitda: firstNonEmpty([
        (saved['${storagePrefix}_ebitda'] ?? '').toString(),
        if (legacyEbitdaKey != null) (saved[legacyEbitdaKey] ?? '').toString(),
        (year3[ebitdaKey] ?? '').toString(),
      ]),
      ebitdaPct: firstNonEmpty([
        (saved['${storagePrefix}_ebitda_pct'] ?? '').toString(),
        (year3[marginKey] ?? '').toString(),
      ]),
    );
  }

  static Future<OnePagerPdfData> fromFirestore(String companyId) async {
    final ref = FirebaseFirestore.instance.collection('companies').doc(companyId);

    Map<String, dynamic> identity = {};
    Map<String, dynamic> year3 = {};
    Map<String, dynamic> saved = {};
    try {
      final identitySnap = await ref
          .collection('companyIdentity')
          .doc('refine_company_identity')
          .get();
      identity = identitySnap.data() ?? {};
    } catch (_) {}

    try {
      final year3Snap =
          await ref.collection('strategicPlanning').doc('year3_targets').get();
      year3 = year3Snap.data() ?? {};
    } catch (_) {}

    try {
      final visualizationSnap =
          await ref.collection('executeAndMonitor').doc('visualization').get();
      saved = visualizationSnap.data() ?? {};
    } catch (_) {}

    List<String> areas = [];
    Map<String, AreaGoalsData> areaGoals = {};
    try {
      areas = await StrategicAreasRepository.loadAreas(companyId, readOnly: true);
      areaGoals =
          await StrategicAreasRepository.loadPerAreaGoals(companyId, readOnly: true);
    } catch (_) {}

    var companyName = 'Company';
    try {
      final companySnap = await ref.get();
      companyName = firstNonEmpty([
        (companySnap.data()?['companyName'] ?? '').toString(),
      ]);
      if (companyName.isEmpty) companyName = 'Company';
    } catch (_) {}

    final logoBytes = await PlanPdfExport.resolveLogoBytes(companyId: companyId);

    final identityValues = (identity['values_str'] ?? '')
        .toString()
        .split(RegExp(r'[\n,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final coreValues = <String>[
      for (var i = 1; i <= 4; i++)
        firstNonEmpty([
          (saved['value$i'] ?? '').toString(),
          if (i <= identityValues.length) identityValues[i - 1],
        ]),
    ].where((v) => v.isNotEmpty).toList();

    return OnePagerPdfData(
      companyName: companyName,
      logoBytes: logoBytes,
      vision: firstNonEmpty([
        (saved['vision'] ?? '').toString(),
        (identity['vision_str'] ?? '').toString(),
      ]),
      mission: firstNonEmpty([
        (saved['mission'] ?? '').toString(),
        (identity['mission_str'] ?? '').toString(),
      ]),
      coreValues: coreValues,
      financialRows: [
        _financialRowFromMaps(
          yearLabel: 'Y3',
          storagePrefix: 'fin_y3',
          saved: saved,
          year3: year3,
          revKey: 'y3R',
          grossKey: 'y3G',
          ebitdaKey: 'y3E',
          marginKey: 'y3M',
          legacyRevKey: 'revenue',
          legacyEbitdaKey: 'ebitda',
        ),
        _financialRowFromMaps(
          yearLabel: 'Y2',
          storagePrefix: 'fin_y2',
          saved: saved,
          year3: year3,
          revKey: 'y2R',
          grossKey: 'y2G',
          ebitdaKey: 'y2E',
          marginKey: 'y2M',
        ),
        _financialRowFromMaps(
          yearLabel: 'Y1',
          storagePrefix: 'fin_y1',
          saved: saved,
          year3: year3,
          revKey: 'y1R',
          grossKey: 'y1G',
          ebitdaKey: 'y1E',
          marginKey: 'y1M',
          legacyRevKey: 'year1_revenue',
          legacyEbitdaKey: 'year1_ebitda',
        ),
      ],
      areas: areas,
      areaGoals: areaGoals,
    );
  }

  static String firstNonEmpty(List<String> candidates) {
    for (final c in candidates) {
      if (c.trim().isNotEmpty) return c.trim();
    }
    return '';
  }
}

/// PDF exports for Year 1 plan summary and strategic one-pager.
class PlanPdfExport {
  static const _accent = PdfColor.fromInt(0xFF2E7D32);
  static const _areaHeader = PdfColor.fromInt(0xFF4B5563);
  static const _areaBody = PdfColor.fromInt(0xFFE8F4FC);
  static const _titleColor = PdfColor.fromInt(0xFF1E293B);

  static Future<Uint8List?> resolveLogoBytes({String? companyId}) async {
    final cached = CompanyProfileSessionCache.logoBytes;
    if (cached != null && cached.isNotEmpty) return cached;

    if (companyId == null || companyId.isEmpty) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      final logoUrl = (snap.data()?['logoUrl'] ?? '').toString().trim();
      if (logoUrl.isEmpty) return null;

      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> downloadYearOnePlan({required String? companyId}) async {
    if (companyId == null || companyId.isEmpty) {
      throw StateError('Company not loaded');
    }

    final data = await _loadPlanData(companyId);
    final doc = pw.Document(title: 'Year 1 Strategic Plan', author: 'MyCatalystPlan');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _title('Year 1 Strategic Plan'),
          pw.SizedBox(height: 6),
          _metaLine(),
          pw.SizedBox(height: 20),
          _section('3-Year Targets'),
          _kv('Year 3 Revenue', data.year3Revenue),
          _kv('Year 3 EBITDA', data.year3Ebitda),
          _kv('Year 1 Revenue', data.year1Revenue),
          _kv('Year 1 EBITDA', data.year1Ebitda),
          pw.SizedBox(height: 16),
          _section('Strategic Areas & Year 1 Goals'),
          ...data.areaGoals.entries.map(
            (e) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Goal: ${_orDash(e.value.goal)}'),
                if (e.value.initiatives.any((i) => i.trim().isNotEmpty)) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Initiatives:'),
                  ...e.value.initiatives
                      .where((i) => i.trim().isNotEmpty)
                      .map((i) => pw.Bullet(text: i)),
                ],
                pw.SizedBox(height: 12),
              ],
            ),
          ),
          if (data.risks.isNotEmpty) ...[
            _section('Key Risks'),
            ...data.risks.map(
              (r) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(r['desc']?.toString() ?? '—',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if ((r['strategicArea'] ?? '').toString().trim().isNotEmpty)
                    pw.Text(
                      'Focus area: ${r['strategicArea']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.Text(
                    'Impact: ${r['impact']} • Likelihood: ${r['likelihood']} • Severity: ${r['severity']}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text('Mitigation: ${_orDash(r['strategy'])}'),
                  pw.SizedBox(height: 8),
                ],
              ),
            ),
          ],
          if (data.budgetAllocations.isNotEmpty) ...[
            _section('Budget Allocation'),
            ...data.budgetAllocations.entries.map(
              (e) => _kv(e.key, '${e.value}%'),
            ),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'mycatalystplan_year1_plan.pdf',
    );
  }

  static Future<void> downloadOnePager({
    OnePagerPdfData? data,
    String? companyId,
  }) async {
    final OnePagerPdfData planData;
    if (data != null) {
      planData = data.logoBytes == null && companyId != null
          ? data.copyWith(
              logoBytes: await resolveLogoBytes(companyId: companyId),
            )
          : data;
    } else if (companyId != null && companyId.isNotEmpty) {
      planData = await OnePagerPdfData.fromFirestore(companyId);
    } else {
      throw StateError('Company not loaded');
    }

    final doc = pw.Document(
      title: '${planData.companyName} Strategic Plan',
      author: 'MyCatalystPlan',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _onePagerHeader(planData, compact: true),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _onePagerCard(
                    title: 'Vision',
                    compact: true,
                    fillColor: const PdfColor.fromInt(0xFFEFF6FF),
                    children: [
                      _onePagerBodyText(
                        _orDash(planData.vision),
                        compact: true,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _onePagerCard(
                    title: 'Mission',
                    compact: true,
                    fillColor: const PdfColor.fromInt(0xFFEFF6FF),
                    children: [
                      _onePagerBodyText(
                        _orDash(planData.mission),
                        compact: true,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _onePagerCard(
                    title: 'Core Values',
                    compact: true,
                    fillColor: const PdfColor.fromInt(0xFFF0FDF4),
                    children: planData.coreValues.isEmpty
                        ? [_onePagerBodyText('—', compact: true)]
                        : planData.coreValues
                            .map(
                              (v) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 2),
                                child: _onePagerBodyText(v, compact: true, maxLines: 2),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            _onePagerCard(
              title: 'Financial Targets',
              compact: true,
              children: [
                pw.TableHelper.fromTextArray(
                  headers: const [
                    '',
                    'Rev \$',
                    'Gross Margin %',
                    'EBITDA \$',
                    'EBITDA %',
                  ],
                  data: planData.financialRows
                      .map(
                        (row) => [
                          row.yearLabel,
                          _orDash(row.revenue),
                          _orDash(row.grossMarginPct),
                          _orDash(row.ebitda),
                          _orDash(row.ebitdaPct),
                        ],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 7,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF374151),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Strategic Focus Areas',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
              ),
            ),
            pw.SizedBox(height: 4),
            if (planData.areas.isEmpty)
              _onePagerBodyText(
                'No strategic focus areas saved yet.',
                compact: true,
              )
            else
              pw.Expanded(
                child: _onePagerFocusAreasRow(planData, compact: true),
              ),
          ],
        ),
      ),
    );

    final safeName = planData.companyName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final filename = safeName.isEmpty
        ? 'mycatalystplan_one_pager.pdf'
        : '${safeName}_strategic_plan.pdf';

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: filename,
    );
  }

  static pw.Widget _onePagerHeader(
    OnePagerPdfData planData, {
    bool compact = false,
  }) {
    final logoSize = compact ? 44.0 : 72.0;
    final titleSize = compact ? 15.0 : 22.0;
    pw.Widget? logoWidget;
    if (planData.logoBytes != null && planData.logoBytes!.isNotEmpty) {
      logoWidget = pw.Container(
        width: logoSize,
        height: logoSize,
        alignment: pw.Alignment.center,
        child: pw.Image(
          pw.MemoryImage(planData.logoBytes!),
          fit: pw.BoxFit.contain,
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoWidget != null) ...[
          logoWidget,
          pw.SizedBox(width: compact ? 10 : 16),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${planData.companyName} Strategic Plan',
                style: pw.TextStyle(
                  fontSize: titleSize,
                  fontWeight: pw.FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              if (!compact) ...[
                pw.SizedBox(height: 4),
                _metaLine(),
              ] else
                pw.Text(
                  'Generated ${DateTime.now().toString().split('.').first}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _onePagerCard({
    required String title,
    required List<pw.Widget> children,
    PdfColor fillColor = PdfColors.grey100,
    bool compact = false,
  }) {
    final padding = compact ? 6.0 : 12.0;
    final titleSize = compact ? 8.0 : 12.0;
    final gap = compact ? 4.0 : 10.0;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: fillColor,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(compact ? 4 : 6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: titleSize,
              fontWeight: pw.FontWeight.bold,
              color: _titleColor,
            ),
          ),
          pw.SizedBox(height: gap),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _onePagerBodyText(
    String text, {
    bool compact = false,
    int? maxLines,
  }) =>
      pw.Text(
        text,
        maxLines: maxLines,
        style: pw.TextStyle(
          fontSize: compact ? 7.5 : 10,
          height: compact ? 1.25 : 1.35,
        ),
      );

  static pw.Widget _onePagerFocusAreasRow(
    OnePagerPdfData planData, {
    bool compact = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < planData.areas.length; i++) ...[
          if (i > 0) pw.SizedBox(width: compact ? 4 : 8),
          pw.Expanded(
            child: _onePagerFocusAreaColumn(
              area: planData.areas[i],
              goals: planData.areaGoals[planData.areas[i]],
              compact: compact,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _onePagerFocusAreaColumn({
    required String area,
    AreaGoalsData? goals,
    bool compact = false,
  }) {
    final initiatives = goals?.initiatives
            .where((i) => i.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final headerPad = compact
        ? const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5)
        : const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10);
    final bodyPad = compact
        ? const pw.EdgeInsets.all(5)
        : const pw.EdgeInsets.all(10);
    final labelSize = compact ? 7.0 : 9.0;
    final headerFontSize = compact ? 7.0 : 9.0;
    final initiativeGap = compact ? 3.0 : 6.0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: headerPad,
            decoration: const pw.BoxDecoration(
              color: _areaHeader,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(3),
                topRight: pw.Radius.circular(3),
              ),
            ),
            child: pw.Text(
              area.toUpperCase(),
              textAlign: pw.TextAlign.center,
              maxLines: 2,
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: bodyPad,
              decoration: const pw.BoxDecoration(
                color: _areaBody,
                borderRadius: pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(3),
                  bottomRight: pw.Radius.circular(3),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GOAL:',
                    style: pw.TextStyle(
                      fontSize: labelSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  _onePagerBodyText(
                    _orDash(goals?.goal),
                    compact: compact,
                    maxLines: compact ? 2 : null,
                  ),
                  if (initiatives.isNotEmpty) ...[
                    pw.SizedBox(height: compact ? 4 : 8),
                    for (var j = 0; j < initiatives.length; j++) ...[
                      pw.Text(
                        'Initiative ${j + 1}:',
                        style: pw.TextStyle(
                          fontSize: labelSize,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '✓ ',
                            style: pw.TextStyle(fontSize: labelSize),
                          ),
                          pw.Expanded(
                            child: _onePagerBodyText(
                              initiatives[j],
                              compact: compact,
                              maxLines: compact ? 2 : null,
                            ),
                          ),
                        ],
                      ),
                      if (j < initiatives.length - 1)
                        pw.SizedBox(height: initiativeGap),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> downloadCommunicationTemplate() async {
    final doc = pw.Document(
      title: 'Communication Plan Template',
      author: 'MyCatalystPlan',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _title('Strategy Communication Plan Template'),
          pw.SizedBox(height: 6),
          _metaLine(),
          pw.SizedBox(height: 16),
          pw.Text(
            'Use this template to plan how you will communicate strategic priorities to each audience.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'Audience',
              'Key Messages',
              'Channels',
              'Frequency',
              'Owner',
            ],
            data: const [
              ['Leadership Team', '', '', 'Monthly', ''],
              ['All Employees', '', '', 'Quarterly', ''],
              ['Board / Advisors', '', '', 'Quarterly', ''],
              ['External Stakeholders', '', '', 'As needed', ''],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _accent),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'mycatalystplan_communication_template.pdf',
    );
  }

  static Future<_PlanData> _loadPlanData(String companyId) async {
    final ref = FirebaseFirestore.instance.collection('companies').doc(companyId);

    final identitySnap =
        await ref.collection('companyIdentity').doc('refine_company_identity').get();
    final year3Snap =
        await ref.collection('strategicPlanning').doc('year3_targets').get();
    final budgetSnap = await ref.collection('yearOnePlan').doc('budget').get();
    final risksSnap = await ref.collection('yearOnePlan').doc('riskAssessment').get();
    final risksRaw = risksSnap.data()?['risks'];
    final risks = risksRaw is List
        ? risksRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final identity = identitySnap.data() ?? {};
    final year3 = year3Snap.data() ?? {};
    final areas = await StrategicAreasRepository.loadAreas(companyId, readOnly: true);
    final areaGoals =
        await StrategicAreasRepository.loadPerAreaGoals(companyId, readOnly: true);

    final budgetRaw = budgetSnap.data()?['areaAllocations'];
    final budgetAllocations = <String, String>{};
    if (budgetRaw is Map) {
      for (final entry in budgetRaw.entries) {
        budgetAllocations[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    return _PlanData(
      vision: (identity['vision_str'] ?? '').toString(),
      mission: (identity['mission_str'] ?? '').toString(),
      year3Revenue: (year3['y3R'] ?? '').toString(),
      year3Ebitda: (year3['y3E'] ?? '').toString(),
      year1Revenue: (year3['y1R'] ?? '').toString(),
      year1Ebitda: (year3['y1E'] ?? '').toString(),
      areas: areas,
      areaGoals: areaGoals,
      budgetAllocations: budgetAllocations,
      risks: risks,
    );
  }

  static pw.Widget _title(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
        ),
      );

  static pw.Widget _section(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6, top: 4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
      );

  static pw.Widget _metaLine() => pw.Text(
        'Generated ${DateTime.now().toString().split('.').first}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      );

  static pw.Widget _kv(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: _orDash(value)),
            ],
          ),
        ),
      );

  static String _orDash(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }
}

class _PlanData {
  const _PlanData({
    required this.vision,
    required this.mission,
    required this.year3Revenue,
    required this.year3Ebitda,
    required this.year1Revenue,
    required this.year1Ebitda,
    required this.areas,
    required this.areaGoals,
    required this.budgetAllocations,
    required this.risks,
  });

  final String vision;
  final String mission;
  final String year3Revenue;
  final String year3Ebitda;
  final String year1Revenue;
  final String year1Ebitda;
  final List<String> areas;
  final Map<String, AreaGoalsData> areaGoals;
  final Map<String, String> budgetAllocations;
  final List<Map<String, dynamic>> risks;
}
