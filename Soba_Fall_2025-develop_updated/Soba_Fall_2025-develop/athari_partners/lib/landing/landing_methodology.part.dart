part of '../landing_page.dart';

extension _LandingMethodologyPart on _MyCatalystPlanLandingPageState {
  Widget _buildStrategicPlanningIntroSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;
      const accentPrimary = Color(0xFF2E7D32);
      const glanceCardGreen = Color(0xFF1E6B3D);
      const foundationPillBg = Color(0xFFE8F5E9);
      const foundationPillFg = Color(0xFF1B4332);

      final headingStyle = TextStyle(
        fontSize: isMobile ? 28 : 36,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade900,
        letterSpacing: 0.4,
        height: 1.12,
      );
      final subHeadingStyle = TextStyle(
        fontSize: isMobile ? 20 : 24,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade900,
        letterSpacing: 0.35,
        height: 1.2,
      );
      final bodyStyle = TextStyle(
        fontSize: isMobile ? 15 : 16,
        height: 1.5,
        color: Colors.grey.shade700,
      );

      Widget introBullet(String text) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: accentPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: bodyStyle)),
            ],
          ),
        );
      }

      final leftColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: foundationPillBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'THE FOUNDATION',
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.15,
                color: foundationPillFg,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Text('What Is Strategic Planning?', style: headingStyle),
          SizedBox(height: isMobile ? 12 : 14),
          introBullet(
            "Defines where your company is headed, how you'll compete, and how resources align to your most critical priorities,",
          ),
          introBullet(
            'Connects your mission, vision, and values to a SWOT-informed assessment, 3-year objectives, and a concrete Year 1 action plan with measurable KPIs,',
          ),
          introBullet(
            'MyCatalystPlan guides you through each step of the process and keeps your plan visible, shared, and actionable as you execute',
          ),
          SizedBox(height: isMobile ? 22 : 28),
          Text('Why Does It Matter for Growth?', style: subHeadingStyle),
          SizedBox(height: isMobile ? 12 : 14),
          introBullet(
            'Companies without a strategic plan waste budget, talent, and time chasing the wrong opportunities;',
          ),
          introBullet(
            'A focused plan aligns your leadership team, customers, and investments around shared outcomes that drive sustainable growth;',
          ),
          introBullet(
            'With the right plan in place, you scale intentionally, adjusting based on performance data and market shifts, not guesswork.',
          ),
        ],
      );

      const glanceItems = <(String, String)>[
        ('5', 'Structured planning steps'),
        ('3 yr', 'Strategic objectives with financial targets'),
        ('360Â°', 'Visibility from C-suite to front line'),
        ('Live', 'Dashboard to track initiatives, KPIs, and results'),
      ];

      final glanceCard = Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 22 : 28),
        decoration: BoxDecoration(
          color: glanceCardGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentPrimary.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The Catalyst Plan at a Glance',
              style: TextStyle(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.35,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'One structured system from identity through execution â€” every element connected.',
              style: TextStyle(
                fontSize: isMobile ? 16 : 17,
                height: 1.45,
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.generate(glanceItems.length, (i) {
              final item = glanceItems[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.22)),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 12 : 8, bottom: i == glanceItems.length - 1 ? 0 : 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: isMobile ? 64 : 72,
                          child: Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: isMobile ? 26 : 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: item.$1.length > 2 ? 0.2 : 0.5,
                              height: 1.05,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 16,
                                height: 1.4,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: isMobile ? 48 : 72,
        ),
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      const SizedBox(height: 36),
                      glanceCard,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 55,
                        child: leftColumn,
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 45,
                        child: Align(
                          alignment: Alignment.center,
                          child: glanceCard,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

  Widget _buildStrategicPlanningFiveStepsSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;
      const accent = Color(0xFF2E7D32);
      const accentDeep = Color(0xFF1B5E20);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: isMobile ? 16 : 48,
          right: isMobile ? 16 : 48,
          top: isMobile ? 8 : 16,
          bottom: isMobile ? 56 : 80,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strategic Planning Process',
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Five clear, actionable steps to build your Catalyst Plan—from identity to execution and measurement. '
                  'Hover or click a step to see what the Catalyst Planning Process covers in detail.',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 18, color: accent.withOpacity(0.85)),
                    const SizedBox(width: 8),
                    Text(
                      'Click or tap to open the full page',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isMobile)
                  _buildCatalystPlanStepsColumn(
                    context: context,
                    accent: accent,
                    accentDeep: accentDeep,
                  )
                else
                  _buildCatalystPlanStepsRow(
                    context: context,
                    accent: accent,
                    accentDeep: accentDeep,
                  ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildCatalystPlanStepCard({
      required BuildContext context,
      required int stepNumber,
      required String label,
      required String detail,
      required Color accent,
      required Color accentDeep,
      double? cardWidth,
    }) {
      return Tooltip(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        textStyle: TextStyle(
          color: Colors.white.withOpacity(0.96),
          fontSize: 13.5,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        waitDuration: const Duration(milliseconds: 350),
        showDuration: const Duration(seconds: 20),
        preferBelow: true,
        verticalOffset: 14,
        constraints: const BoxConstraints(maxWidth: 400),
        message: detail,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  CatalystPlanningStepDetailPage.route(stepNumber),
                );
              },
              borderRadius: BorderRadius.circular(16),
              hoverColor: accent.withOpacity(0.06),
              splashColor: accent.withOpacity(0.12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: cardWidth,
                height: cardWidth != null ? 232 : null,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: cardWidth != null ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accentDeep],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Step $stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (cardWidth != null)
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            letterSpacing: -0.2,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      )
                    else
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          letterSpacing: -0.2,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'View details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildCatalystPlanStepsRow({
      required BuildContext context,
      required Color accent,
      required Color accentDeep,
    }) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 1; i < catalystPlanningSteps.length; i++) ...[
              _buildCatalystPlanStepCard(
                context: context,
                stepNumber: i,
                label: catalystPlanningSteps[i].title,
                detail: catalystPlanningSteps[i].detail,
                accent: accent,
                accentDeep: accentDeep,
                cardWidth: 200,
              ),
              if (i < catalystPlanningSteps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: accent.withOpacity(0.38),
                  ),
                ),
            ],
          ],
        ),
      );
    }

  Widget _buildCatalystPlanStepsColumn({
      required BuildContext context,
      required Color accent,
      required Color accentDeep,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 1; i < catalystPlanningSteps.length; i++) ...[
            _buildCatalystPlanStepCard(
              context: context,
              stepNumber: i,
              label: catalystPlanningSteps[i].title,
              detail: catalystPlanningSteps[i].detail,
              accent: accent,
              accentDeep: accentDeep,
              cardWidth: null,
            ),
            if (i < catalystPlanningSteps.length - 1) ...[
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 22,
                  color: accent.withOpacity(0.38),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      );
    }
}

