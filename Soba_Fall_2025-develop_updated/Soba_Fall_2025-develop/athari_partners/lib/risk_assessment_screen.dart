import 'package:flutter/material.dart';
import 'auth_config.dart';
import 'services/plan_progress_service.dart';
import 'services/strategic_areas_repository.dart';
import 'services/strategic_areas_session_cache.dart';
import 'services/risk_assessment_repository.dart';
import 'services/risk_assessment_session_cache.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  String? companyId;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _strategyController = TextEditingController();

  String impact = 'Medium';
  String likelihood = 'Medium';
  String? _selectedStrategicArea;
  bool _showAddRiskForm = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<String> _strategicAreas = [];
  List<Map<String, dynamic>> _risks = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _strategyController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      companyId = await loadCompanyIdForCurrentUser();
      if (companyId == null) {
        _loadError = 'Company workspace not loaded. Sign in again or finish setup.';
        return;
      }
      await _loadStrategicAreas();
      await _loadRisks();
    } catch (e) {
      _loadError = 'Could not load risk assessment: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStrategicAreas() async {
    if (companyId == null) return;
    if (skipFirebasePersistence) {
      _strategicAreas = StrategicAreasSessionCache.areas;
    } else {
      _strategicAreas = await StrategicAreasRepository.loadAreas(companyId);
    }
    if (_strategicAreas.isNotEmpty &&
        (_selectedStrategicArea == null ||
            !_strategicAreas.contains(_selectedStrategicArea))) {
      _selectedStrategicArea = _strategicAreas.first;
    }
  }

  Future<void> _loadRisks() async {
    if (companyId == null) return;
    if (skipFirebasePersistence) {
      _risks = RiskAssessmentSessionCache.risks;
      return;
    }
    _risks = await RiskAssessmentRepository.loadRisks(companyId!);
  }

  String computeSeverity(String impact, String likelihood) {
    if (impact == 'High' || likelihood == 'High') return 'High';
    if (impact == 'Medium' || likelihood == 'Medium') return 'Medium';
    return 'Low';
  }

  Color getSeverityColor(String severity) {
    switch (severity) {
      case 'High':
        return Colors.red.shade400;
      case 'Medium':
        return Colors.orange.shade400;
      case 'Low':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  bool get _canSubmitRisk =>
      companyId != null &&
      _descriptionController.text.trim().isNotEmpty &&
      _strategyController.text.trim().isNotEmpty;

  Future<void> addRisk({bool addAnother = true}) async {
    if (!_canSubmitRisk || _saving) return;

    setState(() => _saving = true);
    try {
      final riskData = {
        'desc': _descriptionController.text.trim(),
        'impact': impact,
        'likelihood': likelihood,
        'strategy': _strategyController.text.trim(),
        'severity': computeSeverity(impact, likelihood),
        'strategicArea': _selectedStrategicArea ?? '',
      };

      if (skipFirebasePersistence) {
        RiskAssessmentSessionCache.addRisk(riskData);
      } else {
        await RiskAssessmentRepository.addRisk(
          companyId: companyId!,
          riskData: riskData,
        );
        await _loadRisks();
      }

      _descriptionController.clear();
      _strategyController.clear();
      if (mounted) {
        setState(() {
          impact = 'Medium';
          likelihood = 'Medium';
          _showAddRiskForm = addAnother;
        });
      }

      if (companyId != null && !skipFirebasePersistence) {
        try {
          await PlanProgressService.cacheProgress(companyId!);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addAnother
                  ? 'Risk saved. Add another below or tap Done.'
                  : 'Risk saved.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('permission-denied')
            ? 'Could not save risk — Firestore access denied. Ask the workspace '
                'owner to publish the latest firestore.rules, or try again after '
                'signing out and back in.'
            : 'Could not save risk: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> removeRisk(String riskId) async {
    if (companyId == null) return;

    try {
      if (skipFirebasePersistence) {
        RiskAssessmentSessionCache.removeRisk(riskId);
      } else {
        await RiskAssessmentRepository.removeRisk(
          companyId: companyId!,
          riskId: riskId,
        );
        await _loadRisks();
      }

      if (mounted) setState(() {});

      if (!skipFirebasePersistence) {
        try {
          await PlanProgressService.cacheProgress(companyId!);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove risk: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  Future<void> toggleAddRiskForm() async {
    if (!_showAddRiskForm) {
      await _loadStrategicAreas();
    }
    if (mounted) setState(() => _showAddRiskForm = !_showAddRiskForm);
  }

  Future<void> finishAddRisk() async {
    if (_canSubmitRisk) {
      await addRisk(addAnother: false);
      return;
    }
    cancelAddRisk();
  }

  void cancelAddRisk() {
    setState(() {
      _showAddRiskForm = false;
      _descriptionController.clear();
      _strategyController.clear();
      impact = 'Medium';
      likelihood = 'Medium';
    });
  }

  Widget _buildRiskList() {
    if (skipFirebasePersistence) {
      return ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: RiskAssessmentSessionCache.risksNotifier,
        builder: (context, risks, _) => _buildRiskListContent(
          risks
              .map(
                (r) => _RiskEntry(
                  id: r['id']?.toString() ?? '',
                  data: r,
                ),
              )
              .toList(),
        ),
      );
    }

    return _buildRiskListContent(
      _risks
          .map(
            (risk) => _RiskEntry(
              id: (risk['id'] ?? '').toString(),
              data: risk,
            ),
          )
          .where((entry) => entry.id.isNotEmpty)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null || companyId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError ?? 'Company workspace not loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, height: 1.45),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Risk Assessment & Mitigation Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Risk assessment is optional. If you choose to document risks, link each '
                      'one to a strategic focus area from Step 3, assess impact and likelihood, '
                      'and document mitigation strategies. Add as many risks as you need.',
                      style: TextStyle(color: Colors.blue.shade700, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Strategic Risks (optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: toggleAddRiskForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_showAddRiskForm ? 'Hide form' : '+ Add Risk'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_showAddRiskForm) _buildAddRiskForm(),
            const SizedBox(height: 16),
            _buildRiskList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskListContent(List<_RiskEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No risks added. This step is optional — tap "+ Add Risk" if you want to document risks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${entries.length} risk${entries.length == 1 ? '' : 's'} identified',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ...entries.map((e) => _buildRiskCard(e.id, e.data)),
      ],
    );
  }

  Widget _buildAddRiskForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _strategicAreas.isEmpty
                ? null
                : (_strategicAreas.contains(_selectedStrategicArea)
                    ? _selectedStrategicArea
                    : _strategicAreas.first),
            decoration: InputDecoration(
              labelText: 'Strategic focus area',
              hintText: _strategicAreas.isEmpty
                  ? 'Save strategic areas in Step 3 first'
                  : 'Link this risk to a focus area',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: _strategicAreas.isEmpty
                ? null
                : _strategicAreas
                    .map(
                      (area) => DropdownMenuItem(
                        value: area,
                        child: Text(area, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged: _strategicAreas.isEmpty
                ? null
                : (value) => setState(() => _selectedStrategicArea = value),
          ),
          if (_strategicAreas.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Optional until Step 3 areas are saved.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Risk description',
              hintText: 'Describe the risk...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: impact,
                  decoration: const InputDecoration(
                    labelText: 'Impact',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Low', 'Medium', 'High']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => impact = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: likelihood,
                  decoration: const InputDecoration(
                    labelText: 'Likelihood',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Low', 'Medium', 'High']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => likelihood = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _strategyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Mitigation strategy',
              hintText: 'How will you address this risk?',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : finishAddRisk,
                child: const Text('Done'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _saving || !_canSubmitRisk
                    ? null
                    : () => addRisk(addAnother: true),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add & continue'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving || !_canSubmitRisk
                    ? null
                    : () => addRisk(addAnother: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
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
                    : const Text('Add risk'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(String riskId, Map<String, dynamic> risk) {
    final area = (risk['strategicArea'] ?? '').toString().trim();

    return Card(
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    risk['desc'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => removeRisk(riskId),
                  tooltip: 'Remove risk',
                ),
              ],
            ),
            if (area.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 14, color: Colors.blue.shade800),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        area,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildLabel('Impact: ${risk['impact']}', Colors.grey.shade300),
                _buildLabel(
                  'Likelihood: ${risk['likelihood']}',
                  Colors.grey.shade300,
                ),
                _buildLabel(
                  'Severity: ${risk['severity']}',
                  getSeverityColor(risk['severity']?.toString() ?? 'Low'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mitigation: ${risk['strategy'] ?? ''}',
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _RiskEntry {
  const _RiskEntry({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}
