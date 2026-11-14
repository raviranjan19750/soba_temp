import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisualizationPlanPage extends StatefulWidget {
  final VoidCallback onSaveAndContinue;

  const VisualizationPlanPage({super.key, required this.onSaveAndContinue});

  @override
  State<VisualizationPlanPage> createState() => _VisualizationPlanPageState();
}

class _VisualizationPlanPageState extends State<VisualizationPlanPage> {
  String? companyId;

  // ===== TEXT CONTROLLERS =====
  final TextEditingController visionController = TextEditingController();
  final TextEditingController missionController = TextEditingController();

  final TextEditingController revenueController = TextEditingController();
  final TextEditingController ebitdaController = TextEditingController();
  final TextEditingController metricsController = TextEditingController();

  final TextEditingController value1Controller = TextEditingController();
  final TextEditingController value2Controller = TextEditingController();
  final TextEditingController value3Controller = TextEditingController();
  final TextEditingController value4Controller = TextEditingController();

  final TextEditingController market1Controller = TextEditingController();
  final TextEditingController market2Controller = TextEditingController();

  final TextEditingController product1Controller = TextEditingController();
  final TextEditingController product2Controller = TextEditingController();

  final TextEditingController ops1Controller = TextEditingController();
  final TextEditingController ops2Controller = TextEditingController();

  final TextEditingController q1Mil1Controller = TextEditingController();
  final TextEditingController q1Mil2Controller = TextEditingController();

  final TextEditingController q2Mil1Controller = TextEditingController();
  final TextEditingController q2Mil2Controller = TextEditingController();

  final TextEditingController q3Mil1Controller = TextEditingController();
  final TextEditingController q3Mil2Controller = TextEditingController();

  final TextEditingController q4Mil1Controller = TextEditingController();
  final TextEditingController q4Mil2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  @override
  void dispose() {
    visionController.dispose();
    missionController.dispose();
    revenueController.dispose();
    ebitdaController.dispose();
    metricsController.dispose();
    value1Controller.dispose();
    value2Controller.dispose();
    value3Controller.dispose();
    value4Controller.dispose();
    market1Controller.dispose();
    market2Controller.dispose();
    product1Controller.dispose();
    product2Controller.dispose();
    ops1Controller.dispose();
    ops2Controller.dispose();
    q1Mil1Controller.dispose();
    q1Mil2Controller.dispose();
    q2Mil1Controller.dispose();
    q2Mil2Controller.dispose();
    q3Mil1Controller.dispose();
    q3Mil2Controller.dispose();
    q4Mil1Controller.dispose();
    q4Mil2Controller.dispose();
    super.dispose();
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
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('visualization');

    final docSnap = await docRef.get();
    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data()!;
      visionController.text = data['vision'] ?? '';
      missionController.text = data['mission'] ?? '';
      revenueController.text = data['revenue'] ?? '';
      ebitdaController.text = data['ebitda'] ?? '';
      metricsController.text = data['metrics'] ?? '';
      value1Controller.text = data['value1'] ?? '';
      value2Controller.text = data['value2'] ?? '';
      value3Controller.text = data['value3'] ?? '';
      value4Controller.text = data['value4'] ?? '';
      market1Controller.text = data['Market Expansion_initiative1'] ?? '';
      market2Controller.text = data['Market Expansion_initiative2'] ?? '';
      product1Controller.text = data['Product Development_initiative1'] ?? '';
      product2Controller.text = data['Product Development_initiative2'] ?? '';
      ops1Controller.text = data['Operational Excellence_initiative1'] ?? '';
      ops2Controller.text = data['Operational Excellence_initiative2'] ?? '';
      q1Mil1Controller.text = data['Q1_milestone1'] ?? '';
      q1Mil2Controller.text = data['Q1_milestone2'] ?? '';
      q2Mil1Controller.text = data['Q2_milestone1'] ?? '';
      q2Mil2Controller.text = data['Q2_milestone2'] ?? '';
      q3Mil1Controller.text = data['Q3_milestone1'] ?? '';
      q3Mil2Controller.text = data['Q3_milestone2'] ?? '';
      q4Mil1Controller.text = data['Q4_milestone1'] ?? '';
      q4Mil2Controller.text = data['Q4_milestone2'] ?? '';
      setState(() {});
    }
  }

  Future<void> _saveField(String key, String value) async {
    if (companyId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('visualization');

    await docRef.set({key: value}, SetOptions(merge: true));
  }

  Widget _editableBox(
    TextEditingController controller,
    String placeholder, {
    String? firestoreKey,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus && firestoreKey != null) {
            _saveField(firestoreKey, controller.text);
          }
        },
        child: TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _focusAreaCard({
    required String title,
    required TextEditingController c1,
    required TextEditingController c2,
    required Color color,
    required String key1,
    required String key2,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _editableBox(c1, "Key initiative 1", firestoreKey: key1),
            _editableBox(c2, "Key initiative 2", firestoreKey: key2),
          ],
        ),
      ),
    );
  }

  Widget _quarterCard({
    required String quarter,
    required TextEditingController m1,
    required TextEditingController m2,
    required String key1,
    required String key2,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quarter,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _editableBox(m1, "Milestone 1", firestoreKey: key1),
            _editableBox(m2, "Milestone 2", firestoreKey: key2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Visualization Plan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "Create a one-page visual summary of your strategic plan.",
            ),
          ),

          const SizedBox(height: 22),
          const Text(
            "Strategic Plan One-Pager",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // ===== TOP 3 CARDS =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                title: "Vision",
                children: [
                  _editableBox(
                    visionController,
                    "Your vision statement here",
                    firestoreKey: "vision",
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Mission",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _editableBox(
                    missionController,
                    "Your mission statement here",
                    firestoreKey: "mission",
                  ),
                ],
              ),
              _sectionCard(
                title: "3-Year Targets",
                children: [
                  _editableBox(
                    revenueController,
                    "Revenue\n\$XX million",
                    firestoreKey: "revenue",
                  ),
                  _editableBox(
                    ebitdaController,
                    "EBITDA\n\$XX million",
                    firestoreKey: "ebitda",
                  ),
                  _editableBox(
                    metricsController,
                    "Other Metrics\nTarget values",
                    firestoreKey: "metrics",
                  ),
                ],
              ),
              _sectionCard(
                title: "Core Values",
                children: [
                  _editableBox(
                    value1Controller,
                    "Value 1",
                    firestoreKey: "value1",
                  ),
                  _editableBox(
                    value2Controller,
                    "Value 2",
                    firestoreKey: "value2",
                  ),
                  _editableBox(
                    value3Controller,
                    "Value 3",
                    firestoreKey: "value3",
                  ),
                  _editableBox(
                    value4Controller,
                    "Value 4",
                    firestoreKey: "value4",
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Text(
            "Strategic Focus Areas",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _focusAreaCard(
                title: "Market Expansion",
                c1: market1Controller,
                c2: market2Controller,
                color: Colors.blue.shade50,
                key1: "Market Expansion_initiative1",
                key2: "Market Expansion_initiative2",
              ),
              _focusAreaCard(
                title: "Product Development",
                c1: product1Controller,
                c2: product2Controller,
                color: Colors.green.shade50,
                key1: "Product Development_initiative1",
                key2: "Product Development_initiative2",
              ),
              _focusAreaCard(
                title: "Operational Excellence",
                c1: ops1Controller,
                c2: ops2Controller,
                color: Colors.yellow.shade50,
                key1: "Operational Excellence_initiative1",
                key2: "Operational Excellence_initiative2",
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Text(
            "Year 1 Milestones",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _quarterCard(
                quarter: "Q1",
                m1: q1Mil1Controller,
                m2: q1Mil2Controller,
                key1: "Q1_milestone1",
                key2: "Q1_milestone2",
              ),
              _quarterCard(
                quarter: "Q2",
                m1: q2Mil1Controller,
                m2: q2Mil2Controller,
                key1: "Q2_milestone1",
                key2: "Q2_milestone2",
              ),
              _quarterCard(
                quarter: "Q3",
                m1: q3Mil1Controller,
                m2: q3Mil2Controller,
                key1: "Q3_milestone1",
                key2: "Q3_milestone2",
              ),
              _quarterCard(
                quarter: "Q4",
                m1: q4Mil1Controller,
                m2: q4Mil2Controller,
                key1: "Q4_milestone1",
                key2: "Q4_milestone2",
              ),
            ],
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              OutlinedButton(onPressed: () {}, child: const Text("Back")),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onSaveAndContinue,
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
    );
  }
}
