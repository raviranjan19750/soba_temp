import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_config.dart';

class InitiativesTab extends StatefulWidget {
  const InitiativesTab({super.key});

  @override
  State<InitiativesTab> createState() => _InitiativesTabState();
}

class _InitiativesTabState extends State<InitiativesTab> {
  String? companyId;
  final Map<String, TextEditingController> _initiativeControllers = {};

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final resolvedCompanyId = await loadCompanyIdForCurrentUser();
    if (!mounted) return;
    setState(() => companyId = resolvedCompanyId);
  }

  TextEditingController _getController(String goalId) {
    if (!_initiativeControllers.containsKey(goalId)) {
      _initiativeControllers[goalId] = TextEditingController();
    }
    return _initiativeControllers[goalId]!;
  }

  Future<void> _addInitiative(String goalId, String text) async {
    if (skipFirebasePersistence || companyId == null) return;
    final goalRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('goalsAndInitiatives')
        .collection('goals')
        .doc(goalId);

    await goalRef.update({
      'initiatives': FieldValue.arrayUnion([text])
    });
  }

  Future<void> _removeInitiative(String goalId, String text) async {
    if (skipFirebasePersistence || companyId == null) return;
    final goalRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('goalsAndInitiatives')
        .collection('goals')
        .doc(goalId);

    await goalRef.update({
      'initiatives': FieldValue.arrayRemove([text])
    });
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

    return StreamBuilder<QuerySnapshot>(
      stream: goalsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No goals found.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final desc = data['desc'] ?? '';
              final initiatives = List<String>.from(data['initiatives'] ?? []);
              final controller = _getController(doc.id);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(desc,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...initiatives.map((initiative) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(initiative),
                            GestureDetector(
                              onTap: () => _removeInitiative(doc.id, initiative),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: '+ Add Initiative',
                              hintStyle:
                              TextStyle(color: Colors.blue.shade700),
                              border: OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isNotEmpty) {
                              _addInitiative(doc.id, text);
                              controller.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(40, 40),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
