import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_config.dart';
import 'strategic_area_catalog.dart';
import 'services/strategic_area_suggestions.dart';
import 'services/plan_progress_service.dart';
import 'services/strategic_areas_session_cache.dart';

class StrategicAreasWidget extends StatefulWidget {
  final Function(List<String>)? onSave;
  final List<String>? initialSelection;
  final Future<void> Function()? onStepComplete;

  const StrategicAreasWidget({
    super.key,
    this.onSave,
    this.initialSelection,
    this.onStepComplete,
  });

  @override
  State<StrategicAreasWidget> createState() => _StrategicAreasWidgetState();
}

class _StrategicAreasWidgetState extends State<StrategicAreasWidget> {
  static const _catalogTitles = kStrategicAreaCatalog;

  late Set<String> _selectedAreas;
  bool _showError = false;
  bool _loadingCompany = true;
  bool _saving = false;

  final _customAreaTitleController = TextEditingController();
  final _customAreaDescriptionController = TextEditingController();
  bool _includeCustomArea = false;

  Set<String> _suggestedAreas = {};
  ManagementDiscussionSummary _managementDiscussion =
      const ManagementDiscussionSummary(gapsAndOpportunities: []);

  String? _companyId;

  @override
  void initState() {
    super.initState();
    _selectedAreas = Set<String>.from(widget.initialSelection ?? []);
    _loadCompanyId();
  }

  @override
  void dispose() {
    _customAreaTitleController.dispose();
    _customAreaDescriptionController.dispose();
    super.dispose();
  }

  String? get _customAreaTitle {
    final title = _customAreaTitleController.text.trim();
    if (!_includeCustomArea || title.isEmpty) return null;
    return title;
  }

  Set<String> get _catalogTitleSet => catalogStrategicAreaTitles();

  int get _effectiveSelectionCount {
    var count = _selectedAreas.length;
    final custom = _customAreaTitle;
    if (custom != null && !_selectedAreas.contains(custom)) {
      count++;
    }
    return count;
  }

  void _syncCustomAreaInSelection() {
    final custom = _customAreaTitle;
    _selectedAreas.removeWhere((title) => !_catalogTitleSet.contains(title));
    if (custom != null) {
      _selectedAreas.add(custom);
    }
  }

  void _toggleSelection(String title) {
    setState(() {
      if (_selectedAreas.contains(title)) {
        _selectedAreas.remove(title);
      } else if (_effectiveSelectionCount < 5) {
        _selectedAreas.add(title);
      }
      _showError = false;
    });
  }

  Future<void> _handleSaveAndContinue() async {
    _syncCustomAreaInSelection();

    if (_includeCustomArea &&
        _customAreaTitleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a name for your custom strategic area or turn it off.',
            ),
            backgroundColor: Color(0xFFB45309),
          ),
        );
      }
      return;
    }

    if (_effectiveSelectionCount < 3) {
      setState(() => _showError = true);
      return;
    }

    if (_companyId == null || _companyId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot save yet — company profile is still loading or missing. '
              'Check your connection and try again.',
            ),
            backgroundColor: Color(0xFFB45309),
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await _saveStrategicAreas();
      if (!skipFirebasePersistence && _companyId != null) {
        await PlanProgressService.cacheProgress(_companyId!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $_effectiveSelectionCount strategic areas.'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      widget.onSave?.call(_selectedAreas.toList());
      await widget.onStepComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save strategic areas: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadCompanyId() async {
    try {
      _companyId = await loadCompanyIdForCurrentUser();
      if (_companyId != null) {
        if (skipFirebasePersistence) {
          _loadStrategicAreasFromSession();
        } else {
          await _loadStrategicAreas();
          await _loadAssessmentContext();
        }
      }
      if (mounted) setState(() => _loadingCompany = false);
    } catch (_) {
      if (mounted) setState(() => _loadingCompany = false);
    }
  }

  Future<void> _loadAssessmentContext() async {
    final result = await StrategicAreaSuggestions.load(
      companyId: _companyId,
      fetchFromFirestore: !skipFirebasePersistence,
    );
    if (!mounted) return;
    setState(() {
      _suggestedAreas = result.suggestedTitles;
      _managementDiscussion = result.managementDiscussion;
    });
  }

  Future<void> _loadStrategicAreas() async {
    if (_companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('strategic_areas');
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) return;

    final data = snap.data()!;
    final areas = data['areas'];
    if (areas is! List) return;

    _selectedAreas.clear();
    for (final entry in areas) {
      final title = entry?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      if (_catalogTitleSet.contains(title)) {
        _selectedAreas.add(title);
      } else if (_customAreaTitleController.text.isEmpty) {
        _customAreaTitleController.text = title;
        _customAreaDescriptionController.text =
            (data['custom_area_description'] ?? '').toString();
        _includeCustomArea = true;
        _selectedAreas.add(title);
      }
    }
  }

  void _loadStrategicAreasFromSession() {
    final cached = StrategicAreasSessionCache.areas;
    if (cached.isEmpty) return;
    _selectedAreas
      ..clear()
      ..addAll(cached.where((title) => _catalogTitleSet.contains(title)));
    for (final title in cached) {
      if (!_catalogTitleSet.contains(title) &&
          _customAreaTitleController.text.isEmpty) {
        _customAreaTitleController.text = title;
        _includeCustomArea = true;
        _selectedAreas.add(title);
      }
    }
  }

  Future<void> _saveStrategicAreas() async {
    if (_companyId == null) return;
    _syncCustomAreaInSelection();

    if (skipFirebasePersistence) {
      StrategicAreasSessionCache.setAreas(_selectedAreas.toList());
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('strategic_areas');
    await ref.set({
      'areas': _selectedAreas.toList(),
      'custom_area_description': _customAreaDescriptionController.text.trim(),
      'include_custom_area': _includeCustomArea,
    }, SetOptions(merge: true));
  }

  void _applySuggestedAreas() {
    setState(() {
      for (final title in _suggestedAreas) {
        if (_effectiveSelectionCount >= 5) break;
        if (!_selectedAreas.contains(title)) {
          _selectedAreas.add(title);
        }
      }
      _showError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCompany) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_companyId == null || _companyId!.isEmpty) _companyWarningBanner(),
          const Text(
            'Define 3-5 Strategic Areas of Focus',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select the themes that best reflect where your organization must improve '
            'or invest over the next 1–3 years. These should connect directly to the '
            'strategic gaps and opportunities identified in Step 2 and will organize '
            'your Year 1 goals and initiatives in Step 4.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          _selectionInfoBox(),
          if (_managementDiscussion.hasContent) ...[
            const SizedBox(height: 20),
            _step2GapsPanel(),
          ],
          if (_suggestedAreas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _suggestionsPanel(),
          ],
          const SizedBox(height: 24),
          _areasGrid(),
          const SizedBox(height: 24),
          _customAreaPanel(),
          const SizedBox(height: 24),
          _footer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _companyWarningBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your account is not linked to a company yet, so selections '
                  'cannot be saved. Complete signup or contact support.',
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionInfoBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _showError ? const Color(0xFFFEF2F2) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _showError
              ? const Color(0xFFFEE2E2)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _showError ? Icons.error_outline : Icons.info_outline,
            color: _showError
                ? const Color(0xFFDC2626)
                : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _showError
                  ? 'Please select at least 3 strategic areas of focus to continue.'
                  : 'Choose 3–5 areas that represent your highest-priority strategic bets—not '
                      'every department. Each selected area becomes a section in Step 4 where '
                      'you\'ll define one goal and 2–3 initiatives.',
              style: TextStyle(
                fontSize: 14,
                color: _showError
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step2GapsPanel() {
    final filled = _managementDiscussion.gapsAndOpportunities
        .where((entry) => entry.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: Colors.green.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'From Step 2: Management Discussion',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Use these agreed gaps and opportunities to guide which strategic areas you select:',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          ...filled.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _suggestionsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: Colors.blue.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'Suggested based on your Step 2 assessment',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedAreas.map((title) {
              final selected = _selectedAreas.contains(title);
              return InputChip(
                label: Text(title),
                selected: selected,
                onSelected: (_) => _toggleSelection(title),
                selectedColor: const Color(0xFFDBEAFE),
                checkmarkColor: const Color(0xFF1E40AF),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _applySuggestedAreas,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Apply all suggested areas'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areasGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1100
            ? 4
            : width > 720
                ? 3
                : width > 420
                    ? 2
                    : 1;

        final childAspectRatio = crossAxisCount >= 4
            ? 1.55
            : crossAxisCount == 3
                ? 1.45
                : crossAxisCount == 2
                    ? 1.35
                    : 2.4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _catalogTitles.length,
          itemBuilder: (context, index) {
            final area = _catalogTitles[index];
            final isSelected = _selectedAreas.contains(area.title);
            final atMax = !isSelected && _effectiveSelectionCount >= 5;

            return StrategicAreaCard(
              area: area,
              isSelected: isSelected,
              isSuggested: _suggestedAreas.contains(area.title),
              onTap: () => _toggleSelection(area.title),
              isDisabled: atMax,
            );
          },
        );
      },
    );
  }

  Widget _customAreaPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _includeCustomArea
              ? const Color(0xFF4B7BEC)
              : const Color(0xFFE5E7EB),
          width: _includeCustomArea ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_outlined, color: Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Custom Strategic Area (optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Switch(
                value: _includeCustomArea,
                activeTrackColor: const Color(0xFF4B7BEC).withValues(alpha: 0.45),
                activeThumbColor: const Color(0xFF4B7BEC),
                onChanged: (value) {
                  setState(() {
                    _includeCustomArea = value;
                    if (!value) {
                      final custom = _customAreaTitleController.text.trim();
                      if (custom.isNotEmpty) {
                        _selectedAreas.remove(custom);
                      }
                    } else {
                      _syncCustomAreaInSelection();
                    }
                    _showError = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Add one organization-specific theme if it isn\'t covered above '
            '(e.g., Community Impact, Regulatory Change). Counts toward your 3–5 selections.',
            style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade700),
          ),
          if (_includeCustomArea) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customAreaTitleController,
              decoration: InputDecoration(
                labelText: 'Custom area name',
                hintText: 'e.g., Community Impact',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (_) {
                setState(() {
                  _syncCustomAreaInSelection();
                  _showError = false;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customAreaDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Brief description (optional)',
                hintText: 'What outcomes will goals in this area aim to achieve?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    final count = _effectiveSelectionCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: count == 0
                ? Colors.grey.shade100
                : count < 3
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count of 3-5 selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: count == 0
                  ? Colors.grey.shade600
                  : count < 3
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF1E40AF),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: (count >= 3 &&
                  (_companyId != null && _companyId!.isNotEmpty) &&
                  !_saving)
              ? _handleSaveAndContinue
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4B7BEC),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

class StrategicAreaCard extends StatelessWidget {
  final StrategicArea area;
  final bool isSelected;
  final bool isSuggested;
  final VoidCallback onTap;
  final bool isDisabled;

  const StrategicAreaCard({
    super.key,
    required this.area,
    required this.isSelected,
    this.isSuggested = false,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4B7BEC)
                  : isSuggested
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4B7BEC).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      area.icon,
                      color: isSelected
                          ? const Color(0xFF4B7BEC)
                          : const Color(0xFF6B7280),
                      size: 18,
                    ),
                    const Spacer(),
                    if (isSuggested && !isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Suggested',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    if (isSelected) ...[
                      if (isSuggested) const SizedBox(width: 4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4B7BEC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  area.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    area.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF6B7280),
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
