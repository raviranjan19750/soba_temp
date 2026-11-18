import 'package:flutter/material.dart';

import '../services/kpi_dashboard_tracking.dart';

/// Spreadsheet-style Year 1 KPI tracking: plan columns + quarterly actuals + YTD.
class DashboardTrackingTable extends StatefulWidget {
  const DashboardTrackingTable({
    super.key,
    required this.groups,
    required this.currentYear,
    required this.activeQuarter,
    this.editable = false,
    this.controllers,
    this.statusValues,
    this.onStatusChanged,
    this.showStatus = false,
    this.onSuggestMetric,
    this.suggestingRowId,
  });

  final List<DashboardAreaGroup> groups;
  final int currentYear;
  final int activeQuarter;
  final bool editable;
  final Map<String, TextEditingController>? controllers;
  final Map<String, String>? statusValues;
  final void Function(String rowId, String status)? onStatusChanged;
  final bool showStatus;
  final void Function(DashboardTrackingRow row)? onSuggestMetric;
  final String? suggestingRowId;

  static const initiativeRowHeight = 56.0;

  static String controllerKey(DashboardTrackingRow row, String field) =>
      '${row.rowId}_$field';

  /// Height for the horizontal scroll viewport (avoids zero-height in page scroll).
  static double estimatedHeight(List<DashboardAreaGroup> groups) {
    const topHeaders = 68.0;
    const categoryBand = 34.0;
    var total = topHeaders;
    for (final group in groups) {
      total += categoryBand + (group.rows.length * initiativeRowHeight);
    }
    // Outer border (top + bottom) plus small buffer for web font metrics.
    return total + 6;
  }

  @override
  State<DashboardTrackingTable> createState() => _DashboardTrackingTableState();
}

class _DashboardTrackingTableState extends State<DashboardTrackingTable> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  static const _headerBg = Color(0xFF334155);
  static const _categoryBg = Color(0xFFF1F5F9);
  static const _planBg = Colors.white;
  static const _trackingBg = Color(0xFFEFF6FF);
  static const _activeQuarterBg = Color(0xFFDBEAFE);
  static const _borderColor = Color(0xFFCBD5E1);

  static const double _goalsWidth = 148;
  static const double _initiativeWidth = 268;
  static const double _measureWidth = 124;
  static const double _targetWidth = 76;
  static const double _ownerWidth = 84;
  static const double _statusWidth = 92;
  static const double _quarterWidth = 76;
  static const double _ytdWidth = 84;

  double get _planWidth =>
      _goalsWidth +
      _initiativeWidth +
      _ownerWidth +
      _measureWidth +
      (_targetWidth * 4) +
      (widget.showStatus ? _statusWidth : 0);

  double get _trackingWidth => (_quarterWidth * 4) + _ytdWidth;

  double get _minWidth => _planWidth + _trackingWidth;

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final tableHeight = DashboardTrackingTable.estimatedHeight(widget.groups);

    return SizedBox(
      height: tableHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _minWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sectionHeaderRow(),
                    _columnHeaderRow(),
                    for (final group in widget.groups) ...[
                      _categoryRow(group.area),
                      _areaBlock(group),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeaderRow() {
    return Row(
      children: [
        Container(
          width: _planWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: const BoxDecoration(
            color: _categoryBg,
            border: Border(
              bottom: BorderSide(color: _borderColor),
              right: BorderSide(color: _borderColor),
            ),
          ),
          child: const Text(
            'Year 1 — KPIs, targets & owners',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          width: _trackingWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: const BoxDecoration(
            color: Color(0xFFBFDBFE),
            border: Border(bottom: BorderSide(color: _borderColor)),
          ),
          child: Text(
            'Quarterly actuals — ${widget.currentYear}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _columnHeaderRow() {
    return Container(
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          _planHeader('Goals', _goalsWidth),
          _planHeader('Initiatives', _initiativeWidth),
          _planHeader('Owner', _ownerWidth),
          _planHeader('Measures', _measureWidth),
          for (var q = 1; q <= 4; q++)
            _planHeader(
              'Q$q target',
              _targetWidth,
              highlighted: q == widget.activeQuarter,
            ),
          if (widget.showStatus) _planHeader('Status', _statusWidth),
          for (var q = 1; q <= 4; q++)
            _trackingHeader(
              'Q$q',
              highlighted: q == widget.activeQuarter,
            ),
          _trackingHeader('YTD', highlighted: false, isLast: true),
        ],
      ),
    );
  }

  Widget _planHeader(String text, double width, {bool highlighted = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF475569) : _headerBg,
        border: const Border(right: BorderSide(color: Color(0xFF64748B))),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlighted ? const Color(0xFFFDE68A) : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _trackingHeader(
    String text, {
    required bool highlighted,
    bool isLast = false,
  }) {
    return Container(
      width: isLast ? _ytdWidth : _quarterWidth,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF64748B)),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _categoryRow(String area) {
    return Container(
      width: _minWidth,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: _categoryBg,
        border: Border(
          bottom: BorderSide(color: _borderColor),
          top: BorderSide(color: _borderColor),
        ),
      ),
      child: Text(
        area,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _areaBlock(DashboardAreaGroup group) {
    final blockHeight =
        group.rows.length * DashboardTrackingTable.initiativeRowHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _goalsWidth,
          height: blockHeight,
          child: _goalCell(group.goal),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in group.rows) _initiativeRow(row),
          ],
        ),
      ],
    );
  }

  Widget _goalCell(String goal) {
    return Container(
      width: _goalsWidth,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: _planBg,
        border: Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Center(
        child: Text(
          goal,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            height: 1.35,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _initiativeRow(DashboardTrackingRow row) {
    return SizedBox(
      height: DashboardTrackingTable.initiativeRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _planCell(
            width: _initiativeWidth,
            child: Text(
              '${row.initiativeIndex}. ${row.initiative}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.3),
            ),
          ),
          _planCell(
            width: _ownerWidth,
            child: _fieldOrText(row: row, field: 'owner', hint: 'Owner'),
          ),
          _planCell(
            width: _measureWidth,
            child: _measuresCell(row),
          ),
          for (var q = 1; q <= 4; q++)
            _planCell(
              width: _targetWidth,
              highlighted: q == widget.activeQuarter,
              child: _fieldOrText(
                row: row,
                field: 'q${q}Target',
                hint: 'Q$q target',
              ),
            ),
          if (widget.showStatus)
            _planCell(
              width: _statusWidth,
              child: _statusCell(row),
            ),
          for (var q = 1; q <= 4; q++)
            _trackingCell(
              highlighted: q == widget.activeQuarter,
              child: _fieldOrText(
                row: row,
                field: 'q$q',
                hint: 'Q$q actual',
              ),
            ),
          _trackingCell(
            isLast: true,
            child: _fieldOrText(row: row, field: 'fullYear', hint: 'YTD actual'),
          ),
        ],
      ),
    );
  }

  String _valueForField(DashboardTrackingRow row, String field) {
    switch (field) {
      case 'measures':
        return row.measures;
      case 'owner':
        return row.owner;
      case 'q1Target':
        return row.q1Target;
      case 'q2Target':
        return row.q2Target;
      case 'q3Target':
        return row.q3Target;
      case 'q4Target':
        return row.q4Target;
      case 'q1':
        return row.q1;
      case 'q2':
        return row.q2;
      case 'q3':
        return row.q3;
      case 'q4':
        return row.q4;
      case 'fullYear':
        return row.fullYear;
      default:
        return '';
    }
  }

  Widget _statusCell(DashboardTrackingRow row) {
    final status = widget.editable
        ? DashboardInitiativeStatus.normalize(widget.statusValues?[row.rowId])
        : DashboardInitiativeStatus.normalize(row.status);

    if (!widget.editable) return _statusBadge(status);

    return DropdownButtonFormField<String>(
      value: status,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      items: DashboardInitiativeStatus.options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option, style: const TextStyle(fontSize: 10)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) widget.onStatusChanged?.call(row.rowId, value);
      },
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case DashboardInitiativeStatus.onTrack:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case DashboardInitiativeStatus.atRisk:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case DashboardInitiativeStatus.behind:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case DashboardInitiativeStatus.complete:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case DashboardInitiativeStatus.na:
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF64748B);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _measuresCell(DashboardTrackingRow row) {
    final value = row.measures;
    final isSuggesting = widget.suggestingRowId == row.rowId;

    if (!widget.editable) {
      return Text(
        value.trim().isEmpty ? '—' : value,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          color: value.trim().isEmpty
              ? const Color(0xFF94A3B8)
              : const Color(0xFF1E293B),
        ),
      );
    }

    final controller =
        widget.controllers?[DashboardTrackingTable.controllerKey(row, 'measures')];
    if (controller == null) {
      return Text(
        value.trim().isEmpty ? '—' : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      );
    }

    return TextFormField(
      controller: controller,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11),
      decoration: InputDecoration(
        hintText: 'Key metric',
        hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        suffixIcon: widget.onSuggestMetric == null
            ? null
            : SizedBox(
                width: 28,
                child: isSuggesting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : IconButton(
                        tooltip: 'Suggest metric',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        onPressed: () => widget.onSuggestMetric?.call(row),
                      ),
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
    );
  }

  Widget _fieldOrText({
    required DashboardTrackingRow row,
    required String field,
    required String hint,
  }) {
    final value = _valueForField(row, field);

    if (!widget.editable) {
      return Text(
        value.trim().isEmpty ? '—' : value,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.3,
          color: value.trim().isEmpty
              ? const Color(0xFF94A3B8)
              : const Color(0xFF1E293B),
        ),
      );
    }

    final controller =
        widget.controllers?[DashboardTrackingTable.controllerKey(row, field)];
    if (controller == null) {
      return Text(
        value.trim().isEmpty ? '—' : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      );
    }

    return TextFormField(
      controller: controller,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _planCell({
    required double width,
    required Widget child,
    bool highlighted = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFEF9C3) : _planBg,
        border: const Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _trackingCell({
    required Widget child,
    bool isLast = false,
    bool highlighted = false,
  }) {
    return Container(
      width: isLast ? _ytdWidth : _quarterWidth,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? _activeQuarterBg : _trackingBg,
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: _borderColor),
          bottom: const BorderSide(color: _borderColor),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
