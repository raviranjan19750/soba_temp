part of '../landing_page.dart';

extension _LandingPricingPart on _MyCatalystPlanLandingPageState {
  Widget _buildPricingSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;
      const accent = Color(0xFF2E7D32);
      const accentDeep = Color(0xFF1B5E20);

      Widget featureLine(String text) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, size: 20, color: accent.withOpacity(0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 14,
                    height: 1.45,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget tierCard({
        required String name,
        required String userRange,
        required String priceDisplay,
        required String priceCaption,
        required String? annualHint,
        required List<String> features,
        required bool featured,
        required String ctaLabel,
        required bool primaryButton,
      }) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: featured ? accent : const Color(0xFFE2E8F0),
              width: featured ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: featured ? accent.withOpacity(0.18) : Colors.black.withOpacity(0.05),
                blurRadius: featured ? 28 : 16,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (featured)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accentDeep],
                    ),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userRange,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accentDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceDisplay,
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey.shade900,
                            height: 1,
                          ),
                        ),
                        if (priceCaption.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              priceCaption,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (annualHint != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        annualHint,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    for (final f in features) featureLine(f),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: primaryButton
                          ? ElevatedButton(
                              onPressed: _handleGetStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: _handleGetStarted,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentDeep,
                                side: BorderSide(color: accent.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      const tiers = <({
        String name,
        String userRange,
        String priceDisplay,
        String priceCaption,
        String? annualHint,
        List<String> features,
        bool featured,
        String ctaLabel,
        bool primaryButton,
      })>[
        (
          name: 'Foundation',
          userRange: 'Up to 3 users',
          priceDisplay: r'$69',
          priceCaption: '/mo',
          annualHint: r'$59/mo billed annually',
          features: [
            'Full 5-step Catalyst planning workspace',
            'Strategic 1-pager, PDF export & KPI dashboard',
            'Cascade plan & quarterly review tracking',
            'Standard email support',
          ],
          featured: false,
          ctaLabel: 'Start free trial',
          primaryButton: false,
        ),
        (
          name: 'Build',
          userRange: '4–10 users',
          priceDisplay: r'$179',
          priceCaption: '/mo',
          annualHint: r'$149/mo billed annually',
          features: [
            'Everything in Foundation',
            'Collaborator seats with owner approval workflow',
            'Shared dashboards for cross-functional visibility',
            'Priority support & onboarding resources',
          ],
          featured: true,
          ctaLabel: 'Start free trial',
          primaryButton: true,
        ),
        (
          name: 'Accelerate',
          userRange: '11–25 users',
          priceDisplay: r'$249',
          priceCaption: '/mo',
          annualHint: r'$219/mo billed annually',
          features: [
            'Everything in Build',
            'More seats for department-wide planning',
            'Shared dashboards across leadership & functional leads',
            'Priority support with quarterly success check-in',
          ],
          featured: false,
          ctaLabel: 'Start free trial',
          primaryButton: false,
        ),
        (
          name: 'Enterprise',
          userRange: '26+ users',
          priceDisplay: 'Custom',
          priceCaption: '',
          annualHint: 'Volume pricing & annual agreements',
          features: [
            'Everything in Accelerate',
            'SSO, advanced permissions & audit-ready controls',
            'Dedicated success manager & implementation support',
            'Custom SLA & security review options',
          ],
          featured: false,
          ctaLabel: 'Talk to sales',
          primaryButton: false,
        ),
      ];

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: isMobile ? 56 : 80,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRICING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: accentDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Plans that scale with your team',
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a tier by how many people need access—from your leadership team to company-wide visibility.',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 17,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Every plan includes a 14-day free trial with full workspace access. '
                  'No credit card required until you choose a paid tier.',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    height: 1.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 36),
                if (isMobile)
                  Column(
                    children: [
                      for (var i = 0; i < tiers.length; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        tierCard(
                          name: tiers[i].name,
                          userRange: tiers[i].userRange,
                          priceDisplay: tiers[i].priceDisplay,
                          priceCaption: tiers[i].priceCaption,
                          annualHint: tiers[i].annualHint,
                          features: tiers[i].features,
                          featured: tiers[i].featured,
                          ctaLabel: tiers[i].ctaLabel,
                          primaryButton: tiers[i].primaryButton,
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < tiers.length; i++) ...[
                        if (i > 0) const SizedBox(width: 20),
                        Expanded(
                          child: tierCard(
                            name: tiers[i].name,
                            userRange: tiers[i].userRange,
                            priceDisplay: tiers[i].priceDisplay,
                            priceCaption: tiers[i].priceCaption,
                            annualHint: tiers[i].annualHint,
                            features: tiers[i].features,
                            featured: tiers[i].featured,
                            ctaLabel: tiers[i].ctaLabel,
                            primaryButton: tiers[i].primaryButton,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 20),
                Text(
                  'Prices in USD, per organization. User counts are total seats with access to MyCatalystPlan. '
                  'Annual billing available on Foundation, Build, and Accelerate plans.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
}

