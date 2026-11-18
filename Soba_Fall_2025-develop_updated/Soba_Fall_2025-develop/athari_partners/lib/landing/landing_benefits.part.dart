part of '../landing_page.dart';

extension _LandingBenefitsPart on _MyCatalystPlanLandingPageState {
  Widget _buildWhyChooseSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;
      const accent = Color(0xFF2E7D32);

      const benefits = <(String title, String description)>[
        (
          'Robust plan development and documentation',
          'Capture your full Catalyst Plan in one place: from mission, values, and market context to initiatives, owners, and KPIs',
        ),
        (
          'Progress you can track',
          'Monitor milestones and performance in real time so leadership always knows what is working and where to act',
        ),
        (
          'Collaboration built in',
          'Align teams around shared priorities through workflows that drive dialogue, clear ownership, and consistent follow-through',
        ),
        (
          'Visibility across the organization',
          'Cascade the plan from the C-suite to every team level so everyone is pulling toward the same outcomes.',
        ),
        (
          'Execution support when you need it',
          "GROWTH Catalyst HQ's consulting team is available to support facilitation, rollout, and hands-on partnership beyond the platform.",
        ),
      ];

      List<Widget> benefitColumn(List<(String, String)> slice) {
        return [
          for (var i = 0; i < slice.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            _buildBenefitItem(slice[i].$1, slice[i].$2),
          ],
        ];
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 80,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why Choose MyCatalystPlan?',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Built to transform your strategy from a document into a living system your entire organization can see, use, and execute.',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    height: 1.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 28),
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: benefitColumn(benefits),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: benefitColumn(benefits.sublist(0, 3)),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: benefitColumn(benefits.sublist(3)),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 36),
                Center(
                  child: ElevatedButton(
                    onPressed: _handleGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Get started for Free',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildBenefitItem(String title, String description) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
}

