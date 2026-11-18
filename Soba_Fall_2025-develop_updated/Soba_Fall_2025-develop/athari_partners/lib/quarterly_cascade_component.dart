import 'package:flutter/material.dart';

import 'auth_config.dart';
import 'services/cascade_plan_repository.dart';
import 'services/kpi_dashboard_tracking.dart';
import 'services/plan_progress_service.dart';

/// Step 5 — push the strategic plan to departments with sub-initiatives
/// aligned to each focus area. Includes an executive summary for the CEO.
class QuarterlyCascadeComponent extends StatelessWidget {
  const QuarterlyCascadeComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return const CascadePlanSection();
  }
}

class CascadePlanSection extends StatefulWidget {
  const CascadePlanSection({super.key});

  @override
  State<CascadePlanSection> createState() => _CascadePlanSectionState();
}

class _CascadePlanSectionState extends State<CascadePlanSection>
    with SingleTickerProviderStateMixin {
  String? _companyId;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  CascadePlanData? _data;

  late TabController _tabController;
  final Map<String, TextEditingController> _headControllers = {};
  final Map<String, TextEditingController> _initiativeControllers = {};
  final Map<String, String> _statusValues = {};

  static String _initKey(String dept, String area, int index) =>
      '${dept}_${area}_$index';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CascadeDepartment.defaults.length + 1,
      vsync: this,
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _headControllers.values) {
      c.dispose();
    }
    for (final c in _initiativeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      _companyId = await loadCompanyIdForCurrentUser();
      if (_companyId == null) {
        _loadError = 'Company workspace not loaded.';
        return;
      }
      final data = await CascadePlanRepository.load(_companyId);
      _bindControllers(data);
      if (mounted) {
        setState(() => _data = data);
      }
    } catch (e) {
      _loadError = 'Could not load cascade plan: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bindControllers(CascadePlanData data) {
    for (final c in _headControllers.values) {
      c.dispose();
    }
    for (final c in _initiativeControllers.values) {
      c.dispose();
    }
    _headControllers.clear();
    _initiativeControllers.clear();
    _statusValues.clear();

    for (final dept in data.departments) {
      _headControllers[dept.department.key] =
          TextEditingController(text: dept.headName);
      for (final areaPlan in dept.areas) {
        for (var i = 0; i < areaPlan.subInitiatives.length; i++) {
          final item = areaPlan.subInitiatives[i];
          final key =
              _initKey(dept.department.key, areaPlan.area, i);
          _initiativeControllers[key] =
              TextEditingController(text: item.text);
          _statusValues[key] = item.status;
        }
      }
      for (var i = 0; i < dept.riskPlan.subInitiatives.length; i++) {
        final item = dept.riskPlan.subInitiatives[i];
        final key = _initKey(
          dept.department.key,
          CascadePlanRepository.riskAreaKey,
          i,
        );
        _initiativeControllers[key] =
            TextEditingController(text: item.text);
        _statusValues[key] = item.status;
      }
    }
  }

  List<DepartmentCascadePlan> _collectDepartments() {
    final data = _data!;
    return data.departments.map((dept) {
      final headName =
          _headControllers[dept.department.key]?.text.trim() ?? '';
      final areas = dept.areas.map((areaPlan) {
        final subInitiatives = List<CascadeSubInitiative>.generate(
          areaPlan.subInitiatives.length,
          (i) {
            final key = _initKey(dept.department.key, areaPlan.area, i);
            return CascadeSubInitiative(
              text: _initiativeControllers[key]?.text.trim() ?? '',
              status: DashboardInitiativeStatus.normalize(
                _statusValues[key],
              ),
            );
          },
        );
        return CascadeAreaPlan(
          area: areaPlan.area,
          companyGoal: areaPlan.companyGoal,
          companyInitiatives: areaPlan.companyInitiatives,
          subInitiatives: subInitiatives,
        );
      }).toList();
      final riskSubInitiatives = List<CascadeSubInitiative>.generate(
        dept.riskPlan.subInitiatives.length,
        (i) {
          final key = _initKey(
            dept.department.key,
            CascadePlanRepository.riskAreaKey,
            i,
          );
          return CascadeSubInitiative(
            text: _initiativeControllers[key]?.text.trim() ?? '',
            status: DashboardInitiativeStatus.normalize(
              _statusValues[key],
            ),
          );
        },
      );
      return DepartmentCascadePlan(
        department: dept.department,
        headName: headName,
        areas: areas,
        riskPlan: CascadePlanRepository.buildRiskPlan(
          companyRisks: _data!.companyRisks,
          subInitiatives: riskSubInitiatives,
        ),
      );
    }).toList();
  }

  Future<void> _save({bool showSnack = true}) async {
    if (_companyId == null || _data == null) return;
    setState(() => _saving = true);
    try {
      final departments = _collectDepartments();
      await CascadePlanRepository.save(
        companyId: _companyId!,
        departments: departments,
        strategicAreas: _data!.strategicAreas,
      );
      if (!skipFirebasePersistence) {
        await PlanProgressService.cacheProgress(_companyId!);
      }
      if (mounted) {
        setState(() {
          _data = CascadePlanData(
            strategicAreas: _data!.strategicAreas,
            departments: departments,
            companyRisks: _data!.companyRisks,
          );
        });
        if (showSnack) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cascade plan saved'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save cascade plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null || _data == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _loadError ?? 'Cascade plan unavailable.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB91C1C), height: 1.45),
          ),
        ),
      );
    }

    final data = _data!;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _introCard(context),
        const SizedBox(height: 16),
        if (data.strategicAreas.isEmpty)
          _emptyStrategicAreas()
        else ...[
          _executiveSummary(context, data, isMobile),
          const SizedBox(height: 20),
          _departmentSection(context, data, isMobile),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving || data.strategicAreas.isEmpty ? null : () => _save(),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? 'Saving…' : 'Save cascade plan'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _introCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push the plan to departments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A8A),
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Each department head defines sub-initiatives that support the company '
            'goals and initiatives from Steps 3–4. Use the executive summary below '
            'to see alignment and status at a glance.',
            style: TextStyle(height: 1.45, color: Color(0xFF1E40AF)),
          ),
        ],
      ),
    );
  }

  Widget _emptyStrategicAreas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'Save strategic focus areas in Step 3 and Year 1 goals in Step 4 first. '
        'This page will pre-fill company goals so each department can define '
        'supporting sub-initiatives.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF64748B), height: 1.45),
      ),
    );
  }

  Widget _executiveSummary(
    BuildContext context,
    CascadePlanData data,
    bool isMobile,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard_outlined,
                    size: 20, color: Color(0xFF334155)),
                const SizedBox(width: 8),
                Text(
                  'Executive summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  'CEO view',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Department readiness across strategic focus areas. Tap a department tab below to edit sub-initiatives.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (isMobile)
              ...data.departments.map(_deptSummaryCard)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < data.departments.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(
                        width: 220,
                        child: _deptSummaryCard(data.departments[i]),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _statusMatrix(data, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _deptSummaryCard(DepartmentCascadePlan dept) {
    final status = dept.rollupStatus;
    return InkWell(
      onTap: () {
        final index = CascadeDepartment.defaults
                .indexWhere((d) => d.key == dept.department.key) +
            1;
        if (index > 0 && index < _tabController.length) {
          _tabController.animateTo(index);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dept.department.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                _statusChip(status, compact: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dept.headName.isEmpty ? 'No head assigned' : dept.headName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              '${dept.definedCount} sub-initiatives defined',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (dept.atRiskCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${dept.atRiskCount} need attention',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusMatrix(CascadePlanData data, bool isMobile) {
    if (data.strategicAreas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status by department & focus area',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            columns: [
              const DataColumn(label: Text('Department')),
              ...data.strategicAreas.map(
                (area) => DataColumn(
                  label: SizedBox(
                    width: isMobile ? 100 : 120,
                    child: Text(
                      area,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: isMobile ? 88 : 100,
                  child: Text(
                    CascadePlanRepository.riskAreaLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            rows: data.departments.map((dept) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      dept.department.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...dept.areas.map(
                    (area) => DataCell(
                      _statusChip(area.rollupStatus, compact: true),
                    ),
                  ),
                  DataCell(
                    _statusChip(dept.riskPlan.rollupStatus, compact: true),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _departmentSection(
    BuildContext context,
    CascadePlanData data,
    bool isMobile,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department plans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a department to assign the head and define sub-initiatives under each strategic focus area.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2563EB),
              tabs: [
                const Tab(text: 'Overview'),
                for (final d in data.departments) Tab(text: d.department.label),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final index = _tabController.index;
                if (index == 0) {
                  return _companyGoalsOverview(data);
                }
                final dept = data.departments[index - 1];
                return _departmentEditor(dept);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyGoalsOverview(CascadePlanData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company plan to cascade (from Steps 3–4)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),
        for (final area in data.strategicAreas) ...[
          _companyAreaCard(data, area),
          const SizedBox(height: 10),
        ],
        _companyRiskCard(data),
      ],
    );
  }

  Widget _companyRiskCard(CascadePlanData data) {
    final riskPlan = data.departments.isEmpty
        ? CascadePlanRepository.buildRiskPlan(
            companyRisks: data.companyRisks,
            subInitiatives: const [],
          )
        : data.departments.first.riskPlan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CascadePlanRepository.riskAreaLabel.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            riskPlan.companyGoal,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
          if (riskPlan.companyInitiatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Risks from Step 4:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            ...riskPlan.companyInitiatives.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(risk, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _companyAreaCard(CascadePlanData data, String area) {
    final sample = data.departments.first.areas.firstWhere(
      (a) => a.area == area,
      orElse: () => CascadeAreaPlan(
        area: area,
        companyGoal: '',
        companyInitiatives: const [],
        subInitiatives: const [],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            area.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sample.companyGoal.isEmpty ? 'No goal defined yet' : sample.companyGoal,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
          if (sample.companyInitiatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Company initiatives:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            ...sample.companyInitiatives.map(
              (i) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(i, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _departmentEditor(DepartmentCascadePlan dept) {
    final headController = _headControllers[dept.department.key]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: headController,
          decoration: InputDecoration(
            labelText: '${dept.department.label} department head',
            hintText: 'Name of leader responsible for this plan',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        for (final areaPlan in dept.areas)
          _areaCascadeBlock(dept.department.key, areaPlan),
        _areaCascadeBlock(
          dept.department.key,
          dept.riskPlan,
          areaKey: CascadePlanRepository.riskAreaKey,
          isRisk: true,
        ),
      ],
    );
  }

  Widget _areaCascadeBlock(
    String deptKey,
    CascadeAreaPlan areaPlan, {
    String? areaKey,
    bool isRisk = false,
  }) {
    final storageKey = areaKey ?? areaPlan.area;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isRisk
                  ? const Color(0xFF9A3412)
                  : const Color(0xFF334155),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    areaPlan.area.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                _statusChip(areaPlan.rollupStatus, compact: true, onDark: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRisk ? 'Risk summary' : 'Company goal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  areaPlan.companyGoal.isEmpty
                      ? '—'
                      : areaPlan.companyGoal,
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                ),
                if (areaPlan.companyInitiatives.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    isRisk
                        ? 'Risks from Step 4'
                        : 'Supporting company initiatives',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  ...areaPlan.companyInitiatives.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $i', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  isRisk
                      ? 'Department risk mitigation actions'
                      : 'Department sub-initiatives',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  isRisk
                      ? 'What will ${CascadeDepartment.defaults.firstWhere((d) => d.key == deptKey).label} do to mitigate these risks?'
                      : 'What will ${CascadeDepartment.defaults.firstWhere((d) => d.key == deptKey).label} do this year to support this focus area?',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < areaPlan.subInitiatives.length; i++)
                  _subInitiativeRow(deptKey, storageKey, i, isRisk: isRisk),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subInitiativeRow(
    String deptKey,
    String area,
    int index, {
    bool isRisk = false,
  }) {
    final key = _initKey(deptKey, area, index);
    final controller = _initiativeControllers[key]!;
    final status = _statusValues[key] ?? DashboardInitiativeStatus.notStarted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isRisk
                    ? 'Mitigation action ${index + 1}'
                    : 'Sub-initiative ${index + 1}',
                isDense: true,
                filled: true,
                fillColor: isRisk
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFEFF6FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: DashboardInitiativeStatus.options.contains(status)
                  ? status
                  : DashboardInitiativeStatus.notStarted,
              decoration: InputDecoration(
                labelText: 'Status',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              items: DashboardInitiativeStatus.options
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _statusValues[key] = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, {bool compact = false, bool onDark = false}) {
    final colors = _statusColors(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: onDark ? colors.background.withValues(alpha: 0.25) : colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: onDark ? Colors.white : colors.foreground,
        ),
      ),
    );
  }

  ({Color background, Color foreground, Color border}) _statusColors(String status) {
    switch (status) {
      case DashboardInitiativeStatus.onTrack:
        return (
          background: const Color(0xFFDCFCE7),
          foreground: const Color(0xFF166534),
          border: const Color(0xFF86EFAC),
        );
      case DashboardInitiativeStatus.atRisk:
        return (
          background: const Color(0xFFFEF3C7),
          foreground: const Color(0xFFB45309),
          border: const Color(0xFFFCD34D),
        );
      case DashboardInitiativeStatus.behind:
        return (
          background: const Color(0xFFFEE2E2),
          foreground: const Color(0xFFB91C1C),
          border: const Color(0xFFFECACA),
        );
      case DashboardInitiativeStatus.complete:
        return (
          background: const Color(0xFFE0E7FF),
          foreground: const Color(0xFF3730A3),
          border: const Color(0xFFC7D2FE),
        );
      case DashboardInitiativeStatus.na:
        return (
          background: const Color(0xFFE2E8F0),
          foreground: const Color(0xFF64748B),
          border: const Color(0xFF94A3B8),
        );
      default:
        return (
          background: const Color(0xFFF1F5F9),
          foreground: const Color(0xFF475569),
          border: const Color(0xFFCBD5E1),
        );
    }
  }
}
