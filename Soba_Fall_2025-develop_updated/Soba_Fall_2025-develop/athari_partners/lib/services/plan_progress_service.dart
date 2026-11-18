import 'package:athari_partners/auth_config.dart';
import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/services/company_profile_session_cache.dart';
import 'package:athari_partners/services/goals_session_cache.dart';
import 'package:athari_partners/services/identity_session_cache.dart';
import 'package:athari_partners/services/strategic_areas_session_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'company_collaboration_session_cache.dart';
import 'company_membership_service.dart';
import 'company_profile_service.dart';

class StepProgressInfo {
  const StepProgressInfo({
    required this.stepIndex,
    required this.title,
    required this.isDraftComplete,
    required this.isApproved,
    required this.percent,
    required this.missingItems,
    this.approvalRequested = false,
  });

  final int stepIndex;
  final String title;
  final bool isDraftComplete;
  final bool isApproved;
  final double percent;
  final List<String> missingItems;
  final bool approvalRequested;

  /// Roadmap "done" state — owner approval required except on living steps (e.g. Step 5).
  bool get isComplete =>
      !catalystStepRequiresApproval(stepIndex) || isApproved;
}

class PlanProgressSnapshot {
  const PlanProgressSnapshot({
    required this.steps,
    required this.overallPercent,
  });

  final List<StepProgressInfo> steps;
  /// Progress across Steps 1–5 only (each worth 20% when approved).
  final double overallPercent;

  static const double _fullStepWeight = 1.0 / catalystPlanningStepCount;

  /// Progress across all six steps (0–5), including Company Profile.
  double get fullRoadmapPercent => steps
      .fold<double>(
        0,
        (sum, step) =>
            sum +
            (step.isApproved
                ? _fullStepWeight
                : step.percent * _fullStepWeight),
      )
      .clamp(0.0, 1.0);

  int get fullRoadmapApprovedCount =>
      steps.where((s) => s.isApproved).length;

  int get fullRoadmapDraftReadyCount => steps
      .where((s) => s.isDraftComplete && !s.isApproved)
      .length;

  bool isStepComplete(int index) {
    if (index < 0 || index >= steps.length) return false;
    return steps[index].isComplete;
  }

  StepProgressInfo? stepAt(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  StepProgressInfo? get profileStep => stepAt(0);

  List<StepProgressInfo> get strategicSteps =>
      steps.where((s) => isStrategicPlanStep(s.stepIndex)).toList();

  int get strategicApprovedCount =>
      strategicSteps.where((s) => s.isApproved).length;

  int get strategicDraftReadyCount =>
      strategicSteps.where((s) => s.isDraftComplete && !s.isApproved).length;

  double get profilePercent => profileStep?.percent ?? 0;

  bool get isProfileApproved => profileStep?.isApproved ?? false;

  bool get isProfileDraftReady =>
      (profileStep?.isDraftComplete ?? false) && !isProfileApproved;
}

/// Evaluates completion across the Catalyst Planning steps.
class PlanProgressService {
  /// Each strategic plan step (1–5) contributes equally toward plan progress.
  static double get strategicStepWeight =>
      1.0 / catalystStrategicPlanStepCount;

  static PlanProgressSnapshot? _lastSnapshot;

  /// Bumped after each [cacheProgress] so the roadmap UI can refresh.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// Most recently evaluated snapshot (used when Firebase persistence is off).
  static PlanProgressSnapshot? get lastSnapshot => _lastSnapshot;

  static Future<PlanProgressSnapshot> evaluate(String? companyId) async {
    if (companyId == null || companyId.isEmpty) {
      return _emptySnapshot();
    }

    if (skipFirebasePersistence) {
      final snapshot = _evaluateFromSession();
      _lastSnapshot = snapshot;
      return snapshot;
    }

    final approvalState = await _loadApprovalState(companyId);
    final approvals = approvalState.approved;
    final approvalRequests = approvalState.requested;
    final companyRef =
        FirebaseFirestore.instance.collection('companies').doc(companyId);

    final results = await Future.wait<DocumentSnapshot<Map<String, dynamic>>>([
      companyRef.get(),
      companyRef.collection('companyIdentity').doc('company_background').get(),
      companyRef.collection('companyIdentity').doc('refine_company_identity').get(),
      companyRef.collection('companyAssessment').doc('swot_analysis').get(),
      companyRef.collection('companyAssessment').doc('external_assessment').get(),
      companyRef.collection('companyAssessment').doc('management_discussion_output').get(),
      companyRef.collection('strategicPlanning').doc('year3_targets').get(),
      companyRef.collection('strategicPlanning').doc('strategic_areas').get(),
      companyRef.collection('yearOnePlan').doc('goalsAndInitiatives').get(),
    ]);

    final company = results[0].data() ?? {};
    final background = results[1].data() ?? {};
    final identity = results[2].data() ?? {};
    final swot = results[3].data() ?? {};
    final external = results[4].data() ?? {};
    final mgmt = results[5].data() ?? {};
    final year3 = results[6].data() ?? {};
    final areasDoc = results[7].data() ?? {};
    final goalsDoc = results[8].data() ?? {};

    final areas = areasDoc['areas'] is List
        ? (areasDoc['areas'] as List)
            .map((e) => e?.toString() ?? '')
            .where((s) => s.trim().isNotEmpty)
            .toList()
        : <String>[];

    final perAreaGoals = goalsDoc['perAreaGoals'];
    var goalsFilled = 0;
    if (perAreaGoals is Map && areas.isNotEmpty) {
      for (final area in areas) {
        final row = perAreaGoals[area];
        if (row is Map && (row['goal']?.toString().trim().isNotEmpty ?? false)) {
          goalsFilled++;
        }
      }
    }

    final hasCompanyName = _hasText(company['companyName']);
    final recentFinancials = CompanyRecentFinancials.fromMap(company['recentFinancials']);
    final hasIndustry = _hasText(company['industry']);
    final hasWebsite = _hasText(company['website']);
    final hasLogo = _hasText(company['logoUrl']);
    final hasCity = _hasText(company['city']);
    final hasRevenue = _hasText(recentFinancials.revenue);
    final profileFilled = [
      hasCompanyName,
      hasIndustry,
      hasWebsite,
      hasLogo,
      hasCity,
      hasRevenue,
    ].where((v) => v).length;

    final hasBackground = _hasText(background['products_services']);
    final hasIdentity = _hasText(identity['mission_str']) ||
        _hasText(identity['vision_str']);
    final hasSwot = _hasSwotData(swot);
    final hasExternal = _hasText(external['customer_insights']);
    final hasMgmt = _hasText(mgmt['output_1']) ||
        _hasText(mgmt['output_2']) ||
        _hasText(mgmt['output_3']);
    final hasYear3Target = _hasNumericTarget(year3['y3R']);

    final steps = <StepProgressInfo>[
      _step(
        0,
        hasCompanyName,
        approvals[0] ?? false,
        [
          if (!hasCompanyName) 'Add company name',
        ],
        percent: profileFilled / 6,
        approvalRequested: approvalRequests[0] ?? false,
      ),
      _step(
        1,
        hasBackground && hasIdentity,
        approvals[1] ?? false,
        [
          if (!hasBackground) 'Complete company background',
          if (!hasIdentity) 'Add mission or vision',
        ],
        percent: ((hasBackground ? 1 : 0) + (hasIdentity ? 1 : 0)) / 2,
        approvalRequested: approvalRequests[1] ?? false,
      ),
      _step(
        2,
        hasSwot && hasExternal && hasMgmt,
        approvals[2] ?? false,
        [
          if (!hasSwot) 'Complete SWOT analysis',
          if (!hasExternal) 'Add customer insights',
          if (!hasMgmt) 'Document management discussion outputs',
        ],
        percent: ((hasSwot ? 1 : 0) +
                (hasExternal ? 1 : 0) +
                (hasMgmt ? 1 : 0)) /
            3,
        approvalRequested: approvalRequests[2] ?? false,
      ),
      _step(
        3,
        hasYear3Target && areas.length >= 3,
        approvals[3] ?? false,
        [
          if (!hasYear3Target) 'Set 3-year financial targets',
          if (areas.length < 3) 'Select 3–5 strategic areas',
        ],
        percent: ((hasYear3Target ? 1 : 0) +
                (areas.length >= 3 ? 1 : areas.length / 3)) /
            2,
        approvalRequested: approvalRequests[3] ?? false,
      ),
      _step(
        4,
        areas.isNotEmpty && goalsFilled >= areas.length,
        approvals[4] ?? false,
        [
          if (areas.isEmpty) 'Save strategic areas in Step 3',
          if (areas.isNotEmpty && goalsFilled < areas.length)
            'Add a goal for each strategic area',
        ],
        percent: areas.isEmpty ? 0 : goalsFilled / areas.length,
        approvalRequested: approvalRequests[4] ?? false,
      ),
      _step(
        5,
        true,
        true,
        const [],
        percent: 1.0,
        approvalRequested: false,
      ),
    ];

    final snapshot = PlanProgressSnapshot(
      steps: steps,
      overallPercent: _overallPercent(steps),
    );
    _lastSnapshot = snapshot;
    return snapshot;
  }

  /// Local-dev evaluation driven by in-memory session caches.
  static PlanProgressSnapshot _evaluateFromSession() {
    final areas = StrategicAreasSessionCache.areas;
    final goals = GoalsSessionCache.perAreaGoals;
    var goalsFilled = 0;
    for (final area in areas) {
      if (goals[area]?.hasGoal ?? false) goalsFilled++;
    }
    final hasCompanyName =
        CompanyProfileSessionCache.companyName.trim().isNotEmpty;
    final profileFilled = [
      hasCompanyName,
      CompanyProfileSessionCache.industry.trim().isNotEmpty,
      CompanyProfileSessionCache.website.trim().isNotEmpty,
      CompanyProfileSessionCache.logoUrl.trim().isNotEmpty ||
          CompanyProfileSessionCache.logoBytes != null,
      CompanyProfileSessionCache.city.trim().isNotEmpty,
      CompanyProfileSessionCache.financialRevenue.trim().isNotEmpty,
    ].where((v) => v).length;
    final hasIdentity = IdentitySessionCache.vision.trim().isNotEmpty ||
        IdentitySessionCache.mission.trim().isNotEmpty;

    final steps = <StepProgressInfo>[
      _step(
        0,
        hasCompanyName,
        CompanyCollaborationSessionCache.isStepApproved(0),
        [if (!hasCompanyName) 'Add company name'],
        percent: profileFilled / 6,
        approvalRequested:
            CompanyCollaborationSessionCache.isStepApprovalRequested(0),
      ),
      _step(
        1,
        hasIdentity,
        CompanyCollaborationSessionCache.isStepApproved(1),
        [if (!hasIdentity) 'Complete company identity'],
        percent: hasIdentity ? 1.0 : 0,
        approvalRequested:
            CompanyCollaborationSessionCache.isStepApprovalRequested(1),
      ),
      _step(
        2,
        false,
        CompanyCollaborationSessionCache.isStepApproved(2),
        const ['Complete company assessment'],
        percent: 0,
        approvalRequested:
            CompanyCollaborationSessionCache.isStepApprovalRequested(2),
      ),
      _step(
        3,
        areas.length >= 3,
        CompanyCollaborationSessionCache.isStepApproved(3),
        [
          if (areas.length < 3) 'Select 3–5 strategic areas in Step 3',
        ],
        percent: areas.length >= 3 ? 1 : areas.length / 3,
        approvalRequested:
            CompanyCollaborationSessionCache.isStepApprovalRequested(3),
      ),
      _step(
        4,
        areas.isNotEmpty && goalsFilled >= areas.length,
        CompanyCollaborationSessionCache.isStepApproved(4),
        [
          if (areas.isEmpty) 'Save strategic areas in Step 3',
          if (areas.isNotEmpty && goalsFilled < areas.length)
            'Add a goal for each strategic area',
        ],
        percent: areas.isEmpty ? 0 : goalsFilled / areas.length,
        approvalRequested:
            CompanyCollaborationSessionCache.isStepApprovalRequested(4),
      ),
      _step(
        5,
        true,
        true,
        const [],
        percent: 1.0,
        approvalRequested: false,
      ),
    ];
    return PlanProgressSnapshot(
      steps: steps,
      overallPercent: _overallPercent(steps),
    );
  }

  /// Approved strategic steps (1–5) count fully; draft work counts as partial credit.
  static double _overallPercent(List<StepProgressInfo> steps) {
    return steps
        .where((step) => isStrategicPlanStep(step.stepIndex))
        .fold<double>(
          0,
          (sum, step) =>
              sum +
              (step.isApproved
                  ? strategicStepWeight
                  : step.percent * strategicStepWeight),
        )
        .clamp(0.0, 1.0);
  }

  static PlanProgressSnapshot _emptySnapshot() {
    final steps = List.generate(
      catalystPlanningSteps.length,
      (i) => StepProgressInfo(
        stepIndex: i,
        title: catalystPlanningSteps[i].title,
        isDraftComplete: false,
        isApproved: false,
        percent: 0,
        missingItems: const ['Sign in and start planning'],
      ),
    );
    return PlanProgressSnapshot(steps: steps, overallPercent: 0);
  }

  static StepProgressInfo _step(
    int index,
    bool draftComplete,
    bool approved,
    List<String> missing, {
    required double percent,
    bool approvalRequested = false,
  }) {
    final filteredMissing =
        missing.where((m) => m.trim().isNotEmpty).toList();
    return StepProgressInfo(
      stepIndex: index,
      title: catalystPlanningSteps[index].title,
      isDraftComplete: draftComplete,
      isApproved: approved,
      percent: draftComplete ? 1.0 : percent.clamp(0.0, 1.0),
      missingItems: filteredMissing,
      approvalRequested: approvalRequested,
    );
  }

  static Future<({Map<int, bool> approved, Map<int, bool> requested})>
      _loadApprovalState(String companyId) async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('planProgress')
        .doc('summary')
        .get();
    final data = snap.data() ?? {};
    return (
      approved: {
        for (var i = 0; i < catalystPlanningSteps.length; i++)
          i: data['step_${i}_approved'] == true,
      },
      requested: {
        for (var i = 0; i < catalystPlanningSteps.length; i++)
          i: data['step_${i}_approvalRequested'] == true,
      },
    );
  }

  /// Primary owner finalizes a roadmap step after draft work is ready.
  static Future<void> approveStep({
    required String? companyId,
    required int stepIndex,
  }) async {
    if (!catalystStepRequiresApproval(stepIndex)) return;
    if (companyId == null || companyId.isEmpty) return;

    if (skipFirebasePersistence) {
      CompanyCollaborationSessionCache.approveStep(stepIndex);
      revision.value++;
      return;
    }

    final isOwner = await CompanyMembershipService.isCurrentUserOwner(companyId);
    if (!isOwner) {
      throw StateError('Only the primary company owner can approve roadmap steps.');
    }

    final snapshot = await evaluate(companyId);
    if (stepIndex < 0 || stepIndex >= snapshot.steps.length) return;
    final step = snapshot.steps[stepIndex];
    if (!step.isDraftComplete) {
      throw StateError(
        'Complete the step requirements before approving Step ${catalystDisplayStepNumber(stepIndex)}.',
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('planProgress')
        .doc('summary')
        .set(
      {
        'step_${stepIndex}_approved': true,
        'step_${stepIndex}_approvedBy': uid,
        'step_${stepIndex}_approvedAt': FieldValue.serverTimestamp(),
        'step_${stepIndex}_approvalRequested': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    revision.value++;
  }

  /// Collaborator notifies the primary owner that a step is ready for review.
  static Future<void> requestStepApproval({
    required String? companyId,
    required int stepIndex,
  }) async {
    if (!catalystStepRequiresApproval(stepIndex)) return;
    if (companyId == null || companyId.isEmpty) return;

    if (skipFirebasePersistence) {
      CompanyCollaborationSessionCache.requestStepApproval(stepIndex);
      revision.value++;
      return;
    }

    final isOwner = await CompanyMembershipService.isCurrentUserOwner(companyId);
    if (isOwner) {
      throw StateError(
        'Primary owners approve steps directly — use Approve instead.',
      );
    }

    if (stepIndex < 0 || stepIndex >= catalystPlanningSteps.length) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('planProgress')
        .doc('summary')
        .set(
      {
        'step_${stepIndex}_approvalRequested': true,
        'step_${stepIndex}_approvalRequestedBy': uid,
        'step_${stepIndex}_approvalRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    revision.value++;
  }

  static bool _hasText(dynamic value) =>
      value != null && value.toString().trim().isNotEmpty;

  static bool _hasNumericTarget(dynamic value) {
    if (value == null) return false;
    final n = double.tryParse(value.toString().replaceAll(',', ''));
    return n != null && n > 0;
  }

  static bool _hasSwotData(Map<String, dynamic> swot) {
    for (final key in ['strengths', 'weaknesses', 'opportunities', 'threats']) {
      final value = swot[key];
      if (value is List && value.any((e) => e.toString().trim().isNotEmpty)) {
        return true;
      }
      if (value is String && value.trim().isNotEmpty) return true;
    }
    return false;
  }

  static Future<void> cacheProgress(String companyId) async {
    final snapshot = await evaluate(companyId);
    _lastSnapshot = snapshot;
    revision.value++;
    if (skipFirebasePersistence) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('planProgress')
        .doc('summary')
        .set({
      'overallPercent': snapshot.overallPercent,
      'updatedAt': FieldValue.serverTimestamp(),
      for (final step in snapshot.steps) ...{
        'step_${step.stepIndex}_draftComplete': step.isDraftComplete,
        'step_${step.stepIndex}_complete': step.isDraftComplete,
      },
    }, SetOptions(merge: true));
  }
}
