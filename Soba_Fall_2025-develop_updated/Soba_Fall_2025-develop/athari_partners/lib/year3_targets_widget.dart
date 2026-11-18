import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_config.dart';
import 'services/plan_progress_service.dart';
import 'services/year3_targets_session_cache.dart';
import 'utils/currency_input.dart';
import 'utils/debounced_auto_save.dart';

enum _FinancialField { revenue, grossMargin, ebitda, ebitdaMargin }

class _YearFinancialControllers {
  _YearFinancialControllers({
    required this.revenue,
    required this.grossMargin,
    required this.ebitda,
    required this.ebitdaMargin,
  });

  final TextEditingController revenue;
  final TextEditingController grossMargin;
  final TextEditingController ebitda;
  final TextEditingController ebitdaMargin;
}

class Year3TargetsWidget extends StatefulWidget {
  final Function(Map<String, double>)? onSave;

  const Year3TargetsWidget({Key? key, this.onSave}) : super(key: key);

  @override
  State<Year3TargetsWidget> createState() => _Year3TargetsWidgetState();
}

class _Year3TargetsWidgetState extends State<Year3TargetsWidget> {
  late final _YearFinancialControllers _year3 = _YearFinancialControllers(
    revenue: TextEditingController(),
    grossMargin: TextEditingController(),
    ebitda: TextEditingController(),
    ebitdaMargin: TextEditingController(),
  );
  late final _YearFinancialControllers _year1 = _YearFinancialControllers(
    revenue: TextEditingController(),
    grossMargin: TextEditingController(),
    ebitda: TextEditingController(),
    ebitdaMargin: TextEditingController(),
  );
  late final _YearFinancialControllers _year2 = _YearFinancialControllers(
    revenue: TextEditingController(),
    grossMargin: TextEditingController(),
    ebitda: TextEditingController(),
    ebitdaMargin: TextEditingController(),
  );

  String? _companyId;
  bool _syncing = false;

  final DebouncedAutoSave _autoSave = DebouncedAutoSave();
  AutoSaveState _saveState = AutoSaveState.idle;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    for (final group in [_year3, _year1, _year2]) {
      for (final c in [
        group.revenue,
        group.grossMargin,
        group.ebitda,
        group.ebitdaMargin,
      ]) {
        c.addListener(_scheduleAutoSave);
      }
    }
    _loadCompanyId();
  }

  void _scheduleAutoSave() {
    if (_syncing) return;
    _autoSave.schedule(
      _saveYear3TargetsSilent,
      () {
        if (mounted) {
          setState(() {
            _saveState = _autoSave.state;
            _saveError = _autoSave.errorMessage;
          });
        }
      },
    );
  }

  Future<void> _saveYear3TargetsSilent() async {
    await _saveYear3Targets();
    if (_companyId != null && !skipFirebasePersistence) {
      await PlanProgressService.cacheProgress(_companyId!);
    }
  }

  Future<void> _loadCompanyId() async {
    try {
      _companyId = await loadCompanyIdForCurrentUser();
      if (skipFirebasePersistence) {
        _applyLoadedData({
          'y3R': Year3TargetsSessionCache.y3Revenue,
          'y3G': Year3TargetsSessionCache.y3GrossMargin,
          'y3E': Year3TargetsSessionCache.y3Ebitda,
          'y3M': Year3TargetsSessionCache.y3Margin,
          'y1R': Year3TargetsSessionCache.y1Revenue,
          'y1G': Year3TargetsSessionCache.y1GrossMargin,
          'y1E': Year3TargetsSessionCache.y1Ebitda,
          'y1M': Year3TargetsSessionCache.y1Margin,
          'y2R': Year3TargetsSessionCache.y2Revenue,
          'y2G': Year3TargetsSessionCache.y2GrossMargin,
          'y2E': Year3TargetsSessionCache.y2Ebitda,
          'y2M': Year3TargetsSessionCache.y2Margin,
        });
      } else if (_companyId != null) {
        await _loadYear3Targets();
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.text = text;
  }

  void _applyLoadedData(Map<String, dynamic> data) {
    _syncing = true;
    try {
      _setLoadedFinancials(
        _year3,
        data['y3R'],
        data['y3G'],
        data['y3E'],
        data['y3M'],
      );
      _setLoadedFinancials(
        _year1,
        data['y1R'],
        data['y1G'],
        data['y1E'],
        data['y1M'],
      );
      _setLoadedFinancials(
        _year2,
        data['y2R'],
        data['y2G'],
        data['y2E'],
        data['y2M'],
      );
    } finally {
      _syncing = false;
    }
  }

  void _setLoadedFinancials(
    _YearFinancialControllers group,
    dynamic revenueRaw,
    dynamic grossMarginRaw,
    dynamic ebitdaRaw,
    dynamic ebitdaMarginRaw,
  ) {
    final revenue = parseCurrency(revenueRaw?.toString());
    final ebitda = parseCurrency(ebitdaRaw?.toString());
    final grossMargin = parsePercent(grossMarginRaw?.toString());
    final ebitdaMargin = parsePercent(ebitdaMarginRaw?.toString());

    _setControllerText(
      group.revenue,
      revenue != null && revenue > 0 ? formatCurrencyDisplay(revenue) : '',
    );
    _setControllerText(
      group.grossMargin,
      grossMargin != null && grossMargin > 0
          ? formatPercentDisplay(grossMargin)
          : '',
    );
    _setControllerText(
      group.ebitda,
      ebitda != null && ebitda > 0 ? formatCurrencyDisplay(ebitda) : '',
    );

    if (ebitdaMargin != null && ebitdaMargin > 0) {
      _setControllerText(group.ebitdaMargin, formatPercentDisplay(ebitdaMargin));
    } else if (revenue != null && revenue > 0 && ebitda != null && ebitda > 0) {
      _setControllerText(
        group.ebitdaMargin,
        formatPercentDisplay((ebitda / revenue) * 100),
      );
    } else {
      _setControllerText(group.ebitdaMargin, '');
    }
  }

  Future<void> _loadYear3Targets() async {
    if (_companyId == null) return;
    final year3Ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('year3_targets');
    final year3Snapshot = await year3Ref.get();
    if (year3Snapshot.exists && year3Snapshot.data() != null) {
      _applyLoadedData(year3Snapshot.data()!);
    }
  }

  Map<String, String> _collectSavePayload() => {
        'y1R': _year1.revenue.text,
        'y1G': _year1.grossMargin.text,
        'y1E': _year1.ebitda.text,
        'y1M': _year1.ebitdaMargin.text,
        'y2R': _year2.revenue.text,
        'y2G': _year2.grossMargin.text,
        'y2E': _year2.ebitda.text,
        'y2M': _year2.ebitdaMargin.text,
        'y3R': _year3.revenue.text,
        'y3G': _year3.grossMargin.text,
        'y3E': _year3.ebitda.text,
        'y3M': _year3.ebitdaMargin.text,
      };

  Future<void> _saveYear3Targets() async {
    if (_companyId == null) return;
    final payload = _collectSavePayload();
    if (skipFirebasePersistence) {
      Year3TargetsSessionCache.update(
        y3Revenue: payload['y3R'],
        y3GrossMargin: payload['y3G'],
        y3Ebitda: payload['y3E'],
        y3Margin: payload['y3M'],
        y1Revenue: payload['y1R'],
        y1GrossMargin: payload['y1G'],
        y1Ebitda: payload['y1E'],
        y1Margin: payload['y1M'],
        y2Revenue: payload['y2R'],
        y2GrossMargin: payload['y2G'],
        y2Ebitda: payload['y2E'],
        y2Margin: payload['y2M'],
      );
      return;
    }
    final year3Ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('year3_targets');
    await year3Ref.set(payload, SetOptions(merge: true));
  }

  void _onFinancialFieldChanged(
    _YearFinancialControllers group,
    _FinancialField source,
  ) {
    if (_syncing) return;

    _syncing = true;
    try {
      final revenue = parseCurrency(group.revenue.text);
      final ebitda = parseCurrency(group.ebitda.text);
      final ebitdaMargin = parsePercent(group.ebitdaMargin.text);

      switch (source) {
        case _FinancialField.revenue:
        case _FinancialField.grossMargin:
          if (revenue != null && revenue > 0) {
            if (ebitdaMargin != null && ebitdaMargin > 0) {
              _setControllerText(
                group.ebitda,
                formatCurrencyDisplay(revenue * ebitdaMargin / 100),
              );
            } else if (ebitda != null && ebitda > 0) {
              _setControllerText(
                group.ebitdaMargin,
                formatPercentDisplay((ebitda / revenue) * 100),
              );
            }
          }
          break;
        case _FinancialField.ebitda:
          if (revenue != null && revenue > 0 && ebitda != null && ebitda >= 0) {
            _setControllerText(
              group.ebitdaMargin,
              formatPercentDisplay((ebitda / revenue) * 100),
            );
          }
          break;
        case _FinancialField.ebitdaMargin:
          if (revenue != null &&
              revenue > 0 &&
              ebitdaMargin != null &&
              ebitdaMargin >= 0) {
            _setControllerText(
              group.ebitda,
              formatCurrencyDisplay(revenue * ebitdaMargin / 100),
            );
          }
          break;
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    for (final group in [_year3, _year1, _year2]) {
      group.revenue.dispose();
      group.grossMargin.dispose();
      group.ebitda.dispose();
      group.ebitdaMargin.dispose();
    }
    _autoSave.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndContinue() async {
    final targets = {
      'year3Revenue': parseCurrency(_year3.revenue.text) ?? 0.0,
      'year3Ebitda': parseCurrency(_year3.ebitda.text) ?? 0.0,
      'year1Revenue': parseCurrency(_year1.revenue.text) ?? 0.0,
      'year1Ebitda': parseCurrency(_year1.ebitda.text) ?? 0.0,
      'year2Revenue': parseCurrency(_year2.revenue.text) ?? 0.0,
      'year2Ebitda': parseCurrency(_year2.ebitda.text) ?? 0.0,
    };

    await _saveYear3Targets();
    widget.onSave?.call(targets);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Establish Year 3 Targets & Milestones',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenue and EBITDA auto-format with commas. Enter gross margin % and '
            'EBITDA margin % as needed. EBITDA \$ and EBITDA % sync when revenue is set.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Financial Targets',
            child: _buildYearFinancialRow(
              yearLabel: 'Year 3',
              group: _year3,
            ),
          ),
          const SizedBox(height: 24),
          _sectionCard(
            title: 'Milestone Targets',
            titleIcon: Icons.trending_up,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildYearFinancialRow(yearLabel: 'Year 1', group: _year1),
                const SizedBox(height: 24),
                _buildYearFinancialRow(yearLabel: 'Year 2', group: _year2),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSaveStatusChip(
                  state: _saveState,
                  errorMessage: _saveError,
                ),
                if (_saveState != AutoSaveState.idle) const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleSaveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B7BEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? titleIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 20, color: const Color(0xFF4B7BEC)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildYearFinancialRow({
    required String yearLabel,
    required _YearFinancialControllers group,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1020;
        final fields = [
          _buildCurrencyField(
            icon: Icons.attach_money,
            iconColor: const Color(0xFF4B7BEC),
            label: '$yearLabel Revenue Target',
            controller: group.revenue,
            onChanged: () =>
                _onFinancialFieldChanged(group, _FinancialField.revenue),
          ),
          _buildPercentField(
            icon: Icons.pie_chart_outline,
            iconColor: const Color(0xFF0EA5E9),
            label: '$yearLabel Gross Margin',
            controller: group.grossMargin,
            onChanged: () =>
                _onFinancialFieldChanged(group, _FinancialField.grossMargin),
          ),
          _buildCurrencyField(
            icon: Icons.show_chart,
            iconColor: const Color(0xFF26C281),
            label: '$yearLabel EBITDA Target',
            controller: group.ebitda,
            onChanged: () =>
                _onFinancialFieldChanged(group, _FinancialField.ebitda),
          ),
          _buildPercentField(
            icon: Icons.percent,
            iconColor: const Color(0xFF7C3AED),
            label: '$yearLabel EBITDA Margin',
            controller: group.ebitdaMargin,
            onChanged: () =>
                _onFinancialFieldChanged(group, _FinancialField.ebitdaMargin),
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: fields[i]),
              ],
            ],
          );
        }

        final isMedium = constraints.maxWidth > 520;
        if (isMedium) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 16),
                  Expanded(child: fields[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[2]),
                  const SizedBox(width: 16),
                  Expanded(child: fields[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              fields[i],
            ],
          ],
        );
      },
    );
  }

  Widget _buildCurrencyField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '\$ ',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'USD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
          margin: const EdgeInsets.only(top: 8),
        ),
      ],
    );
  }

  Widget _buildPercentField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [PercentInputFormatter()],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '%',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
          margin: const EdgeInsets.only(top: 8),
        ),
      ],
    );
  }
}

class Year3TargetsScreen extends StatelessWidget {
  const Year3TargetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Year3TargetsWidget(
        onSave: (targets) {
          debugPrint('Saved targets: $targets');
        },
      ),
    );
  }
}
