import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// KPIs & Dashboard
/// - Designed to be embedded within a parent page (no Scaffold/AppBar)
/// - Uses only Flutter Material (no extra packages).
class KpisDashboardPage extends StatefulWidget {
  const KpisDashboardPage({super.key});

  @override
  State<KpisDashboardPage> createState() => _KpisDashboardPageState();
}

class _KpisDashboardPageState extends State<KpisDashboardPage> {
  String? companyId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userSnap.exists && userSnap.data() != null) {
      setState(() {
        companyId = userSnap['companyId'];
      });
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return _PageScroll(
      children: [
        _BodyNote(
          'Define key performance indicators (KPIs) to track progress toward your strategic objectives. '
          'Use the Venture Studio dashboard template to visualize and monitor performance.',
        ),
        const SizedBox(height: 12),
        const _PerformanceDashboard(),
        const SizedBox(height: 16),
        _StrategicGoalsTrackingBackend(companyId: companyId!),
        const SizedBox(height: 16),
        const _StrategicInitiativesStatus(),
        const SizedBox(height: 16),
        _ReviewAndUpdateScheduleBackend(companyId: companyId!),
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerRight, child: const _FooterButtons()),
        const SizedBox(height: 24),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   Header note                               */
/* -------------------------------------------------------------------------- */
class _BodyNote extends StatelessWidget {
  final String text;
  const _BodyNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'KPIs & Dashboard',
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Company Performance Dashboard                      */
/* -------------------------------------------------------------------------- */
class _PerformanceDashboard extends StatelessWidget {
  const _PerformanceDashboard();

  @override
  Widget build(BuildContext context) {
    final tiles = [
      const _KpiTile(
        title: 'Revenue YTD',
        value: '\$4.2M',
        deltaText: '+12%',
        deltaPositive: true,
        sublabel: '65% of annual target',
      ),
      const _KpiTile(
        title: 'EBITDA YTD',
        value: '\$840K',
        deltaText: '-5%',
        deltaPositive: false,
        sublabel: '53% of annual target',
      ),
      const _KpiTile(
        title: 'Customer Growth',
        value: '+58',
        deltaText: '+18%',
        deltaPositive: true,
        sublabel: '72% of annual target',
      ),
      const _KpiTile(
        title: 'Strategic Initiatives',
        value: '12/15',
        deltaText: 'On Track',
        deltaPositive: true,
        sublabel: '80% complete • on track',
        pillStyle: true,
      ),
    ];

    return _SectionCard(
      title: 'Company Performance Dashboard',
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cross = w >= 980
              ? 4
              : w >= 720
              ? 2
              : 1;
          return GridView.count(
            shrinkWrap: true,
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: tiles,
          );
        },
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String title;
  final String value;
  final String deltaText;
  final bool deltaPositive;
  final String sublabel;
  final bool pillStyle;

  const _KpiTile({
    required this.title,
    required this.value,
    required this.deltaText,
    required this.deltaPositive,
    required this.sublabel,
    this.pillStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final accentColor = pillStyle
        ? const Color(0xFF3B82F6)
        : deltaPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                deltaText,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _extractProgress(sublabel),
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sublabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  double _extractProgress(String text) {
    final match = RegExp(r'(\d{1,3})%').firstMatch(text);
    if (match != null) {
      final num = double.tryParse(match.group(1) ?? '0');
      return (num ?? 0) / 100;
    }
    return 0.0;
  }
}

/* -------------------------------------------------------------------------- */
/*                           Strategic Goals Tracking (Backend)               */
/* -------------------------------------------------------------------------- */
class _StrategicGoalsTrackingBackend extends StatelessWidget {
  final String companyId;
  const _StrategicGoalsTrackingBackend({required this.companyId});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _GoalRow(
        category: 'Financial',
        goal: 'Establish a financially stable and profitable company.',
        initiatives: [
          'Increase billable hours by 10% over next 12 months.',
          'Achieve sales growth of 10% per year.',
        ],
        measures: '# of billable hours',
        targets: '1.2% increase each month',
        owner: 'John S.',
      ),
      _GoalRow(
        category: 'Customer',
        goal: 'Introduce current products to two new markets.',
        initiatives: [
          'Realize 10% of annual sales from small business market by end of next year.',
        ],
        measures: '# of small business clients',
        targets: '100 clients',
        owner: 'Kim L.',
      ),
    ];

    return _SectionCard(
      title: 'Strategic Goals Tracking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_GoalsTableBackend(companyId: companyId, rows: rows)],
      ),
    );
  }
}

class _GoalsTableBackend extends StatelessWidget {
  final String companyId;
  final List<_GoalRow> rows;
  const _GoalsTableBackend({required this.companyId, required this.rows});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: const Color(0xFF334155),
      fontWeight: FontWeight.w700,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1000),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(160),
            1: FixedColumnWidth(260),
            2: FixedColumnWidth(180),
            3: FixedColumnWidth(160),
            4: FixedColumnWidth(120),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: const Color(0xFFE2E8F0).withOpacity(0.9),
            ),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                for (final h in [
                  'Year 1 Goals',
                  'Year 1 Initiatives',
                  'Measures',
                  'Targets',
                  'Owner',
                  'Q1',
                  'Q2',
                  'Q3',
                  'Q4',
                  '2024',
                ])
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(h, style: headerStyle),
                  ),
              ],
            ),
            for (final row in rows) ...[
              _rowCategory(row.category),
              _rowData(row),
            ],
          ],
        ),
      ),
    );
  }

  TableRow _rowCategory(String category) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFB)),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
        for (int i = 0; i < 9; i++) const SizedBox(),
      ],
    );
  }

  TableRow _rowData(_GoalRow r) {
    Widget checkCell(String id) => Center(
      child: _QuarterCheckBackend(id: id, companyId: companyId),
    );

    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(r.goal)),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: r.initiatives
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(i)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Text(r.measures)),
        Padding(padding: const EdgeInsets.all(12), child: Text(r.targets)),
        Padding(padding: const EdgeInsets.all(12), child: Text(r.owner)),
        checkCell('${r.category}-Q1'),
        checkCell('${r.category}-Q2'),
        checkCell('${r.category}-Q3'),
        checkCell('${r.category}-Q4'),
        const Center(child: _YearBadge(text: '2024')),
      ],
    );
  }
}

class _QuarterCheckBackend extends StatefulWidget {
  final String id;
  final String companyId;
  const _QuarterCheckBackend({required this.id, required this.companyId});

  @override
  State<_QuarterCheckBackend> createState() => _QuarterCheckBackendState();
}

class _QuarterCheckBackendState extends State<_QuarterCheckBackend> {
  bool value = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('executeAndMonitor')
        .doc('kpisAndDashboard');

    final snapshot = await docRef.get();
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      setState(() {
        value = data[widget.id] ?? false;
        loading = false;
      });
    } else {
      setState(() {
        value = false;
        loading = false;
      });
    }
  }

  void _update(bool? v) async {
    if (v == null) return;
    setState(() => value = v);

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('executeAndMonitor')
        .doc('kpisAndDashboard');

    await docRef.set({widget.id: v}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const CircularProgressIndicator(strokeWidth: 2);
    return Checkbox(
      value: value,
      onChanged: _update,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         Review & Update Schedule Backend                  */
/* -------------------------------------------------------------------------- */
class _ReviewAndUpdateScheduleBackend extends StatelessWidget {
  final String companyId;
  const _ReviewAndUpdateScheduleBackend({required this.companyId});

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Subheader('1-Year Review'),
        const SizedBox(height: 6),
        const Text('End of fiscal year (December)'),
        const SizedBox(height: 8),
        const _BodyBullets([
          'Comprehensive review of strategic plan performance. Update goals, initiatives, and metrics for the next year based on performance and market changes.',
        ]),
        _CheckRowBackend(
          text:
              'Schedule annual review meeting (include leadership team, board, and key stakeholders)',
          id: 'Review-1Year',
          companyId: companyId,
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Subheader('3-Year Strategic Plan Review'),
        const SizedBox(height: 6),
        const Text('End of Year 2 (December 2024)'),
        const SizedBox(height: 8),
        const _BodyBullets([
          'Deep review of the entire 3-year strategic plan. Evaluate overall performance, market changes, and begin developing the next 3-year strategic plan.',
        ]),
        _CheckRowBackend(
          text:
              'Schedule strategic planning retreat (2-day offsite with leadership team)',
          id: 'Review-3Year',
          companyId: companyId,
        ),
      ],
    );

    final budget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _Subheader('Budget Finalization Process'),
        SizedBox(height: 8),
        _NumberedBullet(
          'Department Budget Requests (October)',
          'Each department submits budget requests aligned with strategic initiatives',
        ),
        _NumberedBullet(
          'Finance Review (November)',
          'Finance team consolidates and reviews requests, prepares initial budget',
        ),
        _NumberedBullet(
          'Leadership Review (Early December)',
          'Leadership team reviews and adjusts budget based on strategic priorities',
        ),
        _NumberedBullet(
          'Board Approval (Mid-December)',
          'Board reviews and approves final budget for next fiscal year',
        ),
        _NumberedBullet(
          'Implementation (January)',
          'Finalized budget distributed to departments; implementation begins',
        ),
      ],
    );

    return _SectionCard(
      title: 'Review & Update Schedule',
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 16),
                    Expanded(child: right),
                  ],
                ),
                const SizedBox(height: 16),
                budget,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 16),
                right,
                const SizedBox(height: 16),
                budget,
              ],
            );
          }
        },
      ),
    );
  }
}

class _CheckRowBackend extends StatefulWidget {
  final String text;
  final String id;
  final String companyId;
  const _CheckRowBackend({
    required this.text,
    required this.id,
    required this.companyId,
  });

  @override
  State<_CheckRowBackend> createState() => _CheckRowBackendState();
}

class _CheckRowBackendState extends State<_CheckRowBackend> {
  bool value = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('executeAndMonitor')
        .doc('kpisAndDashboard');

    final snapshot = await docRef.get();
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      setState(() {
        value = data[widget.id] ?? false;
        loading = false;
      });
    } else {
      setState(() {
        value = false;
        loading = false;
      });
    }
  }

  void _update(bool? v) async {
    if (v == null) return;
    setState(() => value = v);

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('executeAndMonitor')
        .doc('kpisAndDashboard');

    await docRef.set({widget.id: v}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const CircularProgressIndicator(strokeWidth: 2);
    return Row(
      children: [
        Checkbox(value: value, onChanged: _update),
        Expanded(child: Text(widget.text)),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                Utilities / Widgets                         */
/* -------------------------------------------------------------------------- */
class _PageScroll extends StatelessWidget {
  final List<Widget> children;
  const _PageScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
      ),
    );
  }
}

class _BodyBullets extends StatelessWidget {
  final List<String> bullets;
  const _BodyBullets(this.bullets);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(b)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NumberedBullet extends StatelessWidget {
  final String number;
  final String text;
  const _NumberedBullet(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _YearBadge extends StatelessWidget {
  final String text;
  const _YearBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _GoalRow {
  final String category;
  final String goal;
  final List<String> initiatives;
  final String measures;
  final String targets;
  final String owner;

  _GoalRow({
    required this.category,
    required this.goal,
    required this.initiatives,
    required this.measures,
    required this.targets,
    required this.owner,
  });
}

/* Footer buttons */
class _FooterButtons extends StatelessWidget {
  const _FooterButtons();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4B7BEC),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: const Text(
        'Save & Continue',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/* Placeholder */
class _StrategicInitiativesStatus extends StatelessWidget {
  const _StrategicInitiativesStatus();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Strategic Initiatives Status',
      child: const Text('Initiative status charts & visualizations go here'),
    );
  }
}
