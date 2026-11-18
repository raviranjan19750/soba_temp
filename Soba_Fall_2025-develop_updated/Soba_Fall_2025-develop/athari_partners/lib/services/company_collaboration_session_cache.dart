/// Local collaboration state when Firebase persistence is skipped.
class CompanyCollaborationSessionCache {
  static String companyRole = 'owner';
  static String inviteCode = 'DEMO-INVITE';
  static final Set<int> approvedSteps = {};
  static final Set<int> approvalRequestedSteps = {};

  static void reset() {
    companyRole = 'owner';
    inviteCode = 'DEMO-INVITE';
    approvedSteps.clear();
    approvalRequestedSteps.clear();
  }

  static void setRole(String role) {
    companyRole = role;
  }

  static void approveStep(int stepIndex) {
    approvedSteps.add(stepIndex);
    approvalRequestedSteps.remove(stepIndex);
  }

  static bool isStepApproved(int stepIndex) => approvedSteps.contains(stepIndex);

  static void requestStepApproval(int stepIndex) {
    approvalRequestedSteps.add(stepIndex);
  }

  static bool isStepApprovalRequested(int stepIndex) =>
      approvalRequestedSteps.contains(stepIndex);
}
