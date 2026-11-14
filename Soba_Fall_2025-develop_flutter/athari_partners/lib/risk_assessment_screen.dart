import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _showAddRiskForm = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      companyId = userSnap['companyId'];
    });
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

  Future<void> addRisk() async {
    if (_descriptionController.text.isEmpty ||
        _strategyController.text.isEmpty ||
        companyId == null) return;

    final riskRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('riskAssessment') // consistent path
        .collection('risks')
        .doc(); // Auto ID

    await riskRef.set({
      'desc': _descriptionController.text,
      'impact': impact,
      'likelihood': likelihood,
      'strategy': _strategyController.text,
      'severity': computeSeverity(impact, likelihood),
    });

    _descriptionController.clear();
    _strategyController.clear();
    setState(() {
      impact = 'Medium';
      likelihood = 'Medium';
      _showAddRiskForm = false;
    });
  }

  Future<void> removeRisk(String riskId) async {
    if (companyId == null) return;

    final riskRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('riskAssessment') // match addRisk path
        .collection('risks')
        .doc(riskId);

    await riskRef.delete();
  }

  void toggleAddRiskForm() {
    setState(() => _showAddRiskForm = !_showAddRiskForm);
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

  @override
  Widget build(BuildContext context) {
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final risksRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('riskAssessment')
        .collection('risks');

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
                      'Identify potential risks that could impact your strategic plan, assess their impact and likelihood, and develop mitigation strategies to address them proactively.',
                      style: TextStyle(color: Colors.blue.shade700),
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
                  'Strategic Risks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: toggleAddRiskForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('+ Add Risk'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_showAddRiskForm) _buildAddRiskForm(),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: risksRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No risks identified yet.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRiskCard(doc.id, data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRiskForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Risk Description',
            hintText: 'Describe the risk...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: impact,
                items: ['Low', 'Medium', 'High']
                    .map((e) => DropdownMenuItem(value: e, child: Text('Impact: $e')))
                    .toList(),
                onChanged: (value) => setState(() => impact = value!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: likelihood,
                items: ['Low', 'Medium', 'High']
                    .map((e) => DropdownMenuItem(value: e, child: Text('Likelihood: $e')))
                    .toList(),
                onChanged: (value) => setState(() => likelihood = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _strategyController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Mitigation Strategy',
            hintText: 'How will you address this risk?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(onPressed: cancelAddRisk, child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: addRisk,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Risk'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskCard(String riskId, Map<String, dynamic> risk) {
    return Card(
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    risk['desc'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => removeRisk(riskId),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildLabel('Impact: ${risk['impact']}', Colors.grey.shade300),
                _buildLabel('Likelihood: ${risk['likelihood']}', Colors.grey.shade300),
                _buildLabel('Severity: ${risk['severity']}', getSeverityColor(risk['severity'] ?? 'Low')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Mitigation Strategy: ${risk['strategy'] ?? ''}'),
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
