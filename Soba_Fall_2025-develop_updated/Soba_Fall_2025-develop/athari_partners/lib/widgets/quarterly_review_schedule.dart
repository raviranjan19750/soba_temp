import 'package:flutter/material.dart';

import '../services/quarterly_review_schedule.dart';

/// Editable quarterly review schedule for Step 5 dashboard.
class QuarterlyReviewScheduleSection extends StatefulWidget {
  const QuarterlyReviewScheduleSection({
    super.key,
    required this.companyId,
  });

  final String? companyId;

  @override
  State<QuarterlyReviewScheduleSection> createState() =>
      _QuarterlyReviewScheduleSectionState();
}

class _QuarterlyReviewScheduleSectionState
    extends State<QuarterlyReviewScheduleSection> {
  bool _loading = true;
  bool _saving = false;
  List<QuarterlyReviewEntry> _entries = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant QuarterlyReviewScheduleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _load();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries =
        await QuarterlyReviewScheduleService.load(widget.companyId);
    if (!mounted) return;

    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    for (final entry in entries) {
      _controllers['${entry.quarterKey}_date'] =
          TextEditingController(text: entry.reviewDate);
      _controllers['${entry.quarterKey}_participants'] =
          TextEditingController(text: entry.participants);
      _controllers['${entry.quarterKey}_focus'] =
          TextEditingController(text: entry.focusAreas);
    }

    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<QuarterlyReviewEntry> _collectEntries() {
    return _entries.map((entry) {
      return entry.copyWith(
        reviewDate:
            _controllers['${entry.quarterKey}_date']?.text.trim() ?? '',
        participants:
            _controllers['${entry.quarterKey}_participants']?.text.trim() ??
                '',
        focusAreas:
            _controllers['${entry.quarterKey}_focus']?.text.trim() ?? '',
      );
    }).toList();
  }

  Future<void> _save() async {
    if (widget.companyId == null || widget.companyId!.isEmpty) return;
    setState(() => _saving = true);
    try {
      await QuarterlyReviewScheduleService.save(
        widget.companyId!,
        _collectEntries(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quarterly review schedule saved'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save review schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quarterly Review Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Plan leadership review dates, participants, and focus topics for each quarter.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 16),
            if (isMobile)
              ..._entries.map(_mobileQuarterCard)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _desktopTable(),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _saving || widget.companyId == null ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving…' : 'Save review schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopTable() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 11,
      color: Color(0xFF475569),
    );

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      columnWidths: const {
        0: FixedColumnWidth(72),
        1: FixedColumnWidth(140),
        2: FixedColumnWidth(200),
        3: FixedColumnWidth(280),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('QUARTER', style: headerStyle),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('REVIEW DATE', style: headerStyle),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('PARTICIPANTS', style: headerStyle),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('FOCUS AREAS', style: headerStyle),
            ),
          ],
        ),
        for (final entry in _entries) _desktopRow(entry),
      ],
    );
  }

  TableRow _desktopRow(QuarterlyReviewEntry entry) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            entry.quarterLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        _fieldCell('${entry.quarterKey}_date', 'Review date'),
        _fieldCell('${entry.quarterKey}_participants', 'Participants'),
        _fieldCell('${entry.quarterKey}_focus', 'Focus areas', maxLines: 3),
      ],
    );
  }

  Widget _fieldCell(String key, String hint, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 12),
      child: TextField(
        controller: _controllers[key],
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _mobileQuarterCard(QuarterlyReviewEntry entry) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.quarterLabel,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _labeledField('Review date', '${entry.quarterKey}_date'),
          const SizedBox(height: 8),
          _labeledField('Participants', '${entry.quarterKey}_participants'),
          const SizedBox(height: 8),
          _labeledField('Focus areas', '${entry.quarterKey}_focus', maxLines: 3),
        ],
      ),
    );
  }

  Widget _labeledField(String label, String key, {int maxLines = 2}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controllers[key],
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}
