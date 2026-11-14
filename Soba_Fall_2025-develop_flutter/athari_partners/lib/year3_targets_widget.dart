import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Year3TargetsWidget extends StatefulWidget {
  final Function(Map<String, double>)? onSave;

  const Year3TargetsWidget({Key? key, this.onSave}) : super(key: key);

  @override
  State<Year3TargetsWidget> createState() => _Year3TargetsWidgetState();
}

class _Year3TargetsWidgetState extends State<Year3TargetsWidget> {
  // Controllers for input fields
  final TextEditingController _year3RevenueController = TextEditingController();
  final TextEditingController _year3EbitdaController = TextEditingController();
  final TextEditingController _year1RevenueController = TextEditingController();
  final TextEditingController _year1EbitdaController = TextEditingController();
  final TextEditingController _year2RevenueController = TextEditingController();
  final TextEditingController _year2EbitdaController = TextEditingController();

  String? _companyId;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _year3RevenueController.text = '0.00';
    _year3EbitdaController.text = '0.00';
    _year1RevenueController.text = '0.00';
    _year1EbitdaController.text = '0.00';
    _year2RevenueController.text = '0.00';
    _year2EbitdaController.text = '0.00';
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        _companyId = userDoc['companyId'];
        await _loadYear3Targets();
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _loadYear3Targets() async {
    if (_companyId == null) return;
    final year3Ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('year3_targets');
    final year3Snapshot = await year3Ref.get();
    if (year3Snapshot.exists && year3Snapshot.data() != null) {
      final data = year3Snapshot.data();
      if (data != null) {
        _year1RevenueController.text = data['y1R'] ?? '0.00';
        _year1EbitdaController.text = data['y1E'] ?? '0.00';
        _year2RevenueController.text = data['y2R'] ?? '0.00';
        _year2EbitdaController.text = data['y2E'] ?? '0.00';
        _year3RevenueController.text = data['y3R'] ?? '0.00';
        _year3EbitdaController.text = data['y3E'] ?? '0.00';
      }
    }
  }

  Future<void> _saveYear3Targets() async {
    if (_companyId == null) return;
    final year3Ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('year3_targets');
    await year3Ref.set({
      'y1R': _year1RevenueController.text,
      'y1E': _year1EbitdaController.text,
      'y2R': _year2RevenueController.text,
      'y2E': _year2EbitdaController.text,
      'y3R': _year3RevenueController.text,
      'y3E': _year3EbitdaController.text,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _year3RevenueController.dispose();
    _year3EbitdaController.dispose();
    _year1RevenueController.dispose();
    _year1EbitdaController.dispose();
    _year2RevenueController.dispose();
    _year2EbitdaController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndContinue() async {
    // Collect all values
    final targets = {
      'year3Revenue': double.tryParse(_year3RevenueController.text) ?? 0.0,
      'year3Ebitda': double.tryParse(_year3EbitdaController.text) ?? 0.0,
      'year1Revenue': double.tryParse(_year1RevenueController.text) ?? 0.0,
      'year1Ebitda': double.tryParse(_year1EbitdaController.text) ?? 0.0,
      'year2Revenue': double.tryParse(_year2RevenueController.text) ?? 0.0,
      'year2Ebitda': double.tryParse(_year2EbitdaController.text) ?? 0.0,
    };

    await _saveYear3Targets();
    if (widget.onSave != null) {
      widget.onSave!(targets);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Establish Year 3 Targets & Milestones',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Targets Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Targets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 24),

                // Year 3 Financial Targets
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop layout - side by side
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTargetField(
                              icon: Icons.attach_money,
                              iconColor: const Color(0xFF4B7BEC),
                              label: 'Year 3 Revenue Target',
                              controller: _year3RevenueController,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTargetField(
                              icon: Icons.show_chart,
                              iconColor: const Color(0xFF26C281),
                              label: 'Year 3 EBITDA Target',
                              controller: _year3EbitdaController,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout - stacked
                      return Column(
                        children: [
                          _buildTargetField(
                            icon: Icons.attach_money,
                            iconColor: const Color(0xFF4B7BEC),
                            label: 'Year 3 Revenue Target',
                            controller: _year3RevenueController,
                          ),
                          const SizedBox(height: 16),
                          _buildTargetField(
                            icon: Icons.show_chart,
                            iconColor: const Color(0xFF26C281),
                            label: 'Year 3 EBITDA Target',
                            controller: _year3EbitdaController,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Milestone Targets Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 20,
                      color: const Color(0xFF4B7BEC),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Milestone Targets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Year 1 Targets
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop layout
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTargetField(
                                  icon: Icons.attach_money,
                                  iconColor: const Color(0xFF4B7BEC),
                                  label: 'Year 1 Revenue Target',
                                  controller: _year1RevenueController,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTargetField(
                                  icon: Icons.show_chart,
                                  iconColor: const Color(0xFF26C281),
                                  label: 'Year 1 EBITDA Target',
                                  controller: _year1EbitdaController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTargetField(
                                  icon: Icons.attach_money,
                                  iconColor: const Color(0xFF4B7BEC),
                                  label: 'Year 2 Revenue Target',
                                  controller: _year2RevenueController,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTargetField(
                                  icon: Icons.show_chart,
                                  iconColor: const Color(0xFF26C281),
                                  label: 'Year 2 EBITDA Target',
                                  controller: _year2EbitdaController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          _buildTargetField(
                            icon: Icons.attach_money,
                            iconColor: const Color(0xFF4B7BEC),
                            label: 'Year 1 Revenue Target',
                            controller: _year1RevenueController,
                          ),
                          const SizedBox(height: 16),
                          _buildTargetField(
                            icon: Icons.show_chart,
                            iconColor: const Color(0xFF26C281),
                            label: 'Year 1 EBITDA Target',
                            controller: _year1EbitdaController,
                          ),
                          const SizedBox(height: 16),
                          _buildTargetField(
                            icon: Icons.attach_money,
                            iconColor: const Color(0xFF4B7BEC),
                            label: 'Year 2 Revenue Target',
                            controller: _year2RevenueController,
                          ),
                          const SizedBox(height: 16),
                          _buildTargetField(
                            icon: Icons.show_chart,
                            iconColor: const Color(0xFF26C281),
                            label: 'Year 2 EBITDA Target',
                            controller: _year2EbitdaController,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save & Continue Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _handleSaveAndContinue,
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
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTargetField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '\$ ',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'USD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
          margin: const EdgeInsets.only(top: 8),
        ),
      ],
    );
  }
}

// Example usage
class Year3TargetsScreen extends StatelessWidget {
  const Year3TargetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Year3TargetsWidget(
        onSave: (targets) {
          // Handle save action
          print('Saved targets: $targets');
          // Navigate to next screen or save to database
        },
      ),
    );
  }
}
