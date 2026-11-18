import 'package:flutter/material.dart';

import '../strategic_area_catalog.dart';

/// Infographic icon set matching the strategic one-pager reference graphic.
enum StrategicAreaIconStyle {
  customer,
  sales,
  marketing,
  operations,
  technology,
  people,
  innovation,
  financial,
  risk,
  generic,
}

/// Header, body tint, and icon style for a strategic focus area column.
class StrategicAreaVisualTheme {
  const StrategicAreaVisualTheme({
    required this.headerColor,
    required this.bodyColor,
    required this.iconStyle,
    this.fallbackIcon = Icons.flag_outlined,
  });

  final Color headerColor;
  final Color bodyColor;
  final StrategicAreaIconStyle iconStyle;
  final IconData fallbackIcon;
}

/// Large circular icon badge (white fill, colored border) for one-pager columns.
class StrategicAreaIconBadge extends StatelessWidget {
  const StrategicAreaIconBadge({
    super.key,
    required this.theme,
    this.size = 76,
  });

  final StrategicAreaVisualTheme theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: theme.headerColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: theme.headerColor.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: _InfographicIcon(theme: theme, size: size)),
    );
  }
}

class _InfographicIcon extends StatelessWidget {
  const _InfographicIcon({required this.theme, required this.size});

  final StrategicAreaVisualTheme theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = theme.headerColor;
    switch (theme.iconStyle) {
      case StrategicAreaIconStyle.customer:
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.groups_rounded, size: size * 0.44, color: color),
            Positioned(
              right: size * 0.14,
              bottom: size * 0.12,
              child: Icon(Icons.search_rounded, size: size * 0.26, color: color),
            ),
          ],
        );
      case StrategicAreaIconStyle.sales:
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.bar_chart_rounded, size: size * 0.46, color: color),
            Positioned(
              right: size * 0.1,
              top: size * 0.08,
              child: Icon(Icons.north_east_rounded, size: size * 0.28, color: color),
            ),
          ],
        );
      case StrategicAreaIconStyle.marketing:
        return Icon(Icons.campaign_rounded, size: size * 0.48, color: color);
      case StrategicAreaIconStyle.operations:
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.map_rounded, size: size * 0.42, color: color),
            Positioned(
              right: size * 0.12,
              bottom: size * 0.1,
              child: Icon(Icons.edit_rounded, size: size * 0.22, color: color),
            ),
          ],
        );
      case StrategicAreaIconStyle.technology:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.settings_rounded, size: size * 0.44, color: color),
            Icon(Icons.memory_rounded, size: size * 0.24, color: color),
          ],
        );
      case StrategicAreaIconStyle.people:
        return Icon(Icons.groups_outlined, size: size * 0.46, color: color);
      case StrategicAreaIconStyle.innovation:
        return Icon(Icons.lightbulb_rounded, size: size * 0.46, color: color);
      case StrategicAreaIconStyle.financial:
        return Icon(Icons.account_balance_rounded, size: size * 0.44, color: color);
      case StrategicAreaIconStyle.risk:
        return Icon(Icons.shield_rounded, size: size * 0.44, color: color);
      case StrategicAreaIconStyle.generic:
        return Icon(theme.fallbackIcon, size: size * 0.44, color: color);
    }
  }
}

StrategicAreaVisualTheme strategicAreaVisualTheme(String areaTitle) {
  for (final area in kStrategicAreaCatalog) {
    if (area.title == areaTitle) {
      return _themeForCatalogTitle(area.title, area.icon);
    }
  }

  final lower = areaTitle.trim().toLowerCase();
  if (lower.contains('customer') || lower.contains('stakeholder')) {
    return _customerTheme();
  }
  if (lower == 'sales' ||
      lower.contains('revenue') ||
      lower.contains('growth')) {
    return _revenueTheme();
  }
  if (lower.contains('marketing') ||
      lower.contains('brand') ||
      lower.contains('communication')) {
    return _marketingTheme();
  }
  if (lower.contains('operation') ||
      lower.contains('delivery') ||
      lower.contains('production')) {
    return _operationsTheme();
  }
  if (lower.contains('technology') ||
      lower.contains('digital') ||
      lower.contains(' it')) {
    return _technologyTheme();
  }
  if (lower.contains('people') ||
      lower.contains('culture') ||
      lower.contains('leadership') ||
      lower.contains('talent')) {
    return _peopleTheme();
  }
  if (lower.contains('innovation') || lower.contains('product')) {
    return _innovationTheme();
  }
  if (lower.contains('financial') ||
      lower.contains('finance') ||
      lower.contains('capital')) {
    return _financialTheme();
  }
  if (lower.contains('risk') ||
      lower.contains('compliance') ||
      lower.contains('governance')) {
    return _riskTheme();
  }

  final hash = areaTitle.hashCode.abs();
  const fallbacks = [
    _customerTheme,
    _revenueTheme,
    _marketingTheme,
    _operationsTheme,
    _technologyTheme,
    _peopleTheme,
    _innovationTheme,
    _financialTheme,
  ];
  return fallbacks[hash % fallbacks.length]();
}

StrategicAreaVisualTheme _themeForCatalogTitle(String title, IconData icon) {
  return switch (title) {
    'Revenue & Growth' => _revenueTheme(),
    'Customer & Stakeholder Experience' => _customerTheme(),
    'Brand, Marketing & Communications' => _marketingTheme(),
    'Operations & Delivery Excellence' => _operationsTheme(),
    'People, Culture & Leadership' => _peopleTheme(),
    'Innovation & Product/Program Development' => _innovationTheme(),
    'Technology & Digital Enablement' => _technologyTheme(),
    'Financial Performance & Capital Stewardship' => _financialTheme(),
    'Partnerships, Fundraising & Ecosystem' => StrategicAreaVisualTheme(
        headerColor: const Color(0xFF4338CA),
        bodyColor: const Color(0xFFE0E7FF),
        iconStyle: StrategicAreaIconStyle.generic,
        fallbackIcon: icon,
      ),
    'Risk, Compliance & Governance' => _riskTheme(),
    'Market & Competitive Positioning' => StrategicAreaVisualTheme(
        headerColor: const Color(0xFF0891B2),
        bodyColor: const Color(0xFFCFFAFE),
        iconStyle: StrategicAreaIconStyle.generic,
        fallbackIcon: icon,
      ),
    'Supply Chain & Vendor Excellence' => StrategicAreaVisualTheme(
        headerColor: const Color(0xFFD97706),
        bodyColor: const Color(0xFFFFEDD5),
        iconStyle: StrategicAreaIconStyle.generic,
        fallbackIcon: icon,
      ),
    _ => StrategicAreaVisualTheme(
        headerColor: const Color(0xFF475569),
        bodyColor: const Color(0xFFF1F5F9),
        iconStyle: StrategicAreaIconStyle.generic,
        fallbackIcon: icon,
      ),
  };
}

StrategicAreaVisualTheme _customerTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFFB91C1C),
      bodyColor: Color(0xFFFEE2E2),
      iconStyle: StrategicAreaIconStyle.customer,
    );

StrategicAreaVisualTheme _revenueTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFFCA8A04),
      bodyColor: Color(0xFFFEF9C3),
      iconStyle: StrategicAreaIconStyle.sales,
    );

StrategicAreaVisualTheme _marketingTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFF2563EB),
      bodyColor: Color(0xFFDBEAFE),
      iconStyle: StrategicAreaIconStyle.marketing,
    );

StrategicAreaVisualTheme _operationsTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFF15803D),
      bodyColor: Color(0xFFDCFCE7),
      iconStyle: StrategicAreaIconStyle.operations,
    );

StrategicAreaVisualTheme _technologyTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFF7C3AED),
      bodyColor: Color(0xFFEDE9FE),
      iconStyle: StrategicAreaIconStyle.technology,
    );

StrategicAreaVisualTheme _peopleTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFF0D9488),
      bodyColor: Color(0xFFCCFBF1),
      iconStyle: StrategicAreaIconStyle.people,
    );

StrategicAreaVisualTheme _innovationTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFFEA580C),
      bodyColor: Color(0xFFFFEDD5),
      iconStyle: StrategicAreaIconStyle.innovation,
    );

StrategicAreaVisualTheme _financialTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFF047857),
      bodyColor: Color(0xFFD1FAE5),
      iconStyle: StrategicAreaIconStyle.financial,
    );

StrategicAreaVisualTheme _riskTheme() => const StrategicAreaVisualTheme(
      headerColor: Color(0xFF475569),
      bodyColor: Color(0xFFF1F5F9),
      iconStyle: StrategicAreaIconStyle.risk,
    );
