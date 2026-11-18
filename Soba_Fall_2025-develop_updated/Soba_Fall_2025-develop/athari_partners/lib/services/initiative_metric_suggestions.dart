import 'dart:math' as math;

import '../strategic_area_catalog.dart';
import 'openai_service.dart';

class _KeywordMetricEntry {
  const _KeywordMetricEntry(this.keywords, this.metrics);

  final List<String> keywords;
  final List<String> metrics;
}

/// Default KPI names by strategic area (Step 3 catalog).
const Map<String, List<String>> kStrategicAreaDefaultMetrics = {
  'Revenue & Growth': [
    'Revenue growth %',
    'New customer count',
    'Sales win rate %',
    'Pipeline coverage ratio',
  ],
  'Customer & Stakeholder Experience': [
    'Customer satisfaction score',
    'Net Promoter Score',
    'Customer retention rate %',
    'Support response time (hrs)',
  ],
  'Brand, Marketing & Communications': [
    'Marketing qualified leads',
    'Brand awareness %',
    'Website conversion rate %',
    'Campaign ROI %',
  ],
  'Operations & Delivery Excellence': [
    'On-time delivery rate %',
    'Process cycle time (days)',
    'Defect / error rate %',
    'Capacity utilization %',
  ],
  'People, Culture & Leadership': [
    'Employee engagement score',
    'Voluntary turnover rate %',
    'Time to fill open roles (days)',
    'Training hours per employee',
  ],
  'Innovation & Product/Program Development': [
    'New features / releases shipped',
    'Time to market (weeks)',
    'R&D spend as % of revenue',
    'Active pilots in market',
  ],
  'Technology & Digital Enablement': [
    'System uptime %',
    'Automation hours saved',
    'Digital adoption rate %',
    'IT project on-time delivery %',
  ],
  'Financial Performance & Capital Stewardship': [
    'Gross margin %',
    'EBITDA margin %',
    'Operating cash flow',
    'Budget variance %',
  ],
  'Partnerships, Fundraising & Ecosystem': [
    'Partnership revenue %',
    'Funds raised (\$)',
    'Active strategic partners',
    'Grant approval rate %',
  ],
  'Risk, Compliance & Governance': [
    'Open compliance issues',
    'Audit findings closed %',
    'Policy training completion %',
    'Incident count',
  ],
  'Market & Competitive Positioning': [
    'Market share %',
    'Competitive win rate %',
    'Share of voice %',
    'New market entries',
  ],
  'Supply Chain & Vendor Excellence': [
    'Supplier on-time delivery %',
    'Inventory turnover',
    'Vendor quality score',
    'Procurement cost savings %',
  ],
};

const List<_KeywordMetricEntry> _keywordMetrics = [
  _KeywordMetricEntry(
    ['revenue', 'sales', 'pricing', 'pipeline', 'bookings'],
    ['Revenue growth %', 'New bookings (\$)', 'Average deal size'],
  ),
  _KeywordMetricEntry(
    ['customer', 'retention', 'churn', 'nps', 'satisfaction'],
    ['Customer retention rate %', 'Net Promoter Score', 'Churn rate %'],
  ),
  _KeywordMetricEntry(
    ['marketing', 'brand', 'campaign', 'awareness', 'lead'],
    ['Marketing qualified leads', 'Cost per lead', 'Campaign conversion %'],
  ),
  _KeywordMetricEntry(
    ['hire', 'recruit', 'talent', 'onboard', 'employee'],
    ['Time to fill (days)', 'Offer acceptance rate %', 'New hires count'],
  ),
  _KeywordMetricEntry(
    ['launch', 'product', 'feature', 'release', 'innovation'],
    ['Features shipped', 'Time to market (weeks)', 'Active beta users'],
  ),
  _KeywordMetricEntry(
    ['technology', 'system', 'digital', 'automation', 'software'],
    ['System uptime %', 'Automation hours saved', 'User adoption rate %'],
  ),
  _KeywordMetricEntry(
    ['cost', 'margin', 'profit', 'ebitda', 'cash', 'budget'],
    ['Cost reduction %', 'Gross margin %', 'Budget variance %'],
  ),
  _KeywordMetricEntry(
    ['quality', 'defect', 'error', 'delivery', 'operations'],
    ['Defect rate %', 'On-time delivery %', 'First-pass yield %'],
  ),
  _KeywordMetricEntry(
    ['partner', 'fundraising', 'grant', 'donor', 'alliance'],
    ['Funds raised (\$)', 'Active partnerships', 'Grant win rate %'],
  ),
  _KeywordMetricEntry(
    ['risk', 'compliance', 'audit', 'security', 'governance'],
    ['Open audit findings', 'Compliance training %', 'Security incidents'],
  ),
  _KeywordMetricEntry(
    ['supplier', 'vendor', 'inventory', 'supply chain', 'procurement'],
    ['Supplier on-time %', 'Inventory days on hand', 'Procurement savings %'],
  ),
  _KeywordMetricEntry(
    ['training', 'culture', 'engagement', 'leadership'],
    ['Employee engagement score', 'Training completion %', 'Leadership bench strength'],
  ),
];

/// Suggests trackable KPI names for Year 1 dashboard initiatives.
class InitiativeMetricSuggestions {
  InitiativeMetricSuggestions._();

  static const maxSuggestions = 3;

  static List<String> suggest({
    required String area,
    required String goal,
    required String initiative,
  }) {
    final haystack = '${goal.toLowerCase()} ${initiative.toLowerCase()}';
    final scored = <String, double>{};

    void scoreMetric(String metric, double score) {
      scored[metric] = math.max(scored[metric] ?? 0, score);
    }

    for (final entry in _keywordMetrics) {
      for (final keyword in entry.keywords) {
        if (haystack.contains(keyword)) {
          for (var i = 0; i < entry.metrics.length; i++) {
            scoreMetric(entry.metrics[i], 2.5 + keyword.length / 25 - i * 0.15);
          }
        }
      }
    }

    final areaMetrics = kStrategicAreaDefaultMetrics[area] ??
        kStrategicAreaDefaultMetrics['Operations & Delivery Excellence']!;
    for (var i = 0; i < areaMetrics.length; i++) {
      scoreMetric(areaMetrics[i], 1.2 - i * 0.12);
    }

    for (final keyword in kStrategicAreaSuggestionKeywords[area] ?? const []) {
      if (haystack.contains(keyword)) {
        for (var i = 0; i < areaMetrics.length && i < 2; i++) {
          scoreMetric(areaMetrics[i], 1.6 - i * 0.1);
        }
      }
    }

    final ranked = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final results = <String>[];
    for (final entry in ranked) {
      if (!results.contains(entry.key)) {
        results.add(entry.key);
      }
      if (results.length >= maxSuggestions) break;
    }

    for (final metric in areaMetrics) {
      if (results.length >= maxSuggestions) break;
      if (!results.contains(metric)) results.add(metric);
    }

    return results.isEmpty ? [areaMetrics.first] : results;
  }

  static String primarySuggestion({
    required String area,
    required String goal,
    required String initiative,
  }) =>
      suggest(area: area, goal: goal, initiative: initiative).first;

  static Future<String?> suggestWithAi({
    required String area,
    required String goal,
    required String initiative,
  }) async {
    try {
      return await OpenAIService().generateInitiativeMetricSuggestion(
        area: area,
        goal: goal,
        initiative: initiative,
      );
    } catch (_) {
      return null;
    }
  }
}
