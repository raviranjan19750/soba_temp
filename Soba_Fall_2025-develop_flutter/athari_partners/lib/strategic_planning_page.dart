import 'package:athari_partners/brainstorm_targets_widget.dart';
import 'package:athari_partners/strategic_areas_widget.dart';
import 'package:athari_partners/year3_targets_widget.dart';
import 'package:flutter/material.dart';
import 'horizontal_tab_selector.dart';

/// A page for managing and developing strategic plans.
///
/// This widget provides a tabbed interface for different aspects of
/// strategic planning, including financial targets, brainstorming,
/// and strategic areas definition.
class StrategicPlanningPage extends StatefulWidget {
  /// Creates a StrategicPlanningPage.
  const StrategicPlanningPage({super.key});

  @override
  State<StrategicPlanningPage> createState() => _StrategicPlanningPageState();
}

/// State for [StrategicPlanningPage] that manages the current active tab
/// and builds the appropriate content for each tab.
class _StrategicPlanningPageState extends State<StrategicPlanningPage> {
  /// The currently active page/tab in the strategic planning section
  _StrategicPlanningPageEnum _page = _StrategicPlanningPageEnum.financialTargets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page title
        Text("Strategic Planning"),

        // Page description
        Text(
          "Develop your strategic plan with financial targets, brainstorming, and strategic focus areas.",
        ),

        // Horizontal tab selector for navigating between different sections
        HorizontalTabSelector(
          onTabChanged: (newTab) => setState(() {
            // Update the current page when a new tab is selected
            _page = _StrategicPlanningPageEnum.values[newTab];
          }),
          tabs: [
            TabItem(title: "Financial Targets"),
            TabItem(title: "Brainstorm"),
            TabItem(title: "Strategic Areas"),
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
    _StrategicPlanningPageEnum.financialTargets => Year3TargetsWidget(),
    _StrategicPlanningPageEnum.brainstorm => BrainstormTargetsWidget(),
    _StrategicPlanningPageEnum.strategicAreas => StrategicAreasWidget(),
  };
}

/// Enum representing the different pages available in the Strategic Planning section.
///
/// This enum defines the three main sections:
/// - financialTargets: For setting and tracking financial objectives
/// - brainstorm: For collaborative idea generation and planning
/// - strategicAreas: For defining strategic focus areas and priorities
enum _StrategicPlanningPageEnum {
  /// Financial targets page for setting financial objectives and targets
  financialTargets,

  /// Brainstorm page for collaborative idea generation and planning
  brainstorm,

  /// Strategic areas page for defining focus areas and strategic priorities
  strategicAreas,
}