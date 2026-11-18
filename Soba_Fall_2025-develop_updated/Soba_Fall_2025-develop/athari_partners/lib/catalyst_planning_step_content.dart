/// Shared titles and long-form copy for each Catalyst Planning process step.
/// Used by the landing page, navigation, and step detail screens.
class CatalystPlanningStep {
  const CatalystPlanningStep({
    required this.title,
    required this.shortTitle,
    required this.detail,
  });

  /// Full title used on step pages and marketing.
  final String title;

  /// Compact label for the main app bar chips (steps 2 vs 3 stay distinct).
  final String shortTitle;

  final String detail;
}

const List<CatalystPlanningStep> catalystPlanningSteps = [
  CatalystPlanningStep(
    title: 'Company Profile',
    shortTitle: 'Profile',
    detail:
        'Establish your organization foundation: company name, logo, industry, size, and headquarters. '
        'This workspace identity appears on your strategic plan outputs and keeps planning aligned to the right entity.',
  ),
  CatalystPlanningStep(
    title: 'Refine Company Identity',
    shortTitle: 'Identity',
    detail:
        'Anchor the plan in who you are: mission, vision, values, and market positioning. MyCatalystPlan gives you structured fields so leadership agrees on identity before debating initiatives—reducing rework later.',
  ),
  CatalystPlanningStep(
    title: 'Identify Strategic Gaps & Opportunities',
    shortTitle: 'Assessment',
    detail:
        'Pressure-test context with SWOT-style analysis (strengths, weaknesses, opportunities, threats), competitive dynamics, and market shifts. Surface where you are exposed, where advantage is durable, and which gaps the plan must close.',
  ),
  CatalystPlanningStep(
    title: 'Set 3-Year Strategic Objectives',
    shortTitle: '3-Year targets',
    detail:
        'Define measurable multi-year outcomes—revenue, margin, EBITDA, cash, and capability targets—so financial and operating goals align. Tie objectives to dashboards leadership reviews on a regular cadence.',
  ),
  CatalystPlanningStep(
    title: 'Define Year 1 Strategic Plan',
    shortTitle: 'Year 1 plan',
    detail:
        'Translate 3-year intent into a concrete 12-month path: prioritized initiatives, budgets, owners, and dependencies. Bridge long-range ambition with what teams will actually fund and ship this year.',
  ),
  CatalystPlanningStep(
    title: 'Execute Plan & Monitor Performance',
    shortTitle: 'Execute',
    detail:
        'Operationalize the Catalyst Plan with KPIs, milestones, review rhythms, and monitoring views so execution is visible—not a static document. Adjust when performance or markets demand it.',
  ),
];

/// Compile-time step count for const constructor asserts (keep in sync with [catalystPlanningSteps]).
/// Step 0 = Company Profile; Steps 1–5 = the five-step strategic plan.
const int catalystPlanningStepCount = 6;

/// Number of steps in the strategic plan (excludes Step 0 profile).
const int catalystStrategicPlanStepCount = 5;

/// User-facing step number: Profile = 0, strategic plan = 1–5.
int catalystDisplayStepNumber(int stepIndex) => stepIndex;

/// App bar / nav label, e.g. `#0 Profile`, `#3 3-Year targets`.
String catalystStepNavLabel(int stepIndex) {
  final meta = catalystPlanningSteps[stepIndex.clamp(
    0,
    catalystPlanningSteps.length - 1,
  )];
  return '#${catalystDisplayStepNumber(stepIndex)} ${meta.shortTitle}';
}

/// Whether [stepIndex] is part of the five-step strategic plan (not profile).
bool isStrategicPlanStep(int stepIndex) =>
    stepIndex >= 1 && stepIndex < catalystPlanningStepCount;

/// Step 5 stays open for ongoing cascade and KPI updates — no owner approval gate.
bool catalystStepRequiresApproval(int stepIndex) => stepIndex != 5;
