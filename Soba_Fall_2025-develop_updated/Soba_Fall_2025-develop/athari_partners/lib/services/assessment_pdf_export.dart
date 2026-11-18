import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Step 2 assessment answers captured from [CompanyAssessmentPage] state.
class AssessmentStep2Snapshot {
  const AssessmentStep2Snapshot({
    required this.prework,
    required this.swotStrengths,
    required this.swotWeaknesses,
    required this.swotOpportunities,
    required this.swotThreats,
    required this.finColumnLabels,
    required this.finRowLabels,
    required this.finRowValues,
    required this.additionalMetricLabels,
    required this.additionalMetricValues,
    required this.historicalAnalysisNotes,
    required this.customerInsights,
    required this.marketResearchKeyTakeaways,
    required this.pestelP,
    required this.pestelE,
    required this.pestelS,
    required this.pestelT,
    required this.pestelEnv,
    required this.pestelL,
    required this.porter,
    required this.benchmarking,
  });

  final Map<String, bool> prework;
  final List<String> swotStrengths;
  final List<String> swotWeaknesses;
  final List<String> swotOpportunities;
  final List<String> swotThreats;
  final List<String> finColumnLabels;
  final List<String> finRowLabels;
  final List<List<String>> finRowValues;
  final List<String> additionalMetricLabels;
  final List<List<String>> additionalMetricValues;
  final String historicalAnalysisNotes;
  final String customerInsights;
  final String marketResearchKeyTakeaways;
  final String pestelP;
  final String pestelE;
  final String pestelS;
  final String pestelT;
  final String pestelEnv;
  final String pestelL;
  final String porter;
  final String benchmarking;
}

class AssessmentPdfExport {
  static const _accent = PdfColor.fromInt(0xFF2E7D32);

  static Future<void> download({
    required String? companyId,
    required AssessmentStep2Snapshot step2,
    required bool fetchFromFirestore,
  }) async {
    final step1 = fetchFromFirestore && companyId != null
        ? await _loadStep1FromFirestore(companyId)
        : const <String, dynamic>{};

    final doc = pw.Document(
      title: 'MyCatalystPlan Assessment Summary',
      author: 'Athari Partners',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _title('MyCatalystPlan Assessment Summary'),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated ${DateTime.now().toString().split('.').first}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          ..._buildStep1(step1),
          pw.SizedBox(height: 20),
          ..._buildStep2Internal(step2),
          pw.SizedBox(height: 20),
          ..._buildStep2External(step2),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'mycatalystplan_assessment_summary.pdf',
    );
  }

  static Future<Map<String, dynamic>> _loadStep1FromFirestore(
    String companyId,
  ) async {
    final base = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('companyIdentity');

    final backgroundSnap = await base.doc('company_background').get();
    final identitySnap = await base.doc('refine_company_identity').get();

    return {
      'background': backgroundSnap.data() ?? {},
      'identity': identitySnap.data() ?? {},
    };
  }

  static List<pw.Widget> _buildStep1(Map<String, dynamic> step1) {
    final background = step1['background'] as Map<String, dynamic>? ?? {};
    final identity = step1['identity'] as Map<String, dynamic>? ?? {};
    final hasData = background.isNotEmpty || identity.isNotEmpty;

    return [
      _sectionHeading('Step 1: Company Identity'),
      if (!hasData)
        _bodyText('No saved Step 1 responses were found.')
      else ...[
        _subsection('Company Background'),
        _field(
          'What does your company do? Briefly describe your products or services.',
          background['products_services'],
        ),
        _field(
          'What problem does your company solve for its customers?',
          background['customer_problem'],
        ),
        _field(
          'Who are your primary customers or target audience?',
          background['primary_customers'],
        ),
        _field(
          'What industry or industries does your company primarily serve?',
          background['industries_served'],
        ),
        _field(
          'How do you primarily generate revenue?',
          background['revenue_model'],
        ),
        _field(
          'What geographic area does your business serve?',
          background['geographic_area'],
        ),
        _field(
          "What is the company's competitive advantage?",
          background['competitive_advantage'],
        ),
        pw.SizedBox(height: 12),
        _subsection('Mission, Vision & Values'),
        _field('Do you have company values?', _yesNo(identity['values'])),
        _field('Company Values', identity['values_str']),
        _field('Who helped define the values?', identity['values_who_str']),
        ..._valuesSharedFields(identity['values_shared']),
        _field('Do you have a company vision?', _yesNo(identity['vision'])),
        _field('Company Vision', identity['vision_str']),
        _field('Who helped define the vision?', identity['vision_who_str']),
        _field(
          'Does the vision still inspire and align with where we\'re headed?',
          _yesNo(identity['vision_still_inspires']),
        ),
        _field('Do you have a company mission?', _yesNo(identity['mission'])),
        _field('Company Mission', identity['mission_str']),
        _field('Who helped define the mission?', identity['mission_who_str']),
        _field(
          'Is the mission still relevant?',
          _yesNo(identity['mission_still_relevant']),
        ),
        _field(
          'Does the mission still inspire and guide us today?',
          _yesNo(identity['mission_still_inspires']),
        ),
      ],
    ];
  }

  static List<pw.Widget> _valuesSharedFields(dynamic valuesShared) {
    if (valuesShared is! Map) return const [];
    final checked = valuesShared.entries
        .where((e) => e.value == true)
        .map((e) => e.key.toString())
        .toList();
    return [
      _field(
        'Are the values shared?',
        checked.isEmpty ? null : checked.join(', '),
      ),
    ];
  }

  static List<pw.Widget> _buildStep2Internal(AssessmentStep2Snapshot step2) {
    return [
      _sectionHeading('Step 2: Internal Assessment'),
      _subsection('Pre-Work Checklist'),
      ...step2.prework.entries.map(
        (e) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            '${e.value ? '[x]' : '[ ]'} ${e.key}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
      pw.SizedBox(height: 12),
      _subsection('SWOT Analysis'),
      ..._swotSection('Strengths', step2.swotStrengths),
      ..._swotSection('Weaknesses', step2.swotWeaknesses),
      ..._swotSection('Opportunities', step2.swotOpportunities),
      ..._swotSection('Threats', step2.swotThreats),
      pw.SizedBox(height: 12),
      _subsection('Historical Data & Metrics'),
      if (step2.finRowLabels.isNotEmpty) _financialTable(step2),
      pw.SizedBox(height: 8),
      _field('Analysis Notes', step2.historicalAnalysisNotes),
    ];
  }

  static List<pw.Widget> _buildStep2External(AssessmentStep2Snapshot step2) {
    return [
      _sectionHeading('Step 2: External Assessment'),
      _field('Customer Insights', step2.customerInsights),
      _field('Market Research Key Takeaways', step2.marketResearchKeyTakeaways),
      pw.SizedBox(height: 8),
      _subsection('PESTEL Analysis'),
      _field('Political', step2.pestelP),
      _field('Economic', step2.pestelE),
      _field('Social', step2.pestelS),
      _field('Technological', step2.pestelT),
      _field('Environmental', step2.pestelEnv),
      _field('Legal', step2.pestelL),
      pw.SizedBox(height: 8),
      _subsection("Porter's Five Forces"),
      _field('Competitive forces analysis', step2.porter),
      pw.SizedBox(height: 8),
      _subsection('Customer & Competitor Benchmarking'),
      _field('Benchmarking notes', step2.benchmarking),
    ];
  }

  static List<pw.Widget> _swotSection(String title, List<String> items) {
    final filled = items.where((item) => item.trim().isNotEmpty).toList();
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
      ),
      if (filled.isEmpty)
        _bodyText('—')
      else
        ...filled.asMap().entries.map(
              (e) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                child: pw.Text(
                  '${e.key + 1}. ${e.value}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ),
    ];
  }

  static pw.Widget _financialTable(AssessmentStep2Snapshot step2) {
    final headers = ['Metric', ...step2.finColumnLabels];
    final rows = <List<String>>[];

    for (var r = 0; r < step2.finRowLabels.length; r++) {
      final values = r < step2.finRowValues.length
          ? step2.finRowValues[r]
          : List.filled(step2.finColumnLabels.length, '');
      rows.add([
        step2.finRowLabels[r],
        ...values.map(_display),
      ]);
    }

    for (var r = 0; r < step2.additionalMetricLabels.length; r++) {
      final label = step2.additionalMetricLabels[r].trim();
      final values = r < step2.additionalMetricValues.length
          ? step2.additionalMetricValues[r]
          : List.filled(step2.finColumnLabels.length, '');
      if (label.isEmpty && values.every((v) => v.trim().isEmpty)) continue;
      rows.add([
        label.isEmpty ? 'Additional metric ${r + 1}' : label,
        ...values.map(_display),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7D1F2E)),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        for (var i = 1; i < headers.length; i++) i: pw.Alignment.center,
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
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

  static pw.Widget _sectionHeading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
      );

  static pw.Widget _subsection(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  static pw.Widget _field(String label, dynamic value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            _bodyText(_display(value)),
          ],
        ),
      );

  static pw.Widget _bodyText(String text) => pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      );

  static String _display(dynamic value) {
    if (value == null) return '—';
    final text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }

  static String _yesNo(dynamic value) {
    if (value == true) return 'Yes';
    if (value == false) return 'No';
    return '—';
  }
}
