import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_config.dart';
import 'services/plan_progress_service.dart';
import 'services/strategic_areas_repository.dart';
import 'utils/debounced_auto_save.dart';

class BudgetAllocationScreen extends StatefulWidget {
  const BudgetAllocationScreen({super.key});

  @override
  State<BudgetAllocationScreen> createState() => _BudgetAllocationScreenState();
}

class _BudgetAllocationScreenState extends State<BudgetAllocationScreen> {
  String? companyId;
  bool _loading = true;
  final TextEditingController _totalBudgetController = TextEditingController();
  final DebouncedAutoSave _autoSave = DebouncedAutoSave();

  List<String> _strategicAreas = [];
  Map<String, double> _allocationPercent = {};
  Map<String, TextEditingController> _percentControllers = {};
  Map<String, AreaGoalsData> _goalsByArea = {};
  AutoSaveState _saveState = AutoSaveState.idle;
  String? _saveError;

  double get totalBudget =>
      double.tryParse(_totalBudgetController.text.replaceAll(',', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    companyId = await loadCompanyIdForCurrentUser();
    if (authBypassEnabled || companyId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _strategicAreas = await StrategicAreasRepository.loadAreas(companyId);
    _goalsByArea = await StrategicAreasRepository.loadPerAreaGoals(companyId);

    final budgetSnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('budget')
        .get();

    final savedAllocations = budgetSnap.data()?['areaAllocations'];
    if (budgetSnap.exists && budgetSnap.data() != null) {
      final total = budgetSnap.data()!['total'];
      if (total != null) {
        _totalBudgetController.text = total.toString();
      }
    }

    _allocationPercent = {
      for (final area in _strategicAreas)
        area: _readSavedPercent(savedAllocations, area),
    };

    if (_allocationPercent.values.every((p) => p == 0) &&
        _strategicAreas.isNotEmpty) {
      _allocationPercent = _defaultPercentagesFromGoals();
    }

    _percentControllers = {
      for (final area in _strategicAreas)
        area: TextEditingController(
          text: (_allocationPercent[area] ?? 0).toStringAsFixed(0),
        ),
    };

    if (mounted) setState(() => _loading = false);
  }

  double _readSavedPercent(dynamic savedAllocations, String area) {
    if (savedAllocations is Map && savedAllocations[area] != null) {
      return (savedAllocations[area] as num).toDouble();
    }
    return 0;
  }

  Map<String, double> _defaultPercentagesFromGoals() {
    if (_strategicAreas.isEmpty) return {};
    final weights = <String, int>{};
    var totalWeight = 0;
    for (final area in _strategicAreas) {
      final data = _goalsByArea[area];
      final weight = (data?.hasGoal == true ? 2 : 0) +
          StrategicAreasRepository.countFilledInitiatives(
            data ?? const AreaGoalsData(goal: '', initiatives: []),
          );
      weights[area] = weight > 0 ? weight : 1;
      totalWeight += weights[area]!;
    }
    return {
      for (final area in _strategicAreas)
        area: totalWeight > 0 ? (weights[area]! / totalWeight) * 100 : 0,
    };
  }

  Future<void> _persistBudget({bool showSnackBar = false}) async {
    if (skipFirebasePersistence || companyId == null) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('budget')
        .set({
      'total': totalBudget,
      'areaAllocations': _allocationPercent,
      'strategicAreas': _strategicAreas,
    }, SetOptions(merge: true));

    await PlanProgressService.cacheProgress(companyId!);

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    }
  }

  void _scheduleAutoSave() {
    _autoSave.schedule(
      () => _persistBudget(),
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

  void _updatePercent(String area, String value) {
    final parsed = double.tryParse(value) ?? 0;
    setState(() {
      _allocationPercent[area] = parsed.clamp(0, 100);
    });
    _scheduleAutoSave();
  }

  @override
  void dispose() {
    _autoSave.dispose();
    _totalBudgetController.dispose();
    for (final c in _percentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (companyId == null) {
      return const Center(child: Text('Company profile required to allocate budget.'));
    }

    if (_strategicAreas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Allocation (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoBanner(
              'Save 3–5 strategic areas in Step 3 first. Budget allocation uses those '
              'same areas so resources align with your Year 1 goals and initiatives.',
            ),
          ],
        ),
      );
    }

    final allocatedTotal = _allocationPercent.values.fold<double>(0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Budget Allocation (Optional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              AutoSaveStatusChip(state: _saveState, errorMessage: _saveError),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoBanner(
            'Allocate your Year 1 budget across the strategic areas you selected in Step 3. '
            'Default percentages reflect goals and initiatives already captured in Step 4.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Total Annual Budget',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) _scheduleAutoSave();
            },
            child: TextField(
              controller: _totalBudgetController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _scheduleAutoSave(),
              decoration: InputDecoration(
                hintText: '1000000',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixText: 'USD',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Strategic Focus Area Allocation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Percentages should total 100%. Current total: ${allocatedTotal.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              color: (allocatedTotal - 100).abs() > 0.5
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ..._strategicAreas.map((area) {
            final percent = _allocationPercent[area] ?? 0;
            final amount = totalBudget * (percent / 100);
            final goals = _goalsByArea[area];
            final initiativeCount = goals == null
                ? 0
                : StrategicAreasRepository.countFilledInitiatives(goals);
            return _buildAllocationRow(
              area: area,
              percent: percent,
              amount: amount,
              goalSummary: goals?.hasGoal == true
                  ? 'Goal defined · $initiativeCount initiative(s)'
                  : 'No goal saved yet',
            );
          }),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _persistBudget(showSnackBar: true),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.amber.shade900, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationRow({
    required String area,
    required double percent,
    required double amount,
    required String goalSummary,
  }) {
    final controller = _percentControllers[area]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(area, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            goalSummary,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: '%',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _updatePercent(area, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '\$${amount.toStringAsFixed(0)} allocated',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (percent / 100).clamp(0, 1),
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
