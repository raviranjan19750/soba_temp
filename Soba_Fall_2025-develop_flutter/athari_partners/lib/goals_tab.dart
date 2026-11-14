import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsTab extends StatefulWidget {
  final String? selectedFocusArea;
  final List<String> focusAreas;
  final TextEditingController goalController;
  final Function(String?) onFocusAreaChanged;

  const GoalsTab({
    super.key,
    required this.selectedFocusArea,
    required this.focusAreas,
    required this.goalController,
    required this.onFocusAreaChanged,
  });

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  String? companyId;

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
    setState(() {
      companyId = userSnap['companyId'];
    });
  }

  Future<void> _addGoal() async {
    final text = widget.goalController.text.trim();
    if (text.isEmpty || companyId == null) return;

    final goalsRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('goalsAndInitiatives')
        .collection('goals');

    await goalsRef.add({
      'desc': text,
      'initiatives': <String>[],
      'focusArea': widget.selectedFocusArea ?? '', // optional
    });

    widget.goalController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final goalsRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('goalsAndInitiatives')
        .collection('goals');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Focus area dropdown
        DropdownButtonFormField<String>(
          value: widget.selectedFocusArea,
          items: widget.focusAreas
              .map((area) => DropdownMenuItem(value: area, child: Text(area)))
              .toList(),
          onChanged: widget.onFocusAreaChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Goal input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.goalController,
                decoration: InputDecoration(
                  labelText: 'Add a new goal...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addGoal, child: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 24),

        // StreamBuilder to fetch goals
        StreamBuilder<QuerySnapshot>(
          stream: goalsRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Text('No goals found.');
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final desc = data['desc'] ?? '';
                final initiatives = List<String>.from(
                  data['initiatives'] ?? [],
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.white,
                  child: ListTile(
                    title: Text(desc),
                    subtitle: Text('Initiatives: ${initiatives.length}'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
