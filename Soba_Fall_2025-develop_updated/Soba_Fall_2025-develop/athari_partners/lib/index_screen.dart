import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/auth_config.dart';
import 'package:athari_partners/company_profile_page.dart';
import 'package:athari_partners/planning_roadmap_banner.dart';
import 'package:athari_partners/company_identity_page.dart';
import 'package:athari_partners/strategic_planning_page.dart';
import 'package:athari_partners/year_one_plan_page.dart';
import 'package:athari_partners/landing_page.dart';
import 'package:athari_partners/services/company_membership_service.dart';
import 'package:athari_partners/services/company_role.dart';
import 'package:athari_partners/services/plan_progress_service.dart';
import 'package:athari_partners/services/strategic_areas_session_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'execute_and_monitor_page.dart';
import 'widgets/step_continue_approval_dialog.dart';

/// Main application screen that serves as the container for different strategic planning sections.
///
/// This screen provides a navigation framework with a custom app bar and displays
/// different content pages based on the user's selection in the navigation menu.
class IndexScreen extends StatefulWidget {
  /// Creates an IndexScreen.
  ///
  /// [initialProcessStep] selects which Catalyst Planning step is active (0–5).
  /// Step 0 is Company Profile.
  const IndexScreen({super.key, this.initialProcessStep = 0})
      : assert(initialProcessStep >= 0 &&
            initialProcessStep < catalystPlanningStepCount);

  /// 0 = Company Profile … 5 = Execute & Monitor
  final int initialProcessStep;

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

/// State for [IndexScreen] that manages the current active page and navigation.
class _IndexScreenState extends State<IndexScreen> {
  /// Selected Catalyst Planning process step, mapped to app sections.
  late int _selectedProcessStep;

  PlanProgressSnapshot? _planProgress;
  bool _loadingProgress = true;
  bool _refreshInFlight = false;
  String? _companyRole;
  late final VoidCallback _onProgressRevision;

  bool get _isOwner => CompanyRole.isOwner(_companyRole);

  @override
  void initState() {
    super.initState();
    _selectedProcessStep = widget.initialProcessStep.clamp(
      0,
      catalystPlanningSteps.length - 1,
    );
    _onProgressRevision = () => _refreshPlanProgress();
    PlanProgressService.revision.addListener(_onProgressRevision);
    if (skipFirebasePersistence) {
      StrategicAreasSessionCache.areasNotifier.addListener(_onProgressRevision);
    }
    _loadCompanyRole();
    _refreshPlanProgress(showCompletionToast: false);
  }

  Future<void> _loadCompanyRole() async {
    final role = await CompanyMembershipService.loadCompanyRoleForCurrentUser();
    if (mounted) setState(() => _companyRole = role);
  }

  @override
  void dispose() {
    PlanProgressService.revision.removeListener(_onProgressRevision);
    if (skipFirebasePersistence) {
      StrategicAreasSessionCache.areasNotifier.removeListener(_onProgressRevision);
    }
    super.dispose();
  }

  Future<void> _refreshPlanProgress({bool showCompletionToast = true}) async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    final isInitialLoad = _planProgress == null;
    if (isInitialLoad && mounted) {
      setState(() => _loadingProgress = true);
    }

    try {
      final companyId = await loadCompanyIdForCurrentUser();
      final previous = _planProgress;
      final progress = await PlanProgressService.evaluate(companyId);
      if (!mounted) return;

      if (showCompletionToast && previous != null) {
        for (var i = 0; i < progress.steps.length; i++) {
          final prev = previous.steps[i];
          final curr = progress.steps[i];
          if (!prev.isApproved && curr.isApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Step ${catalystDisplayStepNumber(i)} approved — ${catalystPlanningSteps[i].shortTitle}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
            break;
          }
          if (!prev.isDraftComplete && curr.isDraftComplete && !curr.isApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isOwner
                            ? 'Step ${catalystDisplayStepNumber(i)} draft is ready for your approval'
                            : 'Step ${catalystDisplayStepNumber(i)} draft saved — awaiting owner approval',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFD97706),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
            break;
          }
        }
      }
      setState(() {
        _planProgress = progress;
        _loadingProgress = false;
      });
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  void didUpdateWidget(IndexScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProcessStep != oldWidget.initialProcessStep) {
      setState(() {
        _selectedProcessStep = widget.initialProcessStep.clamp(
          0,
          catalystPlanningSteps.length - 1,
        );
      });
    }
  }

  // Logout method
  Future<void> _logout() async {
    if (authBypassEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demo mode is on (BYPASS_AUTH=true). Set BYPASS_AUTH=false in '
              '.env, restart the app, then sign in.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate explicitly to landing page
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyCatalystPlanLandingPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message if logout fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _displayNameForAppBar(Map<String, dynamic>? data, User? authUser) {
    if (data != null) {
      final dn = (data['displayName'] as String?)?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
      final fn = (data['firstName'] as String?)?.trim() ?? '';
      final ln = (data['lastName'] as String?)?.trim() ?? '';
      final combined = '$fn $ln'.trim();
      if (combined.isNotEmpty) return combined;
    }
    return (authUser?.displayName ?? '').trim();
  }

  Future<void> _approveStep(int stepIndex) async {
    final companyId = await loadCompanyIdForCurrentUser();
    try {
      await PlanProgressService.approveStep(
        companyId: companyId,
        stepIndex: stepIndex,
      );
      await _refreshPlanProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Step ${catalystDisplayStepNumber(stepIndex)} approved and finalized',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('StateError: ', '')),
            backgroundColor: const Color(0xFFB45309),
          ),
        );
      }
    }
  }

  Future<void> _requestStepApproval(int stepIndex) async {
    final companyId = await loadCompanyIdForCurrentUser();
    try {
      await PlanProgressService.requestStepApproval(
        companyId: companyId,
        stepIndex: stepIndex,
      );
      await _refreshPlanProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Approval requested for Step ${catalystDisplayStepNumber(stepIndex)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('StateError: ', '')),
            backgroundColor: const Color(0xFFB45309),
          ),
        );
      }
    }
  }

  Future<void> _handleStepSaveAndContinue(int stepIndex) async {
    await _refreshPlanProgress();
    if (!mounted) return;

    if (!catalystStepRequiresApproval(stepIndex)) {
      return;
    }

    final isLastStep = stepIndex >= catalystPlanningSteps.length - 1;
    final result = await StepContinueApprovalDialog.show(
      context: context,
      stepIndex: stepIndex,
      stepProgress: _planProgress?.stepAt(stepIndex),
      isOwner: _isOwner,
      hasNextStep: !isLastStep,
    );
    if (!mounted || result == null) return;

    switch (result.choice) {
      case StepContinueChoice.stay:
        return;
      case StepContinueChoice.approve:
        await _approveStep(stepIndex);
        if (!mounted) return;
        if (result.continueAfterAction && !isLastStep) {
          await _advanceToNextStep();
        }
      case StepContinueChoice.requestApproval:
        await _requestStepApproval(stepIndex);
        if (!mounted) return;
        if (result.continueAfterAction && !isLastStep) {
          await _advanceToNextStep();
        }
      case StepContinueChoice.continueNext:
        if (!isLastStep) {
          await _advanceToNextStep();
        }
    }
  }

  Future<void> _advanceToNextStep() async {
    final next = (_selectedProcessStep + 1).clamp(
      0,
      catalystPlanningSteps.length - 1,
    );
    if (next == _selectedProcessStep) return;
    setState(() => _selectedProcessStep = next);
    await _refreshPlanProgress();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid;

    final PreferredSizeWidget appBarWidget;
    if (uid == null) {
      appBarWidget = CustomAppBar(
        leftIcon: const MyCatalystPlanAppBarBrand(),
        leadingWidth: 280,
        middleWidgets: _processStepNavWidgets(),
        onLogoutPressed: _logout,
        logoutButtonText: 'Log Out',
      );
    } else {
      appBarWidget = PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            final doc = userSnap.data;
            final data = doc?.data();
            final name = _displayNameForAppBar(data, authUser);
            return CustomAppBar(
              leftIcon: const MyCatalystPlanAppBarBrand(),
              leadingWidth: 280,
              middleWidgets: _processStepNavWidgets(),
              userDisplayName: name.isEmpty ? null : name,
              onLogoutPressed: _logout,
              logoutButtonText: 'Log Out',
            );
          },
        ),
      );
    }

    final w = MediaQuery.sizeOf(context).width;
    final horizontalPad = w < 600 ? 16.0 : (w < 1100 ? 24.0 : 50.0);
    final verticalPad = w < 600 ? 16.0 : 30.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBarWidget,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPad,
          vertical: verticalPad,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlanningRoadmapBanner(
                selectedStep: _selectedProcessStep,
                progress: _planProgress,
                isProgressLoading: _loadingProgress && _planProgress == null,
                isOwner: _isOwner,
                onApproveStep: _isOwner ? _approveStep : null,
                onSelectStep: (i) {
                  setState(() => _selectedProcessStep = i.clamp(
                        0,
                        catalystPlanningSteps.length - 1,
                      ));
                },
              ),
              SizedBox(height: w < 600 ? 16 : 20),
              _buildPage(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _processStepNavWidgets() {
    return [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var i = 0; i < catalystPlanningSteps.length; i++) ...[
                if (i == 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 1,
                      height: 28,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ] else if (i > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      ' > ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                _LoggedInProcessStepNavChip(
                  stepIndex: i,
                  isActive: _selectedProcessStep == i,
                  isComplete: _planProgress?.isStepComplete(i) ?? false,
                  isDraftReady: _planProgress != null &&
                      i < _planProgress!.steps.length &&
                      _planProgress!.steps[i].isDraftComplete &&
                      !_planProgress!.isStepComplete(i),
                  onTap: () {
                    setState(() => _selectedProcessStep = i);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  /// Builds the content widget for the currently active page.
  ///
  /// Returns a widget corresponding to the current [_currentPage] value.
  /// Uses a switch expression to determine which page content to display.
  /// Returns a placeholder text for unimplemented pages.
  Widget _buildPage() {
    // Steps 2–3 (indices 1–2) both use the Strategic Planning workspace.
    switch (_selectedProcessStep) {
      case 0:
        return CompanyProfilePage(
          embedded: true,
          onSaveAndContinue: () => _handleStepSaveAndContinue(0),
        );
      case 1:
        return CompanyIdentityPage(
          onSaveAndContinue: () => _handleStepSaveAndContinue(1),
          onProgressChanged: () => _refreshPlanProgress(),
          isOwner: _isOwner,
          stepProgress: _planProgress?.stepAt(1),
          onApproveStep: _isOwner ? () => _approveStep(1) : null,
        );
      case 2:
        return StrategicPlanningPage(
          companyAssessmentOnly: true,
          onStepComplete: () => _handleStepSaveAndContinue(2),
        );
      case 3:
        return StrategicPlanningPage(
          initialSubTabIndex: 0,
          onStepComplete: () => _handleStepSaveAndContinue(3),
        );
      case 4:
        return YearOnePlanPage(
          onSaveAndContinue: () => _handleStepSaveAndContinue(4),
        );
      case 5:
        return ExecuteAndMonitorPage(
          onProgressChanged: () => _refreshPlanProgress(),
        );
      default:
        return CompanyProfilePage(
          embedded: true,
          onSaveAndContinue: () => _handleStepSaveAndContinue(0),
        );
    }
  }
}

/// Compact nav label for one Catalyst Planning step (logged-in app bar).
class _LoggedInProcessStepNavChip extends StatelessWidget {
  const _LoggedInProcessStepNavChip({
    required this.stepIndex,
    required this.isActive,
    required this.isComplete,
    required this.isDraftReady,
    required this.onTap,
  });

  final int stepIndex;
  final bool isActive;
  final bool isComplete;
  final bool isDraftReady;
  final VoidCallback onTap;

  static const _accent = Color(0xFF2E7D32);
  static const _profileAccent = Color(0xFF2563EB);
  static const _pending = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final stepMeta = catalystPlanningSteps[stepIndex];
    final label = catalystStepNavLabel(stepIndex);
    final completeColor = const Color(0xFF16A34A);
    final isProfile = stepIndex == 0;
    final accent = isProfile ? _profileAccent : _accent;
    final borderColor = isComplete
        ? completeColor
        : isDraftReady
            ? _pending
            : isActive
                ? accent
                : Colors.transparent;
    return Tooltip(
      message: isComplete
          ? '${stepMeta.title} — approved'
          : isDraftReady
              ? '${stepMeta.title} — draft ready for approval'
              : stepMeta.title,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isComplete
                ? completeColor.withValues(alpha: 0.12)
                : isDraftReady
                    ? _pending.withValues(alpha: 0.1)
                    : isActive
                        ? accent.withValues(alpha: 0.08)
                        : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor.withValues(
                alpha: isComplete || isDraftReady || isActive ? 0.55 : 0,
              ),
              width: isComplete || isDraftReady || isActive ? 1.5 : 0,
            ),
            boxShadow: isComplete
                ? [
                    BoxShadow(
                      color: completeColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isComplete)
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: completeColor)
                else if (isDraftReady)
                  Icon(Icons.schedule_rounded, size: 14, color: _pending)
                else
                  Icon(
                    isActive ? Icons.radio_button_checked : Icons.circle_outlined,
                    size: isActive ? 12 : 10,
                    color: isActive ? accent : Colors.grey.shade400,
                  ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: isComplete
                        ? completeColor
                        : isDraftReady
                            ? _pending
                            : isActive
                                ? accent
                                : Colors.grey.shade700,
                    fontWeight:
                        isComplete || isActive ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                if (isComplete) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Approved',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: completeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ] else if (isDraftReady) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ready',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _pending,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom app bar widget that provides flexible navigation and branding.
///
/// This widget implements [PreferredSizeWidget] to be used as an AppBar replacement
/// with customizable left icon, middle navigation items, and logout button.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a CustomAppBar.
  ///
  /// [middleWidgets]: List of widgets to display in the center (typically navigation items)
  /// [onLogoutPressed]: Callback when logout button is pressed
  /// [onIconPressed]: Callback when left icon is pressed
  /// [leftIcon]: Widget to display on the left (typically a logo)
  /// [logoutButtonText]: Text to display on the logout button
  /// [backgroundColor]: Background color of the app bar
  /// [elevation]: Elevation/shadow of the app bar
  const CustomAppBar({
    super.key,
    this.middleWidgets = const [],
    this.onLogoutPressed,
    this.onIconPressed,
    this.leftIcon,
    this.leadingWidth = 100,
    this.logoutButtonText = 'Log Out',
    this.userDisplayName,
    this.backgroundColor = Colors.white,
    this.elevation = 0,
  });

  /// Navigation items displayed in the center of the app bar
  final List<Widget> middleWidgets;

  /// Shown at the trailing end (before Log out) when non-null and non-empty.
  final String? userDisplayName;

  /// Callback function when logout button is pressed
  final VoidCallback? onLogoutPressed;

  /// Callback function when left icon is pressed
  final VoidCallback? onIconPressed;

  /// Widget displayed on the left side (typically a logo)
  final Widget? leftIcon;

  /// Width reserved for [leftIcon] (increase when using text + icon branding)
  final double leadingWidth;

  /// Text displayed on the logout button
  final String logoutButtonText;

  /// Background color of the app bar
  final Color backgroundColor;

  /// Elevation level for shadow effect
  final double elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      leading: leftIcon,
      leadingWidth: leadingWidth,
      title: middleWidgets.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: middleWidgets,
            )
          : null,
      actions: [
        if (userDisplayName != null && userDisplayName!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  userDisplayName!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            onPressed:
                onLogoutPressed ??
                () {
                  // Default logout behavior - show a snackbar when no custom callback provided
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logout button pressed')),
                  );
                },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // Red color for logout
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 16),
                const SizedBox(width: 4),
                Text(
                  logoutButtonText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A navigation menu item widget for use in the custom app bar.
///
/// This widget represents a single navigation item that can be active or inactive
/// and triggers a callback when pressed.
/// Left app bar brand: replaces legacy Athari Partners logo asset with MyCatalystPlan + GROWTH Catalyst HQ.
class MyCatalystPlanAppBarBrand extends StatelessWidget {
  const MyCatalystPlanAppBarBrand({super.key});

  static const _accent = Color(0xFF2E7D32);
  static const _accentDeep = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accent, _accentDeep],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accent, _accentDeep],
                  ).createShader(bounds),
                  child: const Text(
                    'MyCatalystPlan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                ),
                Text(
                  'A product of GROWTH Catalyst HQ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppBarMenuItem extends StatelessWidget {
  /// Creates an AppBarMenuItem.
  ///
  /// [label]: The text to display on the menu item
  /// [isActive]: Whether this item is currently active/selected
  /// [onPressed]: Callback function when the item is pressed
  const AppBarMenuItem({
    super.key,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  /// The text label displayed on the menu item
  final String label;

  /// Whether this menu item is currently active/selected
  final bool isActive;

  /// Callback function when the menu item is pressed
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => onPressed(),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.black : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
