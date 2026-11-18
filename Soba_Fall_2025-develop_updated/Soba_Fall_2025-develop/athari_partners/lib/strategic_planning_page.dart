import 'package:athari_partners/company_assessment_page.dart';
import 'package:athari_partners/strategic_areas_widget.dart';
import 'package:athari_partners/year3_targets_widget.dart';
import 'package:flutter/material.dart';
import 'horizontal_tab_selector.dart';

/// A page for managing and developing strategic plans.
///
/// - Main nav **step 2**: pass [companyAssessmentOnly] `true` — Internal / External / Management assessment tabs.
/// - Main nav **step 3**: two tabs — Financial Targets and Strategic Areas (no company assessment here).
class StrategicPlanningPage extends StatefulWidget {
  /// Creates a StrategicPlanningPage.
  ///
  /// [initialSubTabIndex] applies when [companyAssessmentOnly] is false (step 3):
  /// `0` = Financial Targets, `1` = Strategic Areas.
  ///
  /// When [companyAssessmentOnly] is true (step 2), only company assessment is shown;
  /// [initialSubTabIndex] is ignored.
  const StrategicPlanningPage({
    super.key,
    this.initialSubTabIndex,
    this.companyAssessmentOnly = false,
    this.onStepComplete,
  });

  /// 0 = Financial Targets, 1 = Strategic Areas (when [companyAssessmentOnly] is false).
  final int? initialSubTabIndex;

  /// Step 2: [CompanyAssessmentPage] with tabbed assessment (pre-work lives on Internal).
  final bool companyAssessmentOnly;

  /// Called after the final Save & Continue for this roadmap step.
  final Future<void> Function()? onStepComplete;

  @override
  State<StrategicPlanningPage> createState() => _StrategicPlanningPageState();
}

/// State for [StrategicPlanningPage] that manages the current active tab
/// and builds the appropriate content for each tab.
class _StrategicPlanningPageState extends State<StrategicPlanningPage> {
  /// The currently active page/tab in the strategic planning section
  late _StrategicPlanningPageEnum _page;

  /// Step 2: tab index for [CompanyAssessmentPage.assessmentSection] (0–2).
  int _companyAssessmentTab = 0;

  @override
  void initState() {
    super.initState();
    final idx = widget.initialSubTabIndex;
    if (idx != null &&
        idx >= 0 &&
        idx < _StrategicPlanningPageEnum.values.length) {
      _page = _StrategicPlanningPageEnum.values[idx];
    } else {
      _page = _StrategicPlanningPageEnum.financialTargets;
    }
  }

  @override
  void didUpdateWidget(StrategicPlanningPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.companyAssessmentOnly != oldWidget.companyAssessmentOnly) {
      if (!widget.companyAssessmentOnly) {
        final idx = widget.initialSubTabIndex;
        if (idx != null &&
            idx >= 0 &&
            idx < _StrategicPlanningPageEnum.values.length) {
          setState(() => _page = _StrategicPlanningPageEnum.values[idx]);
        }
      }
      return;
    }
    if (widget.initialSubTabIndex != oldWidget.initialSubTabIndex &&
        widget.initialSubTabIndex != null &&
        !widget.companyAssessmentOnly) {
      final idx = widget.initialSubTabIndex!;
      if (idx >= 0 && idx < _StrategicPlanningPageEnum.values.length) {
        setState(() => _page = _StrategicPlanningPageEnum.values[idx]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.companyAssessmentOnly) {
      final isMobile = MediaQuery.sizeOf(context).width < 768;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Assessment — gaps & opportunities',
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
            'Complete Internal Assessment and External Assessment, then synthesize '
            'findings in Management Discussion before setting multi-year targets in Step 3.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Internal Assessment + External Assessment → Management Discussion',
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          HorizontalTabSelector(
            key: ValueKey(_companyAssessmentTab),
            initialIndex: _companyAssessmentTab,
            onTabChanged: (i) {
              if (i < 0 || i > 2) return;
              setState(() => _companyAssessmentTab = i);
            },
            tabs: const [
              TabItem(title: 'Internal Assessment'),
              TabItem(title: 'External Assessment'),
              TabItem(title: 'Management Discussion'),
            ],
          ),
          const SizedBox(height: 16),
          CompanyAssessmentPage(
            assessmentSection: _companyAssessmentTab,
            onSaveAndContinue: widget.onStepComplete,
            onAdvanceAssessmentTab: (nextTab) async {
              if (nextTab < 0 || nextTab > 2) return;
              setState(() => _companyAssessmentTab = nextTab);
            },
          ),
        ],
      );
    }

    final isMobileStep3 = MediaQuery.sizeOf(context).width < 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: 3-Year objectives — targets & strategic areas',
          style: TextStyle(
            fontSize: isMobileStep3 ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
            letterSpacing: -0.45,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'After assessment (Step 2), define measurable targets and the strategic themes '
          'that will organize your Year 1 goals and initiatives in Step 4.',
          style: TextStyle(
            fontSize: isMobileStep3 ? 14 : 16,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        HorizontalTabSelector(
          key: const ValueKey('step3_plan_tabs'),
          initialIndex: _page.index,
          onTabChanged: (newTab) => setState(() {
            _page = _StrategicPlanningPageEnum.values[newTab];
          }),
          tabs: const [
            TabItem(title: 'Financial Targets'),
            TabItem(title: 'Strategic Areas'),
          ],
        ),

        // Keep both tabs mounted so Strategic Areas selections survive tab switches
        // until Save & Continue writes to Firestore.
        _buildStep3TabBodies(),
      ],
    );
  }

  Widget _buildStep3TabBodies() {
    return IndexedStack(
      index: _page.index,
      sizing: StackFit.passthrough,
      children: [
        Year3TargetsWidget(key: PageStorageKey('step3_year3_targets')),
        StrategicAreasWidget(
          key: PageStorageKey('step3_strategic_areas'),
          onStepComplete: widget.onStepComplete,
        ),
      ],
    );
  }
}

/// Tabs for the full Strategic Planning page (step 3). Company assessment is step 2 only.
enum _StrategicPlanningPageEnum {
  financialTargets,
  strategicAreas,
}