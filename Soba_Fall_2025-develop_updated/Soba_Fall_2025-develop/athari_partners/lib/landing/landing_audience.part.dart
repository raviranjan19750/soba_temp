part of '../landing_page.dart';

extension _LandingAudiencePart on _MyCatalystPlanLandingPageState {
  Widget _buildWhoItsForSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;
      const sectionBg = Color(0xFFFAF8F5);
      const cardBg = Color(0xFFF3F0EB);
      const greenBadgeBg = Color(0xFFE6F4EA);
      const greenBadgeText = Color(0xFF1B5E20);

      final cards = <({String title, String description, IconData icon})>[
        (
          title: 'Founders & CEOs',
          description:
              'Turn big-picture ambition into a focused, executable plan your team can rally behind.',
          icon: Icons.rocket_launch_rounded,
        ),
        (
          title: 'Leadership teams',
          description:
              'Align on priorities before they become conflicts â€” with a shared source of truth.',
          icon: Icons.hub_rounded,
        ),
        (
          title: 'Venture-backed startups',
          description:
              'Build investor confidence with a 3-year roadmap and a Year 1 plan that\'s tracked quarterly.',
          icon: Icons.candlestick_chart_rounded,
        ),
        (
          title: 'Scaling businesses',
          description:
              'Move from reactive to intentional â€” so growth is sustainable, not accidental.',
          icon: Icons.auto_graph_rounded,
        ),
      ];

      const iconGradients = <List<Color>>[
        [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        [Color(0xFF388E3C), Color(0xFF2E7D32)],
        [Color(0xFF43A047), Color(0xFF388E3C)],
        [Color(0xFF1B5E20), Color(0xFF14532D)],
      ];

      Widget whoCard(String title, String description, IconData icon, int index) {
        final g = iconGradients[index % iconGradients.length];
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: g,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: g[0].withOpacity(0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 17 : 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  height: 1.55,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: isMobile ? 48 : 72,
        ),
        color: sectionBg,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'WHO IT\'S FOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: greenBadgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEW SECTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: greenBadgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Built for growing companies ready to get serious about strategy',
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Whether you\'re a seed-stage startup or a scaling Series B, the process adapts to where you are.',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    height: 1.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),
                if (isMobile)
                  Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        whoCard(cards[i].title, cards[i].description, cards[i].icon, i),
                        if (i < cards.length - 1) const SizedBox(height: 16),
                      ],
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: whoCard(cards[0].title, cards[0].description, cards[0].icon, 0)),
                          const SizedBox(width: 20),
                          Expanded(child: whoCard(cards[1].title, cards[1].description, cards[1].icon, 1)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: whoCard(cards[2].title, cards[2].description, cards[2].icon, 2)),
                          const SizedBox(width: 20),
                          Expanded(child: whoCard(cards[3].title, cards[3].description, cards[3].icon, 3)),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildGrowthCatalystHqSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;
      const accent = Color(0xFF2E7D32);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: isMobile ? 56 : 80,
        ),
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.handshake_outlined,
                          color: accent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'GROWTH Catalyst HQ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The company behind MyCatalystPlan â€” software and consulting working together.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'GROWTH Catalyst HQ is the parent organization. MyCatalystPlan is its flagship software, built to guide the '
                        'development of a structured strategic plan, track progress in real time, and drive the collaboration and visibility '
                        'needed for your plan to be understood and executed at every level of the organization. When you need more than '
                        'software, the GROWTH Catalyst HQ consulting team steps in, delivering workshops, change leadership, and hands-on '
                        'partnership to ensure your strategy shows up in how the business actually runs.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.65,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.handshake_outlined,
                          color: accent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GROWTH Catalyst HQ',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The company behind MyCatalystPlan â€” software and consulting working together.',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade900,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'GROWTH Catalyst HQ is the parent organization. MyCatalystPlan is its flagship software, built to guide the '
                              'development of a structured strategic plan, track progress in real time, and drive the collaboration and visibility '
                              'needed for your plan to be understood and executed at every level of the organization. When you need more than '
                              'software, the GROWTH Catalyst HQ consulting team steps in, delivering workshops, change leadership, and hands-on '
                              'partnership to ensure your strategy shows up in how the business actually runs.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.65,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
}

