import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/services/plan_progress_service.dart';
import 'package:athari_partners/widgets/step_owner_approval_panel.dart';
import 'package:flutter/material.dart';

/// Context for the Catalyst steps: recommended order and quick navigation.
class PlanningRoadmapBanner extends StatelessWidget {
  const PlanningRoadmapBanner({
    super.key,
    required this.selectedStep,
    required this.onSelectStep,
    this.progress,
    this.isProgressLoading = false,
    this.isOwner = true,
    this.onApproveStep,
  });

  /// Active main-nav step index.
  final int selectedStep;

  final ValueChanged<int> onSelectStep;

  final PlanProgressSnapshot? progress;

  /// True only on the first progress fetch (shows a fixed-height placeholder).
  final bool isProgressLoading;

  /// When false, user can collaborate but cannot approve steps.
  final bool isOwner;

  final Future<void> Function(int stepIndex)? onApproveStep;

  static const _accent = Color(0xFF2E7D32);
  static const _accentDeep = Color(0xFF1B5E20);

  Future<void> _handleNext(BuildContext context) async {
    final nextStep = selectedStep + 1;
    if (nextStep >= catalystPlanningSteps.length) return;

    final current = progress?.steps[selectedStep.clamp(
      0,
      catalystPlanningSteps.length - 1,
    )];
    if (current != null && !current.isApproved) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            current.isDraftComplete
                ? 'Step awaiting owner approval'
                : 'Step not complete',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (current.isDraftComplete && !current.isApproved)
                const Text(
                  'Draft work is ready, but the primary owner has not approved '
                  'this step yet.',
                  style: TextStyle(height: 1.45),
                )
              else
                Text(
                  'Step ${catalystDisplayStepNumber(selectedStep)} still has incomplete items:',
                  style: const TextStyle(height: 1.45),
                ),
              if (!current.isDraftComplete) ...[
                const SizedBox(height: 10),
                ...current.missingItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text('Continue to the next step anyway?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay here'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    onSelectStep(nextStep);
  }

  @override
  Widget build(BuildContext context) {
    final step = catalystPlanningSteps[selectedStep.clamp(
      0,
      catalystPlanningSteps.length - 1,
    )];
    final hasNext = selectedStep < catalystPlanningSteps.length - 1;
    final nextTitle = hasNext
        ? catalystPlanningSteps[selectedStep + 1].title
        : null;
    final snapshot = progress;
    final fullRoadmapPct = ((snapshot?.fullRoadmapPercent ?? 0) * 100).round();
    final fullApproved = snapshot?.fullRoadmapApprovedCount ?? 0;
    final fullDraftReady = snapshot?.fullRoadmapDraftReadyCount ?? 0;

    return Card(
      elevation: 0,
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.route_rounded, color: _accentDeep, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Catalyst roadmap',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isOwner
                            ? 'Step 0 sets up your company profile. Steps 1–5 are the strategic plan—'
                                'you approve each when draft work is ready. Focus: ${step.title}.'
                            : 'Collaborate on Step 0 and the 5-step plan. The primary owner '
                                'approves each step. Focus: ${step.title}.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (snapshot != null) ...[
                        const SizedBox(height: 14),
                        _ProgressSummary(
                          fullRoadmapPct: fullRoadmapPct,
                          fullApproved: fullApproved,
                          fullDraftReady: fullDraftReady,
                        ),
                        const SizedBox(height: 12),
                        _TrackingLegend(),
                        const SizedBox(height: 14),
                        _StepCompletionTracker(
                          selectedStep: selectedStep,
                          progress: snapshot,
                          onSelectStep: onSelectStep,
                        ),
                        if (isOwner &&
                            onApproveStep != null &&
                            catalystStepRequiresApproval(selectedStep)) ...[
                          const SizedBox(height: 12),
                          _OwnerApprovalBar(
                            selectedStep: selectedStep,
                            progress: snapshot,
                            onApproveStep: onApproveStep!,
                          ),
                        ],
                      ] else if (isProgressLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: _ProgressLoadingPlaceholder(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasNext && nextTitle != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _handleNext(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text('Next: $nextTitle'),
                  style: TextButton.styleFrom(
                    foregroundColor: _accentDeep,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressLoadingPlaceholder extends StatelessWidget {
  const _ProgressLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.fullRoadmapPct,
    required this.fullApproved,
    required this.fullDraftReady,
  });

  final int fullRoadmapPct;
  final int fullApproved;
  final int fullDraftReady;

  static const _accent = Color(0xFF2E7D32);
  static const _accentDeep = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final fullValue = (fullRoadmapPct / 100).clamp(0.0, 1.0);
    final fullLabel =
        '$fullRoadmapPct% • $fullApproved/6 approved • $fullDraftReady ready';

    return _metricRow(
      label: 'Catalyst roadmap (Steps 0–5)',
      valueLabel: fullLabel,
      value: fullValue,
      color: _accent,
      valueColor: _accentDeep,
    );
  }

  Widget _metricRow({
    required String label,
    required String valueLabel,
    required double value,
    required Color color,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: valueColor ?? color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TrackingLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: const [
        _LegendDot(color: Color(0xFF94A3B8), label: 'Not started'),
        _LegendDot(color: Color(0xFF2E7D32), label: 'In progress'),
        _LegendDot(color: Color(0xFFD97706), label: 'Draft ready'),
        _LegendDot(color: Color(0xFF16A34A), label: 'Approved'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Unified six-step roadmap tracker (Step 0 profile through Step 5 execute).
class _StepCompletionTracker extends StatelessWidget {
  const _StepCompletionTracker({
    required this.selectedStep,
    required this.progress,
    required this.onSelectStep,
  });

  final int selectedStep;
  final PlanProgressSnapshot progress;
  final ValueChanged<int> onSelectStep;

  static const _complete = Color(0xFF16A34A);
  static const _profileAccent = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final nodeRow = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < catalystPlanningSteps.length; i++) ...[
              if (i > 0)
                _StepConnector(
                  previousApproved: progress.isStepComplete(i - 1),
                  isProfileBridge: i == 1,
                  compact: compact,
                ),
              _StepNode(
                stepIndex: i,
                isActive: selectedStep == i,
                isApproved: progress.isStepComplete(i),
                isDraftComplete: i < progress.steps.length
                    ? progress.steps[i].isDraftComplete
                    : false,
                compact: compact,
                onTap: () => onSelectStep(i),
              ),
            ],
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Catalyst roadmap',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _profileAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _profileAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '0',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _profileAccent,
                    ),
                  ),
                ),
                Text(
                  ' Profile  →  ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _complete.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _complete.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '1–5',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _complete.withValues(alpha: 0.95),
                    ),
                  ),
                ),
                Text(
                  ' Plan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (compact)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: nodeRow,
                ),
              )
            else
              Center(child: nodeRow),
          ],
        );
      },
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({
    required this.previousApproved,
    required this.isProfileBridge,
    required this.compact,
  });

  final bool previousApproved;
  final bool isProfileBridge;
  final bool compact;

  static const _complete = Color(0xFF16A34A);
  static const _profileAccent = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final color = previousApproved
        ? (isProfileBridge ? _profileAccent : _complete).withValues(alpha: 0.75)
        : Colors.grey.shade300;

    return Container(
      width: compact ? 14 : 22,
      height: 3,
      margin: EdgeInsets.only(
        top: compact ? 13 : 15,
        left: 1,
        right: 1,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: color,
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.stepIndex,
    required this.isActive,
    required this.isApproved,
    required this.isDraftComplete,
    required this.compact,
    required this.onTap,
  });

  final int stepIndex;
  final bool isActive;
  final bool isApproved;
  final bool isDraftComplete;
  final bool compact;
  final VoidCallback onTap;

  static const _accent = Color(0xFF2E7D32);
  static const _complete = Color(0xFF16A34A);
  static const _pending = Color(0xFFD97706);
  static const _profileAccent = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final meta = catalystPlanningSteps[stepIndex];
    final isProfile = stepIndex == 0;
    final awaitingApproval = isDraftComplete && !isApproved;
    final borderColor = isApproved
        ? _complete
        : awaitingApproval
            ? _pending
            : isActive
                ? (isProfile ? _profileAccent : _accent)
                : Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: compact ? 28 : 32,
              height: compact ? 28 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isApproved
                    ? _complete
                    : awaitingApproval
                        ? _pending.withValues(alpha: 0.15)
                        : isActive
                            ? (isProfile
                                    ? _profileAccent
                                    : _accent)
                                .withValues(alpha: 0.12)
                            : Colors.white,
                border: Border.all(color: borderColor, width: isActive ? 2.5 : 2),
                boxShadow: isApproved
                    ? [
                        BoxShadow(
                          color: _complete.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : isActive
                        ? [
                            BoxShadow(
                              color: (isProfile ? _profileAccent : _accent)
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
              ),
              child: Center(
                child: isApproved
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : awaitingApproval
                        ? Icon(Icons.schedule_rounded,
                            color: _pending, size: compact ? 14 : 16)
                        : Text(
                            '${catalystDisplayStepNumber(stepIndex)}',
                            style: TextStyle(
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? (isProfile ? _profileAccent : _accent)
                                  : Colors.grey.shade600,
                            ),
                          ),
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            SizedBox(
              width: compact ? 56 : 68,
              child: Text(
                meta.shortTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  height: 1.2,
                  fontWeight:
                      isActive || isApproved ? FontWeight.w700 : FontWeight.w500,
                  color: isApproved
                      ? _complete
                      : awaitingApproval
                          ? _pending
                          : isActive
                              ? (isProfile ? _profileAccent : _accent)
                              : Colors.grey.shade600,
                ),
              ),
            ),
            if (isApproved) ...[
              const SizedBox(height: 2),
              Text(
                'Approved',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _complete,
                  letterSpacing: 0.3,
                ),
              ),
            ] else if (awaitingApproval) ...[
              const SizedBox(height: 2),
              Text(
                'Ready',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _pending,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerApprovalBar extends StatelessWidget {
  const _OwnerApprovalBar({
    required this.selectedStep,
    required this.progress,
    required this.onApproveStep,
  });

  final int selectedStep;
  final PlanProgressSnapshot progress;
  final Future<void> Function(int stepIndex) onApproveStep;

  @override
  Widget build(BuildContext context) {
    final step = progress.steps[selectedStep.clamp(
      0,
      progress.steps.length - 1,
    )];

    return StepOwnerApprovalPanel(
      stepIndex: selectedStep,
      stepProgress: step,
      isOwner: true,
      compact: true,
      onApprove: () => onApproveStep(selectedStep),
    );
  }
}
