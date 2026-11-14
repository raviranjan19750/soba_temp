import 'package:athari_partners/budget_allocation_screen.dart';
import 'package:athari_partners/develop_goals_screen.dart';
import 'package:athari_partners/risk_assessment_screen.dart';
import 'package:flutter/material.dart';
import 'horizontal_tab_selector.dart';

/// A page for managing and developing the first year implementation plan.
///
/// This widget provides the main interface for year one planning
/// activities, including milestone setting, resource allocation,
/// and quarterly planning.
class YearOnePlanPage extends StatefulWidget {
  /// Creates a YearOnePlanPage.
  const YearOnePlanPage({super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page title
        Text("Year One Plan"),

        // Horizontal tab selector for navigating between different sections
        HorizontalTabSelector(
          onTabChanged: (newTab) => setState(() {
            // Update the current page when a new tab is selected
            _page = _YearOnePlanPageEnum.values[newTab];
          }),
          tabs: [
            TabItem(title: "Goals & Initiatives"),
            TabItem(title: "Risk Assessment"),
            TabItem(title: "Budget"),
          ],
        ),

        // Build the content for the currently selected page
        _buildPage(),
      ],
    );
  }

  /// Builds the content widget for the currently active page.
  ///
  /// Returns a widget corresponding to the current [_page] value.
  /// Uses a switch expression to determine which page content to display.
  Widget _buildPage() => switch (_page) {
    _YearOnePlanPageEnum.goalsAndInitiatives => DevelopGoalsScreen(),
    _YearOnePlanPageEnum.riskAssessment => RiskAssessmentScreen(),
    _YearOnePlanPageEnum.budget => BudgetAllocationScreen(),
  };
}

/// Enum representing the different pages available in the Year One Plan section.
///
/// This enum defines the three main sections:
/// - goalsAndInitiatives: For setting goals and planning initiatives
/// - riskAssessment: For identifying and mitigating risks
/// - budget: For budget planning and resource allocation
enum _YearOnePlanPageEnum {
  /// Goals and initiatives page for objective setting and initiative planning
  goalsAndInitiatives,

  /// Risk assessment page for identifying and mitigating potential risks
  riskAssessment,

  /// Budget page for financial planning and resource allocation
  budget,
}