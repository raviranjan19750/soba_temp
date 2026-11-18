import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/services/plan_progress_service.dart';
import 'package:flutter/material.dart';

/// User choice after a step's final Save & Continue.
enum StepContinueChoice {
  /// Owner approves the step (optionally continues afterward).
  approve,

  /// Collaborator requests owner approval (optionally continues afterward).
  requestApproval,

  /// Move to the next roadmap step without an approval action.
  continueNext,

  /// Remain on the current step.
  stay,
}

/// Result of [StepContinueApprovalDialog.show].
class StepContinueApprovalResult {
  const StepContinueApprovalResult({
    required this.choice,
    this.continueAfterAction = false,
  });

  final StepContinueChoice choice;
  final bool continueAfterAction;
}

/// Dialog shown after Save & Continue so owners can approve or collaborators
/// can request approval before advancing to the next step.
class StepContinueApprovalDialog extends StatelessWidget {
  const StepContinueApprovalDialog({
    super.key,
    required this.stepIndex,
    required this.stepProgress,
    required this.isOwner,
    required this.hasNextStep,
  });

  final int stepIndex;
  final StepProgressInfo? stepProgress;
  final bool isOwner;
  final bool hasNextStep;

  static Future<StepContinueApprovalResult?> show({
    required BuildContext context,
    required int stepIndex,
    required StepProgressInfo? stepProgress,
    required bool isOwner,
    required bool hasNextStep,
  }) {
    return showDialog<StepContinueApprovalResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StepContinueApprovalDialog(
        stepIndex: stepIndex,
        stepProgress: stepProgress,
        isOwner: isOwner,
        hasNextStep: hasNextStep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepNum = catalystDisplayStepNumber(stepIndex);
    final step = stepProgress;
    final approved = step?.isApproved ?? false;
    final draftReady = step?.isDraftComplete ?? false;
    final approvalRequested = step?.approvalRequested ?? false;
    final nextStepNum = catalystDisplayStepNumber(stepIndex + 1);

    return AlertDialog(
      title: Text('Step $stepNum saved'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approved
                  ? 'Step $stepNum is already approved.'
                  : draftReady
                      ? isOwner
                          ? 'Draft work is ready. Approve Step $stepNum to finalize it '
                              'for your team, or continue without approving yet.'
                          : approvalRequested
                              ? 'Your approval request is on file. The primary owner '
                                  'will review Step $stepNum when ready.'
                              : 'Draft work is saved. Request owner approval or continue '
                                  'to the next step.'
                      : 'Your progress is saved. Complete the remaining requirements '
                          'before this step can be approved.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
            if (step != null && !draftReady && step.missingItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Still needed:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              ...step.missingItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.grey.shade600)),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const StepContinueApprovalResult(choice: StepContinueChoice.stay),
          ),
          child: Text('Stay on Step $stepNum'),
        ),
        if (hasNextStep)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const StepContinueApprovalResult(
                choice: StepContinueChoice.continueNext,
              ),
            ),
            child: Text('Continue to Step $nextStepNum'),
          ),
        if (!approved && isOwner && draftReady) ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(
              context,
              StepContinueApprovalResult(
                choice: StepContinueChoice.approve,
                continueAfterAction: hasNextStep,
              ),
            ),
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: Text(
              hasNextStep ? 'Approve & continue' : 'Approve Step $stepNum',
            ),
          ),
        ],
        if (!approved && !isOwner && !approvalRequested)
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(
              context,
              StepContinueApprovalResult(
                choice: StepContinueChoice.requestApproval,
                continueAfterAction: hasNextStep,
              ),
            ),
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(
              hasNextStep
                  ? 'Request approval & continue'
                  : 'Request owner approval',
            ),
          ),
      ],
    );
  }
}
