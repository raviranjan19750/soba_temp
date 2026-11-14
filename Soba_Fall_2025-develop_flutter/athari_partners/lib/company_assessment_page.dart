import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyAssessmentPage extends StatefulWidget {
  const CompanyAssessmentPage({super.key});

  @override
  State<CompanyAssessmentPage> createState() => _CompanyAssessmentPageState();
}

class _CompanyAssessmentPageState extends State<CompanyAssessmentPage> {
  final Map<String, bool> prework = {
    'Executive Management/Employee Survey': false,
    'Gather and analyze historical data': false,
    'Conduct SWOT analysis': false,
    'Customer insights and market research': false,
    'Financial and key metrics analysis (last 3 years)': false,
  };

  // SWOT controllers
  final swotStrengths = TextEditingController();
  final swotWeaknesses = TextEditingController();
  final swotOpportunities = TextEditingController();
  final swotThreats = TextEditingController();

  // Financials map by year/field
  final years = const [2022, 2023, 2024];
  final fields = const [
    'Revenue',
    'Gross margin \$',
    'Gross margin %',
    'EBITDA \$',
    'EBITDA %',
  ];
  late final Map<int, Map<String, TextEditingController>> finCtrls;

  // External assessment
  final pestelP = TextEditingController();
  final pestelE = TextEditingController();
  final pestelS = TextEditingController();
  final pestelT = TextEditingController();

  final porter = TextEditingController();
  final benchmarking = TextEditingController();

  @override
  void initState() {
    super.initState();
    finCtrls = {
      for (final y in years)
        y: {for (final f in fields) f: TextEditingController()},
    };
    _loadCompanyId();
  }

  @override
  void dispose() {
    for (final y in years) {
      for (final f in fields) {
        finCtrls[y]![f]!.dispose();
      }
    }
    swotStrengths.dispose();
    swotWeaknesses.dispose();
    swotOpportunities.dispose();
    swotThreats.dispose();
    pestelP.dispose();
    pestelE.dispose();
    pestelS.dispose();
    pestelT.dispose();
    porter.dispose();
    benchmarking.dispose();
    super.dispose();
  }

  // Firebase loading/saving
  String? _companyId;

  Future<void> _loadCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists && userDoc.data() != null) {
      _companyId = userDoc['companyId'];
      await _loadAssessmentValues();
      setState(() {});
    }
  }

  Future<void> _loadAssessmentValues() async {
    if (_companyId == null) return;

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
      swotStrengths.text = data['strengths'] ?? '';
      swotWeaknesses.text = data['weaknesses'] ?? '';
      swotOpportunities.text = data['opportunities'] ?? '';
      swotThreats.text = data['threats'] ?? '';
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
      porter.text = d['porter'] ?? '';
      benchmarking.text = d['benchmarking'] ?? '';
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
  }

  Future<void> _savePrework() async {
    if (_companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('pre_work');
    await ref.set(prework, SetOptions(merge: true));
  }

  Future<void> _saveSwot() async {
    if (_companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyAssessment')
        .doc('swot_analysis');
    await ref.set({
      'strengths': swotStrengths.text.trim(),
      'weaknesses': swotWeaknesses.text.trim(),
      'opportunities': swotOpportunities.text.trim(),
      'threats': swotThreats.text.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveExternalAssessment() async {
    if (_companyId == null) return;
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
      'porter': porter.text.trim(),
      'benchmarking': benchmarking.text.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveAssessment() async {
    try {
      await _savePrework();
      await _saveSwot();
      await _saveExternalAssessment();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Assessment saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      children: [
        _SectionCard(
          title: 'Company Assessment',
          icon: Icons.psychology_outlined,
          accentColor: const Color(0xFF6366F1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Subheader('Pre-Work'),
              ...prework.entries.map(
                (e) => CheckboxListTile(
                  value: e.value,
                  onChanged: (v) => setState(() => prework[e.key] = v ?? false),
                  title: Text(e.key),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              _Subheader('SWOT Analysis'),
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
        _SectionCard(
          title: 'Gather and analyze historical data and metrics',
          icon: Icons.analytics_outlined,
          accentColor: const Color(0xFF06B6D4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _BodyBullets([
                'Financials: Revenue, gross margin, net income, EBITDA, cash flow trends (2–3 years)',
                'Customer: Retention rates, churn, NPS/satisfaction scores, acquisition cost',
                'Operations: Productivity, throughput, cycle times, quality/defect rates',
                'People: Headcount, turnover, engagement survey results, training investment',
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'External Assessment',
          icon: Icons.public_outlined,
          accentColor: const Color(0xFF8B5CF6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Subheader('Suggested Data to Gather'),
              const _BodyBullets([
                'Market Research: Industry growth rates, size, and trends, competitor benchmarks, pricing trends',
                'Customer Insights: Satisfaction, unmet needs, buying behavior',
                'Competitors: Strengths/weaknesses, market share, differentiation',
                'Macro Environment: Economic, regulatory, technological, and social shifts',
              ]),
              const SizedBox(height: 16),
              const _Subheader('Key Questions'),
              const _BodyBullets([
                'What external trends (market, tech, regulation, customer behavior) could impact us?',
                'How are customer needs or expectations changing?',
                'Where are competitors gaining ground—or losing it?',
                'What external risks pose the biggest threat to growth?',
                'What opportunities exist to expand or differentiate?',
              ]),
              const SizedBox(height: 16),
              Text(
                'PEST or PESTEL Analysis:',
                style: Theme.of(context).textTheme.titleMedium,
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
              const SizedBox(height: 16),
              Text(
                "Porter's Five Forces:",
                style: Theme.of(context).textTheme.titleMedium,
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
              const SizedBox(height: 16),
              const _Subheader('Guidance for Management Discussion'),
              const _BodyBullets([
                'Goal: Align leadership on the most critical strategic gaps & opportunities',
                'Inputs: Management insights, SWOT summary, historical metrics, external assessment',
                'Discussion: Biggest risks to growth? Most attractive opportunities aligned with strengths?',
                'Priorities: Which 2–3 priorities have the biggest impact in the next 1–3 years?',
                'Output: Short list of critical gaps & opportunities and shared alignment on next step of strategic planning',
              ]),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saveAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B7BEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
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
              ),
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

class _LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  const _LabeledTextField({
    required this.label,
    required this.hint,
    this.controller,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
  final TextEditingController strengths;
  final TextEditingController weaknesses;
  final TextEditingController opportunities;
  final TextEditingController threats;

  const _SwotGrid({
    required this.strengths,
    required this.weaknesses,
    required this.opportunities,
    required this.threats,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: isWide ? 2 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SwotCell(
          title: 'Strengths',
          color: const Color(0xFF10B981),
          gradient: const LinearGradient(
            colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          hint:
              "List your organization's strengths…\nWhat do you do well? What sets you apart?",
          controller: strengths,
        ),
        _SwotCell(
          title: 'Weaknesses',
          color: const Color(0xFFEF4444),
          gradient: const LinearGradient(
            colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          hint:
              "List your organization's weaknesses…\nWhat are limitations or gaps?",
          controller: weaknesses,
        ),
        _SwotCell(
          title: 'Opportunities',
          color: const Color(0xFF3B82F6),
          gradient: const LinearGradient(
            colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          hint:
              "List your organization's opportunities…\nTrends you can leverage?",
          controller: opportunities,
        ),
        _SwotCell(
          title: 'Threats',
          color: const Color(0xFFF59E0B),
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          hint:
              "List your organization's threats…\nCompetitors, risks, market shifts?",
          controller: threats,
        ),
      ],
    );
  }
}

class _SwotCell extends StatelessWidget {
  final String title;
  final String hint;
  final Color color;
  final LinearGradient gradient;
  final TextEditingController controller;

  const _SwotCell({
    required this.title,
    required this.hint,
    required this.color,
    required this.gradient,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 14),
              decoration: _roundedDecoration(context, hint).copyWith(
                fillColor: Colors.white.withOpacity(0.8),
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
          ),
        ],
      ),
    );
  }
}

class _FinancialYearGrid extends StatelessWidget {
  final List<int> years;
  final List<String> fields;
  final Map<int, Map<String, TextEditingController>> ctrls;

  const _FinancialYearGrid({
    required this.years,
    required this.fields,
    required this.ctrls,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 920;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: years
          .map(
            (y) => _YearCard(
              year: y,
              fields: fields,
              ctrls: ctrls[y]!,
              width: isWide
                  ? (MediaQuery.sizeOf(context).width - 64) / 3
                  : double.infinity,
            ),
          )
          .toList(),
    );
  }
}

class _YearCard extends StatelessWidget {
  final int year;
  final List<String> fields;
  final Map<String, TextEditingController> ctrls;
  final double width;

  const _YearCard({
    required this.year,
    required this.fields,
    required this.ctrls,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EAF0)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$year', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: ctrls[f],
                    keyboardType: f.contains('%')
                        ? TextInputType.number
                        : const TextInputType.numberWithOptions(decimal: true),
                    decoration: _roundedDecoration(context, '$f:'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
