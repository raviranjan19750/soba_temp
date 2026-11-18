import 'package:flutter/material.dart';
import 'package:athari_partners/auth_config.dart';
import 'package:athari_partners/services/plan_pdf_export.dart';

void main() {
  runApp(const StrategicOnePagerDemo());
}

class StrategicOnePagerDemo extends StatelessWidget {
  const StrategicOnePagerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: StrategicOnePager(),
          ),
        ),
      ),
    );
  }
}

class StrategicOnePager extends StatefulWidget {
  const StrategicOnePager({super.key});

  @override
  State<StrategicOnePager> createState() => _StrategicOnePagerState();
}

class _StrategicOnePagerState extends State<StrategicOnePager> {
  bool _exporting = false;

  Future<void> _download() async {
    setState(() => _exporting = true);
    try {
      final companyId = await loadCompanyIdForCurrentUser();
      await PlanPdfExport.downloadOnePager(companyId: companyId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _headlineBox(String title, String? subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.fromRGBO(243, 244, 247, 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Color.fromRGBO(108, 115, 129, 1)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String header, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Color.fromRGBO(108, 115, 129, 0.35)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color.fromRGBO(36, 99, 235, 1),
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _focusAreaCard(
    String title,
    String description,
    IconData icon,
    List<String> bullets,
    Color color,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...bullets.map(
                  (b) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusAreas = [
      {
        'title': "Strategy",
        'description':
            'Reorganize to Better Showcase Relevance in Key Industry Verticals',
        'icon': Icons.assignment,
        'color': Colors.blue,
        'bullets': [
          "Re-Define Organizational Identity and Value Proposition",

          "Establish Industry Verticals with Defined Functional Support",

          "Buildout Social Enterprise",
        ],
      },
      {
        'title': "Fundraising",
        'description': 'Establish Diversified Fundraising Strategy',
        'icon': Icons.show_chart,
        'color': Colors.lightBlue,
        'bullets': [
          "Individual/Recurring Donor Expansion and Major Gifts Program",
          "Corporate Partnership and Grant Acquisition",
          "Alumni Engagement and Fundraising Infrastructure",
        ],
      },
      {
        'title': "Marketing",
        'description':
            'Establish Unified Brand and Comprehensive Digital Marketing Strategy',
        'icon': Icons.campaign,
        'color': Colors.indigo,
        'bullets': [
          "Brand Revitalization and Identity Alignment",

          "Digital Marketing Strategy Overhaul and Team Expansion",

          "Marketing Infrastructure and Technology Enhancement",
        ],
      },
      {
        'title': "Operations",
        'description':
            'Implement Standardization to Drive Efficiency and Growth',
        'icon': Icons.settings,
        'color': Colors.blueAccent,
        'bullets': [
          "Standardization and establish repeatable documented processes",

          "Automation and integration of AI",

          "Redeploy Monday.com to enhance project delivery",
        ],
      },
      {
        'title': "Human Capital",
        'description': 'Develop a Scalable and Agile Org Structure',
        'icon': Icons.people,
        'color': Colors.lightBlueAccent,
        'bullets': [
          "Organizational Design and Role Clarity",

          "Talent Management and Development",

          "Agile Workforce Strategy",
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Strategic Planner One-Pager',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Top three columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _infoCard('Vision / Mission', [
                const Text(
                  'Vision',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(36, 99, 235, 1),
                  ),
                ),
                const SizedBox(height: 8),
                _headlineBox('Your vision statement here', null),
                const SizedBox(height: 12),
                const Text(
                  'Mission',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(36, 99, 235, 1),
                  ),
                ),
                const SizedBox(height: 8),
                _headlineBox('Your mission statement here', null),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _infoCard('3-Year Targets', [
                _headlineBox('Revenue', '\$XX million'),
                _headlineBox('EBITDA', '\$XX million'),
                _headlineBox('Other Metrics', 'Target values'),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _infoCard('1-Year Targets', [
                _headlineBox('Revenue', '\$X million'),
                _headlineBox('EBITDA', '\$X million'),
                _headlineBox('Customer Growth', 'X%'),
              ]),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Text(
          'Strategic Focus Areas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(36, 99, 235, 1),
          ),
        ),
        const SizedBox(height: 12),

        // Focus area cards
        Wrap(
          alignment: WrapAlignment.start,
          children: focusAreas
              .map(
                (f) => _focusAreaCard(
                  f['title'] as String,
                  f['description'] as String,
                  f['icon'] as IconData,
                  (f['bullets'] as List).cast<String>(),
                  f['color'] as Color,
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _exporting ? null : _download,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Download One-Pager'),
          ),
        ),
      ],
    );
  }
}
