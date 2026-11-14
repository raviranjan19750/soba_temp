import 'package:athari_partners/communicate_strat.dart';
import 'package:athari_partners/kpis_dashboard_page.dart';
import 'package:athari_partners/quarterly_cascade_component.dart';
import 'package:athari_partners/visualization_plan.dart';
import 'package:flutter/material.dart';

import 'horizontal_tab_selector.dart';

/// A page for executing and monitoring strategic plan performance.
///
/// This widget provides a tabbed interface for different aspects of
/// strategy execution and monitoring, including visualization,
/// communication, cascade planning, and KPI tracking.
class ExecuteAndMonitorPage extends StatefulWidget {
  /// Creates an ExecuteAndMonitorPage.
  const ExecuteAndMonitorPage({super.key});

  @override
  State<ExecuteAndMonitorPage> createState() => _ExecuteAndMonitorPageState();
}

/// State for [ExecuteAndMonitorPage] that manages the current active tab
/// and builds the appropriate content for each tab.
class _ExecuteAndMonitorPageState extends State<ExecuteAndMonitorPage> {
  /// The currently active page/tab in the execute and monitor section
  _ExecuteAndMonitorPageEnum _page = _ExecuteAndMonitorPageEnum.visualization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page title
        Text("Execute & Monitor Performance"),

        // Page description
        Text(
          "Implement your strategic plan and track progress toward your goals.",
        ),

        // TODO: ADD PROGRESS TRACKING LINES - Future enhancement for visual progress indicators

        // Horizontal tab selector for navigating between different sections
        HorizontalTabSelector(
          onTabChanged: (newTab) => setState(() {
            // Update the current page when a new tab is selected
            _page = _ExecuteAndMonitorPageEnum.values[newTab];
          }),
          tabs: [
            TabItem(title: "Visualization"),
            TabItem(title: "Communication"),
            TabItem(title: "Cascade Plan"),
            TabItem(title: "KPIs & Dashboard"),
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
    _ExecuteAndMonitorPageEnum.visualization => VisualizationPlanPage(
      onSaveAndContinue: () {
        setState(() {
          // TODO: THIS ISN'T QUITE WORKING FIX LATER - Navigation issue needs resolution
          _page = _ExecuteAndMonitorPageEnum.cascadePlan;
        });
      },
    ),
    _ExecuteAndMonitorPageEnum.communication => CommunicateStrategyPage(
      onSaveAndContinue: () {
        setState(() {
          // TODO: THIS ISN'T QUITE WORKING FIX LATER - Navigation issue needs resolution
          _page = _ExecuteAndMonitorPageEnum.cascadePlan;
        });
      },
    ),
    _ExecuteAndMonitorPageEnum.cascadePlan => QuarterlyCascadeComponent(),
    _ExecuteAndMonitorPageEnum.kpisAndDashboard => KpisDashboardPage(),
  };
}

/// Enum representing the different pages available in the Execute & Monitor section.
///
/// This enum defines the four main sections:
/// - visualization: For visual representation of strategy and progress
/// - communication: For strategy communication planning
/// - cascadePlan: For cascading the strategy through the organization
/// - kpisAndDashboard: For tracking KPIs and dashboard metrics
enum _ExecuteAndMonitorPageEnum {
  /// Visualization page for strategic plan visual representations
  visualization,

  /// Communication page for strategy communication planning
  communication,

  /// Cascade plan page for organizational strategy deployment
  cascadePlan,

  /// KPIs and Dashboard page for performance metrics tracking
  kpisAndDashboard,
}
