import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class StrategicAreasWidget extends StatefulWidget {
  final Function(List<String>)? onSave;
  final List<String>? initialSelection;

  const StrategicAreasWidget({Key? key, this.onSave, this.initialSelection})
    : super(key: key);

  @override
  State<StrategicAreasWidget> createState() => _StrategicAreasWidgetState();
}

class _StrategicAreasWidgetState extends State<StrategicAreasWidget> {
  final List<StrategicArea> _strategicAreas = [
    const StrategicArea(
      title: 'Market Expansion',
      description:
          'Entering new markets or expanding reach within existing ones',
      icon: Icons.public,
    ),
    const StrategicArea(
      title: 'Product Development',
      description: 'Creating new products or enhancing existing offerings',
      icon: Icons.inventory_2_outlined,
    ),
    const StrategicArea(
      title: 'Operational Excellence',
      description: 'Improving internal processes and efficiency',
      icon: Icons.settings_suggest_outlined,
    ),
    const StrategicArea(
      title: 'Talent & Culture',
      description: 'Developing people, leadership and organizational culture',
      icon: Icons.groups_outlined,
    ),
    const StrategicArea(
      title: 'Technology & Innovation',
      description: 'Leveraging technology to create competitive advantages',
      icon: Icons.lightbulb_outline,
    ),
    const StrategicArea(
      title: 'Customer Experience',
      description: 'Enhancing how customers interact with your business',
      icon: Icons.sentiment_satisfied_alt_outlined,
    ),
    const StrategicArea(
      title: 'Financial Management',
      description: 'Optimizing capital structure and financial performance',
      icon: Icons.account_balance_outlined,
    ),
    const StrategicArea(
      title: 'Strategic Partnerships',
      description: 'Developing key relationships with other organizations',
      icon: Icons.handshake_outlined,
    ),
  ];

  late Set<String> _selectedAreas;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _selectedAreas = Set<String>.from(widget.initialSelection ?? []);
    _loadCompanyId();
  }

  void _toggleSelection(String title) {
    setState(() {
      if (_selectedAreas.contains(title)) {
        _selectedAreas.remove(title);
      } else if (_selectedAreas.length < 5) {
        _selectedAreas.add(title);
      }
      _showError = false;
    });
  }

  Future<void> _handleSaveAndContinue() async {
    if (_selectedAreas.length < 3) {
      setState(() {
        _showError = true;
      });
      return;
    }

    try {
      await _saveStrategicAreas();
    } catch (e) {
      // ignore save errors here; caller may handle
    }

    if (widget.onSave != null) {
      widget.onSave!(_selectedAreas.toList());
    }
  }

  // Firebase helpers
  String? _companyId;

  Future<void> _loadCompanyId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        _companyId = userDoc['companyId'];
        await _loadStrategicAreas();
        setState(() {});
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadStrategicAreas() async {
    if (_companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('strategic_areas');
    final snap = await ref.get();
    if (snap.exists && snap.data() != null) {
      final data = snap.data()!;
      final areas = data['areas'];
      if (areas is List) {
        _selectedAreas = Set<String>.from(
          areas.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty),
        );
      }
    }
  }

  Future<void> _saveStrategicAreas() async {
    if (_companyId == null) return;
    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('strategic_areas');
    await ref.set({'areas': _selectedAreas.toList()}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Define 3-5 Strategic Areas of Focus',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Warning/Info box
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showError
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showError
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFFDE68A),
                width: 1,
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
                        : 'Please select at least 3 strategic areas of focus (maximum 5).',
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
          ),
          const SizedBox(height: 24),

          // Grid of strategic areas
          LayoutBuilder(
            builder: (context, constraints) {
              // Determine grid layout based on screen width
              int crossAxisCount = 2;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 800) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth < 500) {
                crossAxisCount = 1;
              }

              double childAspectRatio = constraints.maxWidth < 500 ? 3.5 : 1.8;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _strategicAreas.length,
                itemBuilder: (context, index) {
                  final area = _strategicAreas[index];
                  final isSelected = _selectedAreas.contains(area.title);

                  return StrategicAreaCard(
                    area: area,
                    isSelected: isSelected,
                    onTap: () => _toggleSelection(area.title),
                    isDisabled: !isSelected && _selectedAreas.length >= 5,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Footer with button and counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Selection counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedAreas.isEmpty
                      ? Colors.grey.shade100
                      : _selectedAreas.length < 3
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedAreas.length} of 3-5 selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedAreas.isEmpty
                        ? Colors.grey.shade600
                        : _selectedAreas.length < 3
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E40AF),
                  ),
                ),
              ),

              // Save & Continue button
              ElevatedButton(
                onPressed: _selectedAreas.length >= 3
                    ? _handleSaveAndContinue
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7BEC),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class StrategicAreaCard extends StatelessWidget {
  final StrategicArea area;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDisabled;

  const StrategicAreaCard({
    Key? key,
    required this.area,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4B7BEC)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4B7BEC).withOpacity(0.1),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header with icon and checkmark
                Row(
                  children: [
                    Icon(
                      area.icon,
                      color: isSelected
                          ? const Color(0xFF4B7BEC)
                          : const Color(0xFF6B7280),
                      size: 24,
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4B7BEC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  area.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  area.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Example usage
class StrategicAreasScreen extends StatelessWidget {
  const StrategicAreasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StrategicAreasWidget(
        onSave: (selectedAreas) {
          // Handle save action
          print('Selected strategic areas: $selectedAreas');
          // Navigate to next screen or save to database
        },
      ),
    );
  }
}
