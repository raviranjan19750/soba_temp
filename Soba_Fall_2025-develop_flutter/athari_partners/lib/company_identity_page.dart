import 'package:flutter/material.dart';
import 'company_assessment_page.dart';
import 'company_identity_code.dart';
import 'horizontal_tab_selector.dart';

/// A page for managing and developing company identity elements.
///
/// This widget provides a tabbed interface for different aspects of
/// company identity, including financial targets, brainstorming,
/// and strategic areas definition.
class CompanyIdentityPage extends StatefulWidget {
  /// Creates a CompanyIdentityPage.
  const CompanyIdentityPage({super.key});

  @override
  State<CompanyIdentityPage> createState() => _CompanyIdentityPageState();
}

/// State for [CompanyIdentityPage] that manages the current active tab
/// and builds the appropriate content for each tab.
class _CompanyIdentityPageState extends State<CompanyIdentityPage> {
  /// The currently active page/tab in the company identity section
  _CompanyIdentityPageEnum _page = _CompanyIdentityPageEnum.companyIdentity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page title
        Text("Company Identity & Assessment"),

        // Page description
        Text(
          "Define your company's core identity and assess your strategic position",
        ),

        // Horizontal tab selector for navigating between different sections
        HorizontalTabSelector(
          onTabChanged: (newTab) => setState(() {
            // Update the current page when a new tab is selected
            _page = _CompanyIdentityPageEnum.values[newTab];
          }),
          tabs: [
            TabItem(title: "Company Identity"),
            TabItem(title: "Company Assessment"),
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
    _CompanyIdentityPageEnum.companyIdentity => CompanyIdentityTab(),
    _CompanyIdentityPageEnum.companyAssessment => CompanyAssessmentPage(),
  };
}

/// Enum representing the different pages available in the Company Identity section.
///
/// This enum defines the three main sections:
/// - financialTargets: For setting and tracking financial objectives
/// - brainstorm: For collaborative idea generation and planning
/// - strategicAreas: For defining strategic focus areas and priorities
enum _CompanyIdentityPageEnum {
  /// Financial targets page for setting financial objectives and targets
  companyIdentity,

  /// Brainstorm page for collaborative idea generation and planning
  companyAssessment,
}