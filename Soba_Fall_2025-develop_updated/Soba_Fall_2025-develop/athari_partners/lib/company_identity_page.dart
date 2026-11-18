import 'package:flutter/material.dart';
import 'company_identity_code.dart';
import 'horizontal_tab_selector.dart';
import 'services/plan_progress_service.dart';
import 'widgets/step_owner_approval_panel.dart';

/// A page for managing and developing company identity elements.
///
/// Company assessment lives under Strategic Planning (step 2), not here.
class CompanyIdentityPage extends StatefulWidget {
  /// Creates a CompanyIdentityPage.
  const CompanyIdentityPage({
    super.key,
    this.onSaveAndContinue,
    this.onProgressChanged,
    this.isOwner = true,
    this.stepProgress,
    this.onApproveStep,
  });

  final Future<void> Function()? onSaveAndContinue;
  final VoidCallback? onProgressChanged;
  final bool isOwner;
  final StepProgressInfo? stepProgress;
  final Future<void> Function()? onApproveStep;

  @override
  State<CompanyIdentityPage> createState() => _CompanyIdentityPageState();
}

class _CompanyIdentityPageState extends State<CompanyIdentityPage> {
  CompanyIdentityTabPanel _panel = CompanyIdentityTabPanel.companyIdentity;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Company Identity',
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
          'Define your company’s core identity in MyCatalystPlan.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        HorizontalTabSelector(
          key: ValueKey(_panel),
          initialIndex: _panel.index,
          onTabChanged: (i) {
            if (i < 0 || i >= CompanyIdentityTabPanel.values.length) return;
            setState(() => _panel = CompanyIdentityTabPanel.values[i]);
          },
          tabs: const [
            TabItem(title: 'Company Identity'),
            TabItem(title: 'Company Background'),
          ],
        ),
        const SizedBox(height: 16),
        StepOwnerApprovalPanel(
          stepIndex: 1,
          stepProgress: widget.stepProgress,
          isOwner: widget.isOwner,
          onApprove: widget.onApproveStep,
        ),
        const SizedBox(height: 16),
        CompanyIdentityTab(
          panel: _panel,
          onSaveAndContinue: widget.onSaveAndContinue,
          onProgressChanged: widget.onProgressChanged,
          onAdvanceToIdentityTab: () {
            setState(() => _panel = CompanyIdentityTabPanel.companyIdentity);
          },
        ),
      ],
    );
  }
}
