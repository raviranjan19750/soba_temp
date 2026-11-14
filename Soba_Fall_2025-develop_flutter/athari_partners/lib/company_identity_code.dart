import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/openai_service.dart';

class CompanyIdentityTab extends StatefulWidget {
  const CompanyIdentityTab({super.key});

  @override
  State<CompanyIdentityTab> createState() => _CompanyIdentityTabState();
}

enum _YesNo { yes, no }

class _CompanyIdentityTabState extends State<CompanyIdentityTab> {
  final _competitiveController = TextEditingController();

  // Values conditional fields
  final _valuesTextController = TextEditingController();
  final _valuesWhoController = TextEditingController();
  final Map<String, bool> _valuesShared = {
    'Internally with employees': false,
    'Externally with customers/partners': false,
    'Published on website/materials': false,
    'Not actively shared': false,
  };

  // Vision conditional fields
  final _visionTextController = TextEditingController();
  final _visionWhoController = TextEditingController();
  _YesNo? _visionStillInspires;

  // Mission conditional fields
  final _missionTextController = TextEditingController();
  final _missionWhoController = TextEditingController();
  _YesNo? _missionStillRelevant;
  _YesNo? _missionStillInspires;

  _YesNo? values;
  _YesNo? vision;
  _YesNo? mission;

  String? _companyId;
  bool _loading = true;
  
  // AI loading states
  bool _valuesAILoading = false;
  bool _visionAILoading = false;
  bool _missionAILoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      _companyId = userDoc['companyId'];
      await _loadMissionVisionValues();
    }
  }

  // Future<void> _loadMissionVisionValues() async {
  //   if (_companyId == null) return;

  //   // Load competitive advantages (string)
  //   final compAdvRef = FirebaseFirestore.instance
  //       .collection('companies')
  //       .doc(_companyId)
  //       .collection('companyIdentity')
  //       .doc('competitive_advantages');

  //   final compAdvSnapshot = await compAdvRef.get();
  //   print(compAdvSnapshot);
  //   if (compAdvSnapshot.exists && compAdvSnapshot.data() != null) {
  //     final data = compAdvSnapshot.data()!;
  //     _competitiveController.text = data['competitive_advantages'] ?? '';
  //   }

  //   // Load mission/vision/values booleans
  //   final identityRef = FirebaseFirestore.instance
  //       .collection('companies')
  //       .doc(_companyId)
  //       .collection('companyIdentity')
  //       .doc('refine_company_identity');

  //   final identifySnapshot = await identityRef.get();
  //   print(identifySnapshot);
  //   if (identifySnapshot.exists && identifySnapshot.data() != null) {
  //     final data = identifySnapshot.data()!;
  //     setState(() {
  //       values = data['values'] == true ? _YesNo.yes : _YesNo.no;
  //       vision = data['vision'] == true ? _YesNo.yes : _YesNo.no;
  //       mission = data['mission'] == true ? _YesNo.yes : _YesNo.no;

  //       _valuesTextController.text = data['values_str'];
  //       _visionTextController.text = data['vision_str'];
  //       _missionTextController.text = data['mission_str'];

  //       _valuesWhoController.text = data['values_who_str'];
  //       _visionWhoController.text = data['vision_who_str'];
  //       _missionWhoController.text = data['mission_who_str'];

  //       _missionStillRelevant = data['mission_still_relevant'] == true
  //           ? _YesNo.yes
  //           : _YesNo.no;
  //       _missionStillInspires = data['mission_still_inspires'] == true
  //           ? _YesNo.yes
  //           : _YesNo.no;

  //       _visionStillInspires = data['vision_still_inspires'] == true
  //           ? _YesNo.yes
  //           : _YesNo.no;

  //       // values_shared stored as a nested map in Firestore under 'values_shared'
  //       final valuesSharedMap = data['values_shared'];
  //       if (valuesSharedMap is Map<String, dynamic>) {
  //         for (final key in _valuesShared.keys) {
  //           _valuesShared[key] = valuesSharedMap[key] ?? false;
  //         }
  //       } else {
  //         // fallback: older documents may have keys at top level
  //         for (final key in _valuesShared.keys) {
  //           _valuesShared[key] = data[key] ?? false;
  //         }
  //       }
  //       _loading = false;
  //     });
  //   } else {
  //     setState(() => _loading = false);
  //   }
  // }

  Future<void> _loadMissionVisionValues() async {
    try {
      if (_companyId == null) return;

      final compAdvRef = FirebaseFirestore.instance
          .collection('companies')
          .doc(_companyId)
          .collection('companyIdentity')
          .doc('competitive_advantages');

      final compAdvSnapshot = await compAdvRef.get().timeout(
        const Duration(seconds: 5),
      );

      if (compAdvSnapshot.exists && compAdvSnapshot.data() != null) {
        _competitiveController.text =
            compAdvSnapshot.data()!['competitive_advantages'] ?? '';
      }

      final identityRef = FirebaseFirestore.instance
          .collection('companies')
          .doc(_companyId)
          .collection('companyIdentity')
          .doc('refine_company_identity');

      final identitySnapshot = await identityRef.get().timeout(
        const Duration(seconds: 5),
      );

      if (!mounted) return;

      if (identitySnapshot.exists && identitySnapshot.data() != null) {
        setState(() {
          // your existing setState code
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e, st) {
      print("🔥 LOAD ERROR: $e");
      print(st);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveCompetitiveAdvantages() async {
    if (_companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyIdentity')
        .doc('competitive_advantages');

    await docRef.set({
      'competitive_advantages': _competitiveController.text,
    }, SetOptions(merge: true));
  }

  Future<void> _saveMissionVisionValues() async {
    if (_companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyIdentity')
        .doc('refine_company_identity');

    await docRef.set({
      'values': values == _YesNo.yes,
      'vision': vision == _YesNo.yes,
      'mission': mission == _YesNo.yes,

      'values_str': _valuesTextController.text,
      'vision_str': _visionTextController.text,
      'mission_str': _missionTextController.text,

      'values_who_str': _valuesWhoController.text,
      'vision_who_str': _visionWhoController.text,
      'mission_who_str': _missionWhoController.text,

      'mission_still_inspires': _missionStillInspires == _YesNo.yes,
      'mission_still_relevant': _missionStillRelevant == _YesNo.yes,
      'vision_still_inspires': _visionStillInspires == _YesNo.yes,

      // store the values shared map as a nested map field
      'values_shared': _valuesShared,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _competitiveController.dispose();
    _valuesTextController.dispose();
    _valuesWhoController.dispose();
    _visionTextController.dispose();
    _visionWhoController.dispose();
    _missionTextController.dispose();
    _missionWhoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      children: [
        _SectionCard(
          title: 'Refine Company Identity',
          icon: Icons.business_center_outlined,
          accentColor: const Color(0xFF8B5CF6), // Purple
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EnhancedYesNoQuestion(
                heading: 'Values',
                prompt: 'Do you have company values?',
                groupValue: values,
                onChanged: (v) => setState(() => values = v),
                showConditional: values == _YesNo.yes,
                conditionalWidget: _buildValuesConditional(),
              ),
              const _HR(),
              _EnhancedYesNoQuestion(
                heading: 'Vision',
                prompt: 'Do you have a company vision?',
                groupValue: vision,
                onChanged: (v) => setState(() => vision = v),
                showConditional: vision == _YesNo.yes,
                conditionalWidget: _buildVisionConditional(),
              ),
              const _HR(),
              _EnhancedYesNoQuestion(
                heading: 'Mission',
                prompt: 'Do you have a company mission?',
                groupValue: mission,
                onChanged: (v) => setState(() => mission = v),
                showConditional: mission == _YesNo.yes,
                conditionalWidget: _buildMissionConditional(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Competitive Advantages',
          icon: Icons.trending_up_outlined,
          accentColor: const Color(0xFF10B981), // Emerald
          child: _LabeledTextArea(
            label: "What are your company's competitive advantages?",
            hint: 'Describe what sets your company apart from competitors...',
            controller: _competitiveController,
            maxLines: 6,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Spacer(),
            ElevatedButton(
              onPressed: _saveIdentity,
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
      ],
    );
  }

  Future<void> _saveIdentity() async {
    try {
      // Save competitive advantages
      await _saveCompetitiveAdvantages();

      // Save mission/vision/values booleans
      await _saveMissionVisionValues();

      final snack = SnackBar(
        content: Text(
          'Saved! values=$values, vision=$vision, mission=$mission, '
          'advantages="${_competitiveController.text.trim().isEmpty ? "(empty)" : "filled"}"',
        ),
        backgroundColor: Colors.green,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
    } catch (e) {
      final errorSnack = SnackBar(
        content: Text('Error saving: $e'),
        backgroundColor: Colors.red,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(errorSnack);
      }
    }
  }

  Widget _buildValuesConditional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _LabeledTextAreaWithAI(
          label: 'If yes, what are your values?',
          hint: 'Enter your company values...',
          controller: _valuesTextController,
          maxLines: 4,
          fieldType: 'Values',
          isLoading: _valuesAILoading,
          onSuggest: () => _generateAISuggestion('Values', _valuesTextController, (loading) {
            setState(() => _valuesAILoading = loading);
          }),
        ),
        const SizedBox(height: 12),
        _LabeledTextArea(
          label: 'Who helped define the values?',
          hint: 'e.g., Leadership team, All employees, Consultants',
          controller: _valuesWhoController,
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        Text(
          'Are the values shared?',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._valuesShared.keys.map(
          (key) => CheckboxListTile(
            value: _valuesShared[key],
            onChanged: (v) => setState(() => _valuesShared[key] = v ?? false),
            title: Text(key),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildVisionConditional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _LabeledTextAreaWithAI(
          label: 'If yes, what is your vision?',
          hint: 'Enter your company vision...',
          controller: _visionTextController,
          maxLines: 4,
          fieldType: 'Vision',
          isLoading: _visionAILoading,
          onSuggest: () => _generateAISuggestion('Vision', _visionTextController, (loading) {
            setState(() => _visionAILoading = loading);
          }),
        ),
        const SizedBox(height: 12),
        _LabeledTextArea(
          label: 'Who helped define the vision?',
          hint: 'e.g., Founder, Leadership team, Board',
          controller: _visionWhoController,
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        _YesNoQuestion(
          heading: 'Does it still inspire and align with where we\'re headed?',
          prompt: '',
          groupValue: _visionStillInspires,
          onChanged: (v) => setState(() => _visionStillInspires = v),
        ),
      ],
    );
  }

  Widget _buildMissionConditional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _LabeledTextAreaWithAI(
          label: 'If yes, what is your mission?',
          hint: 'Enter your company mission...',
          controller: _missionTextController,
          maxLines: 4,
          fieldType: 'Mission',
          isLoading: _missionAILoading,
          onSuggest: () => _generateAISuggestion('Mission', _missionTextController, (loading) {
            setState(() => _missionAILoading = loading);
          }),
        ),
        const SizedBox(height: 12),
        _LabeledTextArea(
          label: 'Who helped define the mission?',
          hint: 'e.g., Founder, Leadership team, Board',
          controller: _missionWhoController,
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        _YesNoQuestion(
          heading: 'Is it still relevant?',
          prompt: '',
          groupValue: _missionStillRelevant,
          onChanged: (v) => setState(() => _missionStillRelevant = v),
        ),
        const SizedBox(height: 12),
        _YesNoQuestion(
          heading: 'Does it still inspire and guide us today?',
          prompt: '',
          groupValue: _missionStillInspires,
          onChanged: (v) => setState(() => _missionStillInspires = v),
        ),
      ],
    );
  }

  Future<void> _generateAISuggestion(
    String fieldType,
    TextEditingController controller,
    Function(bool) setLoading,
  ) async {
    try {
      setLoading(true);
      final openaiService = OpenAIService();
      final suggestion = await openaiService.generateSuggestion(
        fieldType: fieldType,
        existingText: controller.text,
      );
      
      if (mounted) {
        controller.text = suggestion;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI suggestion generated for $fieldType!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating suggestion: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }
}

/* ----------------------------- Local widgets ----------------------------- */

class _PageScroll extends StatelessWidget {
  final List<Widget> children;
  const _PageScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    const maxW = 920.0;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFAFBFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.1), width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.1),
                          primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _HR extends StatelessWidget {
  const _HR();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 28, color: Color(0xFFE7EAF0));
}

class _YesNoQuestion extends StatelessWidget {
  final String heading;
  final String prompt;
  final _YesNo? groupValue;
  final ValueChanged<_YesNo?> onChanged;

  const _YesNoQuestion({
    required this.heading,
    required this.prompt,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (prompt.isNotEmpty) Text(prompt),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          children: [
            RadioMenuButton<_YesNo>(
              value: _YesNo.yes,
              groupValue: groupValue,
              onChanged: onChanged,
              child: const Text('Yes'),
            ),
            RadioMenuButton<_YesNo>(
              value: _YesNo.no,
              groupValue: groupValue,
              onChanged: onChanged,
              child: const Text('No'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnhancedYesNoQuestion extends StatelessWidget {
  final String heading;
  final String prompt;
  final _YesNo? groupValue;
  final ValueChanged<_YesNo?> onChanged;
  final bool showConditional;
  final Widget conditionalWidget;

  const _EnhancedYesNoQuestion({
    required this.heading,
    required this.prompt,
    required this.groupValue,
    required this.onChanged,
    required this.showConditional,
    required this.conditionalWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (prompt.isNotEmpty) Text(prompt),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          children: [
            RadioMenuButton<_YesNo>(
              value: _YesNo.yes,
              groupValue: groupValue,
              onChanged: onChanged,
              child: const Text('Yes'),
            ),
            RadioMenuButton<_YesNo>(
              value: _YesNo.no,
              groupValue: groupValue,
              onChanged: onChanged,
              child: const Text('No'),
            ),
          ],
        ),
        if (showConditional) conditionalWidget,
      ],
    );
  }
}

class _LabeledTextArea extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;

  const _LabeledTextArea({
    required this.label,
    required this.hint,
    this.controller,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _roundedDecoration(context, hint),
        ),
      ],
    );
  }
}

class _LabeledTextAreaWithAI extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  final String fieldType;
  final bool isLoading;
  final VoidCallback onSuggest;

  const _LabeledTextAreaWithAI({
    required this.label,
    required this.hint,
    this.controller,
    this.maxLines = 3,
    required this.fieldType,
    required this.isLoading,
    required this.onSuggest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: _roundedDecoration(context, hint),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onSuggest,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Suggest'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

InputDecoration _roundedDecoration(BuildContext context, String hint) {
  final primary = Theme.of(context).colorScheme.primary;
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primary, width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
