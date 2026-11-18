import 'package:athari_partners/auth_config.dart';
import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/index_screen.dart';
import 'package:athari_partners/signup_page.dart';
import 'package:flutter/material.dart';

/// Full-screen detail for one Catalyst Planning process step.
class CatalystPlanningStepDetailPage extends StatelessWidget {
  const CatalystPlanningStepDetailPage({
    super.key,
    required this.stepIndex,
  }) : assert(stepIndex >= 0 && stepIndex < catalystPlanningStepCount);

  final int stepIndex;

  static Route<void> route(int stepIndex) {
    return MaterialPageRoute<void>(
      builder: (context) => CatalystPlanningStepDetailPage(stepIndex: stepIndex),
    );
  }

  static const _accent = Color(0xFF2E7D32);
  static const _accentDeep = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final step = catalystPlanningSteps[stepIndex];
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.grey.shade900,
        title: null,
        leading: const BackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: const Color(0xFFE8F5E9),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 48,
                0,
                isMobile ? 20 : 48,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_accent, _accentDeep],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'STEP ${catalystDisplayStepNumber(stepIndex)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 30,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 48,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.detail,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 17,
                          height: 1.65,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Ready to build this in MyCatalystPlan?',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (authBypassEnabled) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute<void>(
                                    builder: (context) => const IndexScreen(),
                                  ),
                                  (route) => false,
                                );
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (context) => SignupPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Get started for Free',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (authBypassEnabled) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute<void>(
                                    builder: (context) => const IndexScreen(),
                                  ),
                                  (route) => false,
                                );
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      const SignupPage(joinExistingCompany: true),
                                ),
                              );
                            },
                            child: const Text('Join your team with an invite code'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back to overview'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 0 — Company Profile
class CompanyProfileDetailPage extends StatelessWidget {
  const CompanyProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CatalystPlanningStepDetailPage(stepIndex: 0);
}

/// Step 1 — Refine Company Identity
class RefineCompanyIdentityPage extends StatelessWidget {
  const RefineCompanyIdentityPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CatalystPlanningStepDetailPage(stepIndex: 1);
}

/// Step 2 — Identify Strategic Gaps & Opportunities
class IdentifyStrategicGapsPage extends StatelessWidget {
  const IdentifyStrategicGapsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CatalystPlanningStepDetailPage(stepIndex: 2);
}

/// Step 3 — Set 3-Year Strategic Objectives
class SetThreeYearObjectivesPage extends StatelessWidget {
  const SetThreeYearObjectivesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CatalystPlanningStepDetailPage(stepIndex: 3);
}

/// Step 4 — Define Year 1 Strategic Plan
class DefineYearOneStrategicPlanPage extends StatelessWidget {
  const DefineYearOneStrategicPlanPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CatalystPlanningStepDetailPage(stepIndex: 4);
}

/// Step 5 — Execute Plan & Monitor Performance
class ExecuteAndMonitorPlanPage extends StatelessWidget {
  const ExecuteAndMonitorPlanPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CatalystPlanningStepDetailPage(stepIndex: 5);
}
