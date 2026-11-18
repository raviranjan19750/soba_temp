import 'package:athari_partners/basic_chart.dart';
import 'package:flutter/material.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Roadmap', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500)),
        const Text(
          'Quarterly timeline with dependencies and status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black38),
        ),
        const SizedBox(height: 24),
        // TODO: Replace sampleGrid with real data
        BasicChart(rows: sampleGrid, numberOfQuarters: 8, labels: ['Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6', 'Q7', 'Q8'],),
      ],
    );
  }
}
