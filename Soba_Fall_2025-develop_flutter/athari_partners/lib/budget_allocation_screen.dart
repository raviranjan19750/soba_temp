import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetAllocationScreen extends StatefulWidget {
  const BudgetAllocationScreen({super.key});

  @override
  State<BudgetAllocationScreen> createState() => _BudgetAllocationScreenState();
}

class _BudgetAllocationScreenState extends State<BudgetAllocationScreen> {
  String? companyId;
  final TextEditingController _totalBudgetController = TextEditingController();

  Map<String, double> focusAreaPercentages = {
    "Market Expansion": 0.0,
    "Customer Retention": 0.0,
    "Product Innovation": 0.0,
  };

  double totalBudget = 0;

  @override
  void initState() {
    super.initState();
    _loadCompanyIdBudgetAndGoals();
  }

  Future<void> _loadCompanyIdBudgetAndGoals() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userSnap.exists && userSnap.data() != null) {
      companyId = userSnap['companyId'];
    }

    if (companyId != null) {
      // Load total budget
      final budgetSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('yearOnePlan')
          .doc('budget')
          .get();

      if (budgetSnap.exists && budgetSnap.data() != null) {
        totalBudget = (budgetSnap.data()!['total'] ?? 0).toDouble();
        _totalBudgetController.text = totalBudget.toStringAsFixed(0);
      }

      // Predefined focus areas
      Map<String, int> focusAreaCounts = {
        "Market Expansion": 0,
        "Customer Retention": 0,
        "Product Innovation": 0,
      };

      // Load goals to calculate focus area percentages
      final goalsSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('yearOnePlan')
          .doc('goalsAndInitiatives')
          .collection('goals')
          .get();

      for (var doc in goalsSnap.docs) {
        final data = doc.data();
        final focus = data['focusArea'];
        if (focusAreaCounts.containsKey(focus)) {
          focusAreaCounts[focus] = focusAreaCounts[focus]! + 1;
        }
      }

      final totalGoals = focusAreaCounts.values.fold<int>(
        0,
        (sum, val) => sum + val,
      );

      setState(() {
        focusAreaPercentages = focusAreaCounts.map((key, value) {
          return MapEntry(key, totalGoals > 0 ? value / totalGoals : 0.0);
        });
      });
    }
  }

  Future<void> _updateTotalBudget(String value) async {
    if (companyId == null) return;
    double? total = double.tryParse(value);
    if (total == null) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('yearOnePlan')
        .doc('budget')
        .set({'total': total}, SetOptions(merge: true));

    setState(() {
      totalBudget = total;
    });
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Budget Allocation (Optional)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildInfoBanner(),
          const SizedBox(height: 20),
          const Text(
            "Total Annual Budget",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _updateTotalBudget(_totalBudgetController.text);
              }
            },
            child: TextField(
              controller: _totalBudgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "1000000",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixText: "USD",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Strategic Focus Area Allocation",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...focusAreaPercentages.entries.map((entry) {
            final amount = totalBudget * entry.value;
            return _buildProgressRow(entry.key, entry.value, amount);
          }).toList(),
          const SizedBox(height: 32),
          const Text(
            "Income Statement",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload File"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildIncomeTable(),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text("Download Template"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text("Back")),
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
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This section is optional but recommended. Allocate your budget across strategic focus areas to ensure resources are aligned with your priorities.',
              style: TextStyle(color: Colors.amber.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double percent, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label  ${(percent * 100).toStringAsFixed(0)}%  \$${amount.toStringAsFixed(0)}",
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTable() {
    final items = [
      ["Revenue", "\$1,000,000", "100%"],
      ["Cost of Sales", "\$400,000", "40%"],
      ["Gross Profit", "\$600,000", "60%"],
      ["Salaries & Benefits", "\$250,000", "25%"],
      ["Marketing & Sales", "\$75,000", "8%"],
      ["Rent & Facilities", "\$60,000", "6%"],
      ["Utilities", "\$25,000", "3%"],
      ["Other Expenses", "\$40,000", "4%"],
      ["Total Operating Expenses", "\$450,000", "45%"],
      ["Operating Income", "\$150,000", "15%"],
      ["Taxes", "\$37,500", "4%"],
      ["Net Income", "\$112,500", "11%"],
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "ITEM",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "AMOUNT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "% OF REVENUE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...items.map(
          (row) => TableRow(
            decoration: BoxDecoration(
              color: row[0] == "Net Income"
                  ? Colors.blue.shade50
                  : Colors.transparent,
            ),
            children: row
                .map(
                  (cell) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(cell, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
