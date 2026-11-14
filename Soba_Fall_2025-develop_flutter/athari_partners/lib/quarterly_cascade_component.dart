import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quarterly + Cascade component with department-head inputs backed by Firestore.
/// Firestore document path:
/// companies/{companyId}/executeAndMonitor/cascadePlan/departments
///
/// Fields stored inside that single document:
/// - sales_headName
/// - marketing_headName
/// - product_headName
/// - operations_headName
/// - finance_headName
/// - hr_headName
class QuarterlyCascadeComponent extends StatelessWidget {
  const QuarterlyCascadeComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CascadePlanSection(),
          const SizedBox(height: 32),
          _buildQuarterlyCard(context),
        ],
      ),
    );
  }

  Widget _buildQuarterlyCard(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quarterly Review Schedule',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).dividerColor.withOpacity(0.05),
                ),
                columns: const [
                  DataColumn(label: Text('QUARTER')),
                  DataColumn(label: Text('REVIEW DATE')),
                  DataColumn(label: Text('PARTICIPANTS')),
                  DataColumn(label: Text('FOCUS AREAS')),
                ],
                rows: _quarterRows(),
                dataRowHeight: 64,
                headingRowHeight: 56,
                columnSpacing: 24,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () {}, child: const Text('Back')),
                ElevatedButton(
                  onPressed: () {},
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _quarterRows() {
    final rows = [
      {
        'q': 'Q1 2023',
        'date': 'April 5, 2023',
        'participants': 'Leadership team, Department heads',
        'focus': 'Q1 performance, Q2 forecast, initiative updates',
      },
      {
        'q': 'Q2 2023',
        'date': 'July 7, 2023',
        'participants': 'Leadership team, Department heads',
        'focus': 'Q2 performance, mid-year adjustments, H2 outlook',
      },
      {
        'q': 'Q3 2023',
        'date': 'October 6, 2023',
        'participants': 'Leadership team, Department heads',
        'focus': 'Q3 performance, year-end forecast, strategic planning prep',
      },
      {
        'q': 'Q4 2023',
        'date': 'January 11, 2024',
        'participants': 'Leadership team, Department heads, Board',
        'focus': 'Annual performance review, Year 2 plan adjustments',
      },
    ];

    return rows
        .map(
          (r) => DataRow(
            cells: [
              DataCell(Text(r['q']!)),
              DataCell(Text(r['date']!)),
              DataCell(Text(r['participants']!)),
              DataCell(Text(r['focus']!)),
            ],
          ),
        )
        .toList();
  }
}

/// CascadePlanSection: department tabs + editable department head textbox.
/// Auto-saves to Firestore live.
class CascadePlanSection extends StatefulWidget {
  const CascadePlanSection({Key? key}) : super(key: key);

  @override
  State<CascadePlanSection> createState() => _CascadePlanSectionState();
}

class _CascadePlanSectionState extends State<CascadePlanSection>
    with SingleTickerProviderStateMixin {
  String? companyId;

  final List<_DeptInfo> _departments = const [
    _DeptInfo(key: 'sales', label: 'Sales'),
    _DeptInfo(key: 'marketing', label: 'Marketing'),
    _DeptInfo(key: 'product', label: 'Product'),
    _DeptInfo(key: 'operations', label: 'Operations'),
    _DeptInfo(key: 'finance', label: 'Finance'),
    _DeptInfo(key: 'hr', label: 'HR'),
  ];

  late final Map<String, TextEditingController> _controllers;
  late final TabController _tabController;

  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final d in _departments) d.key: TextEditingController(),
    };
    _tabController = TabController(length: _departments.length, vsync: this);
    _loadCompanyId();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      companyId = userDoc['companyId'];
      setState(() {});
      await _loadDepartmentHeads();
    }
  }

  Future<void> _loadDepartmentHeads() async {
    if (companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('cascadePlan')
        .collection('departmentsCollection')
        .doc('departments');

    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      for (final d in _departments) {
        final field = '${d.key}_headName';
        _controllers[d.key]!.text = data[field] ?? '';
      }
    }

    _addAutoSaveListeners();
    setState(() {});
  }

  void _addAutoSaveListeners() {
    if (_listenersAdded) return;
    _listenersAdded = true;

    for (final d in _departments) {
      final ctrl = _controllers[d.key]!;
      ctrl.addListener(() {
        _autoSaveDeptHead(d.key, ctrl.text);
      });
    }
  }

  Future<void> _autoSaveDeptHead(String deptKey, String headName) async {
    if (companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('cascadePlan')
        .collection('departmentsCollection')
        .doc('departments');

    final field = '${deptKey}_headName';

    await docRef.set({field: headName}, SetOptions(merge: true));
  }

  Widget _departmentView(BuildContext context, _DeptInfo dept) {
    final controller = _controllers[dept.key]!;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Department head',
                hintText: 'Name of department head',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aligned Strategic Focus Areas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(
                  color: WidgetStatePropertyAll(Colors.white),
                  label: Text('Market Expansion'),
                ),
                Chip(
                  color: WidgetStatePropertyAll(Colors.white),
                  label: Text('Product Development'),
                ),
                Chip(
                  color: WidgetStatePropertyAll(Colors.white),
                  label: Text('Operational Excellence'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Department Goals',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _goalCard(
              title: 'Increase new customer acquisition by 20%',
              alignedWith: 'Market Expansion',
              initiatives: [
                'Implement new lead generation campaign',
                'Optimize sales funnel conversion rates',
                'Expand sales team in western region',
              ],
              kpis: [
                'Number of new customers',
                'Lead-to-customer conversion rate',
                'Sales cycle length',
              ],
              status: GoalStatus.onTrack,
            ),
            const SizedBox(height: 12),
            _goalCard(
              title: 'Improve customer retention rate to 85%',
              alignedWith: 'Customer Experience',
              initiatives: [
                'Implement customer success program',
                'Improve onboarding flow',
              ],
              kpis: ['Retention rate', 'Churn rate'],
              status: GoalStatus.atRisk,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard({
    required String title,
    required String alignedWith,
    required List<String> initiatives,
    required List<String> kpis,
    required GoalStatus status,
  }) {
    final statusLabel = status == GoalStatus.onTrack ? 'On Track' : 'At Risk';
    final statusColor = status == GoalStatus.onTrack
        ? Colors.green.shade200
        : Colors.amber.shade200;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aligned with strategic focus area: $alignedWith',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Key Initiatives:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...initiatives.map((s) => _bulletLine(s)),
            const SizedBox(height: 8),
            const Text('KPIs:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...kpis.map((s) => _bulletLine(s)),
          ],
        ),
      ),
    );
  }

  Widget _bulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cascade the Plan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Break down your strategic plan into department/team level goals and initiatives. This ensures alignment across the organization and clear ownership of objectives.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ FIXED: use only _tabController, no DefaultTabController
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[700],
              tabs: [for (final d in _departments) Tab(text: d.label)],
            ),
            const SizedBox(height: 12),
            Container(
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final d in _departments) _departmentView(context, d),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeptInfo {
  final String key;
  final String label;
  const _DeptInfo({required this.key, required this.label});
}

enum GoalStatus { onTrack, atRisk }

/// Demo entrypoint for previewing the component.
void main() {
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Quarterly + Cascade Demo')),
        body: const QuarterlyCascadeComponent(),
      ),
    );
  }
}
