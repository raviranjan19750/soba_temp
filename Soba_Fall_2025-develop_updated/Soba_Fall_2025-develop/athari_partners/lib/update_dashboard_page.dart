import 'package:flutter/material.dart';

import 'auth_config.dart';
import 'services/kpi_dashboard_tracking.dart';
import 'services/plan_progress_service.dart';
import 'widgets/dashboard_tracking_table.dart';

class UpdateDashboardPage extends StatefulWidget {
  const UpdateDashboardPage({
    super.key,
    required this.companyId,
    this.onSaved,
  });

  final String companyId;
  final VoidCallback? onSaved;

  @override
  State<UpdateDashboardPage> createState() => _UpdateDashboardPageState();
}

class _UpdateDashboardPageState extends State<UpdateDashboardPage> {
  bool _loading = true;
  bool _saving = false;
  List<DashboardAreaGroup> _groups = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _statusValues = {};
  final int _activeQuarter = dashboardCurrentQuarter();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _bindControllers(List<DashboardAreaGroup> groups) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    _statusValues.clear();

    for (final group in groups) {
      for (final row in group.rows) {
        _statusValues[row.rowId] = DashboardInitiativeStatus.normalize(row.status);
        for (final field in const [
          'measures',
          'owner',
          'q1Target',
          'q2Target',
          'q3Target',
          'q4Target',
          'q1',
          'q2',
          'q3',
          'q4',
          'fullYear',
        ]) {
          final key = DashboardTrackingTable.controllerKey(row, field);
          _controllers[key] = TextEditingController(
            text: _readField(row, field),
          );
        }
      }
    }
  }

  String _readField(DashboardTrackingRow row, String field) {
    switch (field) {
      case 'measures':
        return row.measures;
      case 'owner':
        return row.owner;
      case 'q1Target':
        return row.q1Target;
      case 'q2Target':
        return row.q2Target;
      case 'q3Target':
        return row.q3Target;
      case 'q4Target':
        return row.q4Target;
      case 'q1':
        return row.q1;
      case 'q2':
        return row.q2;
      case 'q3':
        return row.q3;
      case 'q4':
        return row.q4;
      case 'fullYear':
        return row.fullYear;
      default:
        return '';
    }
  }

  DashboardTrackingRow _rowFromControllers(DashboardTrackingRow row) {
    String read(String field) =>
        _controllers[DashboardTrackingTable.controllerKey(row, field)]
            ?.text
            .trim() ??
        '';

    final q1Target = read('q1Target');
    return row.copyWith(
      measures: read('measures'),
      targets: q1Target,
      owner: read('owner'),
      status: DashboardInitiativeStatus.normalize(_statusValues[row.rowId]),
      q1Target: q1Target,
      q2Target: read('q2Target'),
      q3Target: read('q3Target'),
      q4Target: read('q4Target'),
      q1: read('q1'),
      q2: read('q2'),
      q3: read('q3'),
      q4: read('q4'),
      fullYear: read('fullYear'),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final groups = await KpiDashboardTrackingService.loadGroups(widget.companyId);
    _bindControllers(groups);
    if (mounted) {
      setState(() {
        _groups = groups;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = _groups
          .map(
            (group) => DashboardAreaGroup(
              area: group.area,
              goal: group.goal,
              rows: group.rows.map(_rowFromControllers).toList(),
            ),
          )
          .toList();

      await KpiDashboardTrackingService.saveGroups(widget.companyId, updated);
      if (!skipFirebasePersistence) {
        await PlanProgressService.cacheProgress(widget.companyId);
      }
      widget.onSaved?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard updated'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save dashboard: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Update Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Goals and initiatives are pulled from Steps 3 and 4. Define '
                      'measures, quarterly targets, and owners, then record quarterly '
                      'actuals and YTD results for each initiative.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
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
                            'Year 1 Strategic Tracking',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          DashboardTrackingTable(
                            groups: _groups,
                            currentYear: DateTime.now().year,
                            activeQuarter: _activeQuarter,
                            editable: true,
                            controllers: _controllers,
                            statusValues: _statusValues,
                            showStatus: true,
                            onStatusChanged: (rowId, status) {
                              setState(() => _statusValues[rowId] = status);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _saving || _groups.isEmpty ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B7BEC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Dashboard',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
