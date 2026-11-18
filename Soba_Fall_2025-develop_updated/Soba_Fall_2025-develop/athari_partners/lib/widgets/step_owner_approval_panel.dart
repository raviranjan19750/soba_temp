import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/services/plan_progress_service.dart';
import 'package:flutter/material.dart';

/// Owner/collaborator approval status and primary-owner approve action for a step.
class StepOwnerApprovalPanel extends StatelessWidget {
  const StepOwnerApprovalPanel({
    super.key,
    required this.stepIndex,
    required this.stepProgress,
    required this.isOwner,
    this.onApprove,
    this.compact = false,
  });

  final int stepIndex;
  final StepProgressInfo? stepProgress;
  final bool isOwner;
  final Future<void> Function()? onApprove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final step = stepProgress;
    if (step == null) return const SizedBox.shrink();

    final stepNum = catalystDisplayStepNumber(stepIndex);
    final approved = step.isApproved;
    final draftReady = step.isDraftComplete && !approved;
    final approvalRequested = step.approvalRequested && !approved;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: approved
            ? const Color(0xFFF0FDF4)
            : draftReady
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: approved
              ? const Color(0xFF86EFAC)
              : draftReady
                  ? const Color(0xFFFCD34D)
                  : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved
                    ? Icons.verified_outlined
                    : draftReady
                        ? Icons.schedule_rounded
                        : Icons.edit_note_outlined,
                size: 20,
                color: approved
                    ? const Color(0xFF16A34A)
                    : draftReady
                        ? const Color(0xFFD97706)
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Step $stepNum approval',
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (approved)
            Text(
              'Step $stepNum is approved and finalized.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            )
          else if (draftReady && isOwner)
            Text(
              approvalRequested
                  ? 'A collaborator requested approval. Review Step $stepNum and '
                      'approve when requirements are met.'
                  : 'Draft work is ready. As the primary owner, approve Step $stepNum '
                      'to finalize it for the team.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            )
          else if (draftReady && !isOwner)
            Text(
              approvalRequested
                  ? 'Your approval request was sent. The primary owner will review '
                      'Step $stepNum when ready.'
                  : 'Draft work is saved. The primary owner will approve Step $stepNum '
                      'when ready.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            )
          else if (approvalRequested && isOwner)
            Text(
              'A collaborator requested approval for Step $stepNum. '
              'Review the draft and approve when requirements are met.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD97706),
                height: 1.45,
              ),
            )
          else ...[
            Text(
              'Complete the draft requirements before Step $stepNum can be approved:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
            if (step.missingItems.isNotEmpty) ...[
              const SizedBox(height: 8),
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
          if (isOwner && onApprove != null && draftReady) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: Text('Approve Step $stepNum'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
