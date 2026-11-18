import 'package:athari_partners/kpis_dashboard_page.dart';
import 'package:athari_partners/quarterly_cascade_component.dart';
import 'package:athari_partners/visualization_plan.dart';
import 'package:flutter/material.dart';

import 'horizontal_tab_selector.dart';

/// A page for executing and monitoring strategic plan performance.
///
/// This widget provides a tabbed interface for different aspects of
/// strategy execution and monitoring, including the one-pager,
/// cascade planning, and KPI tracking.
class ExecuteAndMonitorPage extends StatefulWidget {
  /// Creates an ExecuteAndMonitorPage.
  const ExecuteAndMonitorPage({
    super.key,
    this.onProgressChanged,
  });

  final VoidCallback? onProgressChanged;

  @override
  State<ExecuteAndMonitorPage> createState() => _ExecuteAndMonitorPageState();
}

/// State for [ExecuteAndMonitorPage] that manages the current active tab
/// and builds the appropriate content for each tab.
class _ExecuteAndMonitorPageState extends State<ExecuteAndMonitorPage> {
  /// Strategic Plan 1 Pager is the default entry point for Step 5.
  _ExecuteAndMonitorPageEnum _page = _ExecuteAndMonitorPageEnum.visualization;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 5: Execute & Monitor Performance',
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
          'Track quarterly execution on the dashboard, refine your one-page summary, '
          'and cascade ownership across teams.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        HorizontalTabSelector(
          key: const ValueKey('execute_monitor_tabs'),
          initialIndex: _page.index,
          onTabChanged: (newTab) {
            if (newTab < 0 || newTab >= _ExecuteAndMonitorPageEnum.values.length) {
              return;
            }
            setState(() => _page = _ExecuteAndMonitorPageEnum.values[newTab]);
          },
          tabs: const [
            TabItem(title: 'Strategic Plan 1 Pager'),
            TabItem(title: 'Dashboard'),
            TabItem(title: 'Cascade Plan'),
          ],
        ),
        const SizedBox(height: 16),
        _buildTabBodies(),
      ],
    );
  }

  /// Build only the active tab so nested scroll views get a bounded height
  /// (IndexedStack + SingleChildScrollView inside the app scroll caused blank Step 5).
  Widget _buildTabBodies() {
    switch (_page) {
      case _ExecuteAndMonitorPageEnum.kpisAndDashboard:
        return KpisDashboardPage(
          key: const PageStorageKey('step5_kpis'),
          onProgressChanged: widget.onProgressChanged,
        );
      case _ExecuteAndMonitorPageEnum.visualization:
        return VisualizationPlanPage(
          key: const PageStorageKey('step5_one_pager'),
          onSaveAndContinue: () => setState(
            () => _page = _ExecuteAndMonitorPageEnum.cascadePlan,
          ),
        );
      case _ExecuteAndMonitorPageEnum.cascadePlan:
        return const QuarterlyCascadeComponent(
          key: PageStorageKey('step5_cascade'),
        );
    }
  }
}

/// Sections under Execute & Monitor (same order as [HorizontalTabSelector] tabs).
enum _ExecuteAndMonitorPageEnum {
  visualization,
  kpisAndDashboard,
  cascadePlan,
}
