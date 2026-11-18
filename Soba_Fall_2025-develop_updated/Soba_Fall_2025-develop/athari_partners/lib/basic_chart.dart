import 'package:flutter/material.dart';

class BasicChart extends StatelessWidget {
  const BasicChart({super.key, required this.labels, required this.rows, required this.numberOfQuarters});

  final List<String> labels;
  final List<GridRow> rows;
  final int numberOfQuarters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(48),
      child: _Grid(
        rows: rows,
        labels: labels,
        numberOfQuarters: numberOfQuarters,
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({super.key, required this.labels, required this.rows, required this.numberOfQuarters})
    : assert(labels.length == numberOfQuarters);
  final List<String> labels;
  final List<GridRow> rows;
  final int numberOfQuarters;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 24,
      children: [
        Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            for (final row in rows)
              SizedBox(
                height: 60,
                child: Text(
                  row.label,
                  style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        Expanded(
          child: Column(
            spacing: 24,
            children: [
              Row(
                children: [
                  for (final label in labels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w300),
                    ),
                  ),
                ],
              ),
              for (final row in rows)
                SizedBox(
                  height: 60,
                  child: Container(
                    // TODO: Replace Colors.grey with the real color.
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Expanded(flex: row.startQuarter, child: SizedBox()),
                        Expanded(
                          flex: row.endQuarter - row.startQuarter,
                          child: Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: row.activeColor),
                          ),
                        ),
                        Expanded(flex: numberOfQuarters - row.endQuarter, child: SizedBox()),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class GridRow {
  GridRow({required this.label, required this.activeColor, required this.startQuarter, required this.endQuarter});

  final String label;
  final Color activeColor;
  final int startQuarter;
  final int endQuarter;
}

final sampleGrid = [
  GridRow(label: 'Wizard', activeColor: Colors.blueAccent, startQuarter: 0, endQuarter: 2),
  GridRow(label: 'AI Insights', activeColor: Colors.amber, startQuarter: 1, endQuarter: 3),
];
