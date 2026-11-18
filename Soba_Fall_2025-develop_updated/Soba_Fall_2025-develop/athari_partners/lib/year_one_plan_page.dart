import 'package:athari_partners/develop_goals_screen.dart';
import 'package:athari_partners/risk_assessment_screen.dart';
import 'package:flutter/material.dart';
import 'horizontal_tab_selector.dart';

/// Step #4 — Define Year 1 Plan (Goals & Initiatives, Risk Assessment tabs).
///
/// This widget provides the main interface for year one planning
/// activities, including milestone setting, resource allocation,
/// and quarterly planning.
class YearOnePlanPage extends StatefulWidget {
  /// Creates a YearOnePlanPage.
  const YearOnePlanPage({super.key, this.onSaveAndContinue});

  final Future<void> Function()? onSaveAndContinue;

  @override
  State<YearOnePlanPage> createState() => _YearOnePlanPageState();
}

/// State for [YearOnePlanPage] that manages the current active tab
/// and builds the appropriate content for each tab.
class _YearOnePlanPageState extends State<YearOnePlanPage> {
  /// The currently active page/tab in the year one plan section
  _YearOnePlanPageEnum _page = _YearOnePlanPageEnum.goalsAndInitiatives;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Year 1 plan — goals & risk',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
            letterSpacing: -0.45,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Turn your 3-year direction into a practical first-year plan: define goals and '
          'initiatives for each strategic area. Risk assessment is optional — use that tab '
          'only if you want to document and mitigate risks before you execute.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        HorizontalTabSelector(
          key: const ValueKey('year_one_plan_tabs'),
          initialIndex: _page.index,
          onTabChanged: (newTab) => setState(() {
            _page = _YearOnePlanPageEnum.values[newTab];
          }),
          tabs: const [
            TabItem(title: 'Goals & Initiatives'),
            TabItem(title: 'Risk Assessment', subtitle: 'Optional'),
          ],
        ),

        // Keep all tabs alive so Goals & Initiatives state persists when switching
        // to Risk Assessment; aligns with Step #3 → Step #4 data in DevelopGoalsScreen.
        _buildYearOneTabBodies(),
      ],
    );
  }

  Widget _buildYearOneTabBodies() {
    return IndexedStack(
      index: _page.index,
      sizing: StackFit.passthrough,
      children: [
        DevelopGoalsScreen(
          key: const PageStorageKey('step4_goals_initiatives'),
          onSaveAndContinue: widget.onSaveAndContinue,
        ),
        RiskAssessmentScreen(key: PageStorageKey('step4_risk')),
      ],
    );
  }
}

/// Enum representing the different pages available in the Year One Plan section.
///
/// This enum defines the two main sections:
/// - goalsAndInitiatives: For setting goals and planning initiatives
/// - riskAssessment: For identifying and mitigating risks
enum _YearOnePlanPageEnum {
  /// Goals and initiatives page for objective setting and initiative planning
  goalsAndInitiatives,

  /// Risk assessment page for identifying and mitigating potential risks
  riskAssessment,
}