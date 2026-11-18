import 'package:flutter/material.dart';

class StrategicArea {
  final String title;
  final String description;
  final IconData icon;

  const StrategicArea({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Outcome-oriented strategic pillars for Step 3 → Step 4 goal organization.
const List<StrategicArea> kStrategicAreaCatalog = [
  StrategicArea(
    title: 'Revenue & Growth',
    description:
        'Expand revenue, market share, and sustainable growth through pricing, new markets, products/services, and sales effectiveness.',
    icon: Icons.trending_up_outlined,
  ),
  StrategicArea(
    title: 'Customer & Stakeholder Experience',
    description:
        'Deepen satisfaction, retention, and lifetime value by improving how you serve and engage customers or stakeholders.',
    icon: Icons.favorite_border_outlined,
  ),
  StrategicArea(
    title: 'Brand, Marketing & Communications',
    description:
        'Strengthen positioning, awareness, and demand generation so the right audiences understand and choose you.',
    icon: Icons.campaign_outlined,
  ),
  StrategicArea(
    title: 'Operations & Delivery Excellence',
    description:
        'Improve how work gets done—quality, speed, cost, scalability, and reliability of core delivery.',
    icon: Icons.precision_manufacturing_outlined,
  ),
  StrategicArea(
    title: 'People, Culture & Leadership',
    description:
        'Build the talent, culture, and leadership capability required to execute strategy.',
    icon: Icons.groups_outlined,
  ),
  StrategicArea(
    title: 'Innovation & Product/Program Development',
    description:
        'Create or improve offerings that meet evolving market or mission needs.',
    icon: Icons.lightbulb_outline,
  ),
  StrategicArea(
    title: 'Technology & Digital Enablement',
    description:
        'Use systems, data, and automation to improve decision-making, productivity, and competitive advantage.',
    icon: Icons.computer_outlined,
  ),
  StrategicArea(
    title: 'Financial Performance & Capital Stewardship',
    description:
        'Strengthen profitability, cash flow, unit economics, and disciplined investment allocation.',
    icon: Icons.account_balance_outlined,
  ),
  StrategicArea(
    title: 'Partnerships, Fundraising & Ecosystem',
    description:
        'Grow reach and resources through alliances, channels, donors, grants, or community partnerships.',
    icon: Icons.handshake_outlined,
  ),
  StrategicArea(
    title: 'Risk, Compliance & Governance',
    description:
        'Protect the organization through regulatory compliance, legal readiness, and operational resilience.',
    icon: Icons.shield_outlined,
  ),
  StrategicArea(
    title: 'Market & Competitive Positioning',
    description:
        'Clarify where you compete, how you differentiate, and which segments or geographies to prioritize.',
    icon: Icons.leaderboard_outlined,
  ),
  StrategicArea(
    title: 'Supply Chain & Vendor Excellence',
    description:
        'Strengthen sourcing, suppliers, inventory, and vendor relationships to support delivery, quality, and margin.',
    icon: Icons.local_shipping_outlined,
  ),
];

/// Keywords used to lightly suggest areas from Step 2 assessment text.
const Map<String, List<String>> kStrategicAreaSuggestionKeywords = {
  'Revenue & Growth': [
    'revenue',
    'growth',
    'sales',
    'market share',
    'pricing',
    'pipeline',
    'acquisition',
    'expand',
  ],
  'Customer & Stakeholder Experience': [
    'customer',
    'stakeholder',
    'retention',
    'churn',
    'nps',
    'satisfaction',
    'service',
    'experience',
    'support',
  ],
  'Brand, Marketing & Communications': [
    'brand',
    'marketing',
    'awareness',
    'communication',
    'positioning',
    'campaign',
    'reputation',
  ],
  'Operations & Delivery Excellence': [
    'operation',
    'efficiency',
    'quality',
    'delivery',
    'supply chain',
    'process',
    'throughput',
    'production',
    'logistics',
  ],
  'People, Culture & Leadership': [
    'talent',
    'people',
    'culture',
    'leadership',
    'employee',
    'hiring',
    'retention',
    'engagement',
    'workforce',
    'hr',
  ],
  'Innovation & Product/Program Development': [
    'innovation',
    'product',
    'program',
    'r&d',
    'development',
    'new offering',
    'research',
  ],
  'Technology & Digital Enablement': [
    'technology',
    'digital',
    'automation',
    'data',
    'system',
    'software',
    'ai',
    'cyber',
    'it',
  ],
  'Financial Performance & Capital Stewardship': [
    'financial',
    'finance',
    'margin',
    'ebitda',
    'cash',
    'profit',
    'cost',
    'budget',
    'capital',
  ],
  'Partnerships, Fundraising & Ecosystem': [
    'partnership',
    'fundraising',
    'donor',
    'grant',
    'alliance',
    'ecosystem',
    'collaboration',
    'channel',
  ],
  'Risk, Compliance & Governance': [
    'risk',
    'compliance',
    'legal',
    'regulatory',
    'governance',
    'audit',
    'security',
  ],
  'Market & Competitive Positioning': [
    'competitive',
    'competitor',
    'positioning',
    'differentiation',
    'market entry',
    'segment',
    'geography',
    'niche',
    'market share',
  ],
  'Supply Chain & Vendor Excellence': [
    'supply chain',
    'vendor',
    'supplier',
    'procurement',
    'inventory',
    'sourcing',
    'logistics',
    'distribution',
    'purchasing',
  ],
};

Set<String> catalogStrategicAreaTitles() =>
    kStrategicAreaCatalog.map((a) => a.title).toSet();
