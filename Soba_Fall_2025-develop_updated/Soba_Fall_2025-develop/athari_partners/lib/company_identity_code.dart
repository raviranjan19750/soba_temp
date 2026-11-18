import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_config.dart';
import 'services/identity_session_cache.dart';
import 'services/openai_service.dart';
import 'services/plan_progress_service.dart';
import 'utils/debounced_auto_save.dart';

/// Sub-tabs under Step 1 — Company Identity (see [CompanyIdentityPage]).
enum CompanyIdentityTabPanel {
  companyIdentity,
  companyBackground,
}

class CompanyIdentityTab extends StatefulWidget {
  const CompanyIdentityTab({
    super.key,
    required this.panel,
    this.onSaveAndContinue,
    this.onProgressChanged,
    this.onAdvanceToIdentityTab,
  });

  final CompanyIdentityTabPanel panel;
  final Future<void> Function()? onSaveAndContinue;
  final VoidCallback? onProgressChanged;
  final VoidCallback? onAdvanceToIdentityTab;

  @override
  State<CompanyIdentityTab> createState() => _CompanyIdentityTabState();
}

enum _YesNo { yes, no }

enum _IdentitySuggestField { companyValues, vision, mission }

class _CompanyIdentityTabState extends State<CompanyIdentityTab> {
  // Company background
  final _backgroundProductsServicesController = TextEditingController();
  final _backgroundCustomerProblemController = TextEditingController();
  final _backgroundPrimaryCustomersController = TextEditingController();
  final _backgroundIndustriesController = TextEditingController();
  final _backgroundRevenueController = TextEditingController();
  final _backgroundGeographyController = TextEditingController();
  final _backgroundCompetitiveAdvantageController = TextEditingController();

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

  final DebouncedAutoSave _autoSave = DebouncedAutoSave();
  AutoSaveState _saveState = AutoSaveState.idle;
  String? _saveError;
  bool _autoSaveListenersAttached = false;
  _IdentitySuggestField? _suggestingIdentityField;

  /// Placeholder for mission text fields (Yes / No paths).
  static const _missionStatementHint =
      'Our mission is to [core purpose / what you do], by [how you do it / unique approach], so that [who you serve] can [impact or benefit delivered].';

  @override
  void initState() {
    super.initState();
    _attachAutoSaveListeners();
    _loadCompanyId();
  }

  void _attachAutoSaveListeners() {
    if (_autoSaveListenersAttached) return;
    _autoSaveListenersAttached = true;

    void listen(TextEditingController c) => c.addListener(_scheduleAutoSave);

    listen(_backgroundProductsServicesController);
    listen(_backgroundCustomerProblemController);
    listen(_backgroundPrimaryCustomersController);
    listen(_backgroundIndustriesController);
    listen(_backgroundRevenueController);
    listen(_backgroundGeographyController);
    listen(_backgroundCompetitiveAdvantageController);
    listen(_valuesTextController);
    listen(_valuesWhoController);
    listen(_visionTextController);
    listen(_visionWhoController);
    listen(_missionTextController);
    listen(_missionWhoController);
  }

  void _scheduleAutoSave() {
    _autoSave.schedule(
      _saveSilent,
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

  Future<void> _saveSilent() async {
    if (_companyId == null) return;
    if (skipFirebasePersistence) {
      IdentitySessionCache.update(
        vision: _visionTextController.text.trim(),
        mission: _missionTextController.text.trim(),
        values: _valuesTextController.text.trim(),
      );
      return;
    }
    await _saveCompanyBackground();
    await _saveMissionVisionValues();
    await PlanProgressService.cacheProgress(_companyId!);
  }

  Future<void> _loadCompanyId() async {
    try {
      _companyId = await loadCompanyIdForCurrentUser();
      if (!authBypassEnabled && _companyId != null) {
        await _loadMissionVisionValues();
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e, st) {
      print("🔥 LOAD ERROR: $e");
      print(st);
      if (!mounted) return;
      setState(() => _loading = false);
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

      final backgroundRef = FirebaseFirestore.instance
          .collection('companies')
          .doc(_companyId)
          .collection('companyIdentity')
          .doc('company_background');

      final backgroundSnapshot = await backgroundRef.get().timeout(
        const Duration(seconds: 5),
      );

      if (backgroundSnapshot.exists && backgroundSnapshot.data() != null) {
        final bg = backgroundSnapshot.data()!;
        _backgroundProductsServicesController.text =
            (bg['products_services'] as String?) ?? '';
        _backgroundCustomerProblemController.text =
            (bg['customer_problem'] as String?) ?? '';
        _backgroundPrimaryCustomersController.text =
            (bg['primary_customers'] as String?) ?? '';
        _backgroundIndustriesController.text =
            (bg['industries_served'] as String?) ?? '';
        _backgroundRevenueController.text =
            (bg['revenue_model'] as String?) ?? '';
        _backgroundGeographyController.text =
            (bg['geographic_area'] as String?) ?? '';
        _backgroundCompetitiveAdvantageController.text =
            (bg['competitive_advantage'] as String?) ?? '';
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
        final data = identitySnapshot.data()!;
        setState(() {
          final vVal = data['values'];
          values = vVal == true
              ? _YesNo.yes
              : vVal == false
                  ? _YesNo.no
                  : null;
          final visVal = data['vision'];
          vision = visVal == true
              ? _YesNo.yes
              : visVal == false
                  ? _YesNo.no
                  : null;
          final mVal = data['mission'];
          mission = mVal == true
              ? _YesNo.yes
              : mVal == false
                  ? _YesNo.no
                  : null;

          _valuesTextController.text =
              (data['values_str'] as String?) ?? '';
          _visionTextController.text =
              (data['vision_str'] as String?) ?? '';
          _missionTextController.text =
              (data['mission_str'] as String?) ?? '';

          _valuesWhoController.text =
              (data['values_who_str'] as String?) ?? '';
          _visionWhoController.text =
              (data['vision_who_str'] as String?) ?? '';
          _missionWhoController.text =
              (data['mission_who_str'] as String?) ?? '';

          final msr = data['mission_still_relevant'];
          _missionStillRelevant = msr == true
              ? _YesNo.yes
              : msr == false
                  ? _YesNo.no
                  : null;
          final msi = data['mission_still_inspires'];
          _missionStillInspires = msi == true
              ? _YesNo.yes
              : msi == false
                  ? _YesNo.no
                  : null;
          final vsi = data['vision_still_inspires'];
          _visionStillInspires = vsi == true
              ? _YesNo.yes
              : vsi == false
                  ? _YesNo.no
                  : null;

          final valuesSharedMap = data['values_shared'];
          if (valuesSharedMap is Map<String, dynamic>) {
            for (final key in _valuesShared.keys) {
              _valuesShared[key] = valuesSharedMap[key] == true;
            }
          } else {
            for (final key in _valuesShared.keys) {
              _valuesShared[key] = data[key] == true;
            }
          }

          _loading = false;
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

  bool get _aiSuggestionsEnabled => aiSuggestionsEnabled;

  String _companyBackgroundContext() {
    final parts = <String>[];
    void add(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) parts.add('$label: $trimmed');
    }

    add('Products/services', _backgroundProductsServicesController.text);
    add('Customer problem', _backgroundCustomerProblemController.text);
    add('Primary customers', _backgroundPrimaryCustomersController.text);
    add('Industries served', _backgroundIndustriesController.text);
    add('Revenue model', _backgroundRevenueController.text);
    add('Geographic area', _backgroundGeographyController.text);
    add('Competitive advantage', _backgroundCompetitiveAdvantageController.text);
    return parts.join('\n');
  }

  Future<void> _suggestIdentityField(_IdentitySuggestField field) async {
    if (!_aiSuggestionsEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI suggestions require an OpenAI API key in .env',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fieldType = switch (field) {
      _IdentitySuggestField.companyValues => 'Values',
      _IdentitySuggestField.vision => 'Vision',
      _IdentitySuggestField.mission => 'Mission',
    };
    final controller = switch (field) {
      _IdentitySuggestField.companyValues => _valuesTextController,
      _IdentitySuggestField.vision => _visionTextController,
      _IdentitySuggestField.mission => _missionTextController,
    };

    setState(() => _suggestingIdentityField = field);
    try {
      final suggestion = await OpenAIService().generateSuggestion(
        fieldType: fieldType,
        existingText: controller.text,
        companyBackgroundContext: _companyBackgroundContext(),
      );
      if (!mounted) return;
      controller.text = suggestion;
      _scheduleAutoSave();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Suggested $fieldType added — review and edit as needed'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate suggestion: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _suggestingIdentityField = null);
    }
  }

  Widget _identitySuggestionButton(_IdentitySuggestField field, String label) {
    final loading = _suggestingIdentityField == field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: loading ? null : () => _suggestIdentityField(field),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        if (!_aiSuggestionsEnabled) ...[
          const SizedBox(height: 6),
          Text(
            'Uses your Company Background answers when an OpenAI API key is configured.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
          ),
        ],
      ],
    );
  }

  Future<void> _saveCompanyBackground() async {
    if (skipFirebasePersistence || _companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyIdentity')
        .doc('company_background');

    await docRef.set({
      'products_services': _backgroundProductsServicesController.text,
      'customer_problem': _backgroundCustomerProblemController.text,
      'primary_customers': _backgroundPrimaryCustomersController.text,
      'industries_served': _backgroundIndustriesController.text,
      'revenue_model': _backgroundRevenueController.text,
      'geographic_area': _backgroundGeographyController.text,
      'competitive_advantage': _backgroundCompetitiveAdvantageController.text,
    }, SetOptions(merge: true));
  }

  Future<void> _saveMissionVisionValues() async {
    if (skipFirebasePersistence || _companyId == null) return;

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

  Future<void> _saveValuesSectionOnly() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyIdentity')
        .doc('refine_company_identity');
    await docRef.set({
      'values': values == _YesNo.yes,
      'values_str': _valuesTextController.text,
      'values_who_str': _valuesWhoController.text,
      'values_shared': _valuesShared,
    }, SetOptions(merge: true));
  }

  Future<void> _saveVisionSectionOnly() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyIdentity')
        .doc('refine_company_identity');
    await docRef.set({
      'vision': vision == _YesNo.yes,
      'vision_str': _visionTextController.text,
      'vision_who_str': _visionWhoController.text,
      'vision_still_inspires': _visionStillInspires == _YesNo.yes,
    }, SetOptions(merge: true));
  }

  Future<void> _saveMissionSectionOnly() async {
    if (skipFirebasePersistence || _companyId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('companyIdentity')
        .doc('refine_company_identity');
    await docRef.set({
      'mission': mission == _YesNo.yes,
      'mission_str': _missionTextController.text,
      'mission_who_str': _missionWhoController.text,
      'mission_still_inspires': _missionStillInspires == _YesNo.yes,
      'mission_still_relevant': _missionStillRelevant == _YesNo.yes,
    }, SetOptions(merge: true));
  }

  Future<void> _notifyProgressUpdated() async {
    if (_companyId != null && !skipFirebasePersistence) {
      await PlanProgressService.cacheProgress(_companyId!);
    }
    widget.onProgressChanged?.call();
  }

  Future<void> _onSaveCompanyBackground() async {
    if (_companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company not loaded yet. Please wait.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    try {
      await _saveCompanyBackground();
      await _notifyProgressUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company background saved'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onAdvanceToIdentityTab?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onSaveValuesSection() async {
    if (_companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company not loaded yet. Please wait.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    try {
      await _saveValuesSectionOnly();
      await _notifyProgressUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Values saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onSaveVisionSection() async {
    if (_companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company not loaded yet. Please wait.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    try {
      await _saveVisionSectionOnly();
      await _notifyProgressUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vision saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onSaveMissionSection() async {
    if (_companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company not loaded yet. Please wait.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    try {
      await _saveMissionSectionOnly();
      await _notifyProgressUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission saved'),
            backgroundColor: Colors.green,
          ),
        );
        await widget.onSaveAndContinue?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _sectionSaveButton({
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Save & Continue',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backgroundProductsServicesController.dispose();
    _backgroundCustomerProblemController.dispose();
    _backgroundPrimaryCustomersController.dispose();
    _backgroundIndustriesController.dispose();
    _backgroundRevenueController.dispose();
    _backgroundGeographyController.dispose();
    _backgroundCompetitiveAdvantageController.dispose();
    _valuesTextController.dispose();
    _valuesWhoController.dispose();
    _visionTextController.dispose();
    _visionWhoController.dispose();
    _missionTextController.dispose();
    _missionWhoController.dispose();
    _autoSave.dispose();
    super.dispose();
  }

  List<Widget> _buildCompanyBackgroundPanelChildren() {
    return [
      _SectionCard(
        title: 'Company Background',
        icon: Icons.apartment_outlined,
        accentColor: const Color(0xFF0EA5E9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete this section to capture the essentials of your business '
              'which will lay the foundation for the strategic planning process.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Company narrative',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  '1. What does your company do? Briefly describe your products or services.',
              hint:
                  'Summarize your main offerings—what customers buy or use from you…',
              controller: _backgroundProductsServicesController,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  '2. What problem does your company solve for its customers?',
              hint:
                  'The outcomes, pains, or needs you address for buyers or users…',
              controller: _backgroundCustomerProblemController,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  '3. Who are your primary customers or target audience?',
              hint:
                  'e.g., SMBs, enterprises, consumers, specific roles or segments…',
              controller: _backgroundPrimaryCustomersController,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  '4. What industry or industries does your company primarily serve?',
              hint:
                  'e.g., healthcare, manufacturing, SaaS, retail, public sector…',
              controller: _backgroundIndustriesController,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  '5. How do you primarily generate revenue? (e.g., product sales, subscriptions, consulting, contracts, etc.)',
              hint:
                  'Describe your main revenue streams and how customers pay you…',
              controller: _backgroundRevenueController,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  '6. What geographic area does your business serve? (Local, regional, national, global)',
              hint:
                  'e.g., One city, multi-state, country-wide, or international…',
              controller: _backgroundGeographyController,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _LabeledTextArea(
              label:
                  "7. What is the company's competitive advantage?",
              hint:
                  'What is hard for competitors to copy—capabilities, brand, speed, cost, IP, network, or customer relationships…',
              controller: _backgroundCompetitiveAdvantageController,
              maxLines: 4,
            ),
            _sectionSaveButton(
              backgroundColor: const Color(0xFF0EA5E9),
              onPressed: _onSaveCompanyBackground,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildCompanyIdentityPanelChildren() {
    return [
      _SectionCard(
        title: 'Values',
        icon: Icons.favorite_outline,
        accentColor: const Color(0xFF2E7D32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnhancedYesNoQuestion(
              heading: '',
              prompt: 'Do you have company values?',
              groupValue: values,
              onChanged: (v) => setState(() => values = v),
              yesChild: _buildValuesConditional(),
              noChild: _buildValuesNoDraft(),
            ),
            _sectionSaveButton(
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _onSaveValuesSection,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Vision',
        icon: Icons.visibility_outlined,
        accentColor: const Color(0xFF2E7D32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnhancedYesNoQuestion(
              heading: '',
              prompt: 'Do you have a company vision?',
              groupValue: vision,
              onChanged: (v) => setState(() => vision = v),
              yesChild: _buildVisionConditional(),
              noChild: _buildVisionNoDraft(),
            ),
            _sectionSaveButton(
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _onSaveVisionSection,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Mission',
        icon: Icons.flag_outlined,
        accentColor: const Color(0xFF2E7D32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnhancedYesNoQuestion(
              heading: '',
              prompt: 'Do you have a company mission?',
              groupValue: mission,
              onChanged: (v) => setState(() => mission = v),
              yesChild: _buildMissionConditional(),
              noChild: _buildMissionNoDraft(),
            ),
            _sectionSaveButton(
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _onSaveMissionSection,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final children = switch (widget.panel) {
      CompanyIdentityTabPanel.companyBackground =>
        _buildCompanyBackgroundPanelChildren(),
      CompanyIdentityTabPanel.companyIdentity =>
        _buildCompanyIdentityPanelChildren(),
    };
    return _PageScroll(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AutoSaveStatusChip(
            state: _saveState,
            errorMessage: _saveError,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildValuesConditional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const _ValuesYesRefineAskPrompts(),
        const SizedBox(height: 16),
        _LabeledTextArea(
          label: 'Company Values',
          hint: 'Enter your company values...',
          controller: _valuesTextController,
          maxLines: 4,
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
        const _VisionYesRefineAskPrompts(),
        const SizedBox(height: 16),
        _LabeledTextArea(
          label: 'Company Vision',
          hint: 'Enter your company vision...',
          controller: _visionTextController,
          maxLines: 4,
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

  Widget _buildValuesNoDraft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _NoAnswerDraftBanner(
          message:
              'You answered No—draft proposed company values.',
        ),
        const SizedBox(height: 16),
        const _ValuesNoDefinitionAskPrompts(),
        const SizedBox(height: 16),
        if (_aiSuggestionsEnabled) ...[
          _identitySuggestionButton(
            _IdentitySuggestField.companyValues,
            'Suggest company values',
          ),
          const SizedBox(height: 16),
        ],
        _LabeledTextArea(
          label: 'Draft your company values',
          hint:
              'Describe principles, behaviors, or commitments you want the organization to adopt…',
          controller: _valuesTextController,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildVisionNoDraft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _NoAnswerDraftBanner(
          message:
              'You answered No—draft a proposed company vision.',
        ),
        const SizedBox(height: 16),
        const _VisionNoDefinitionAskPrompts(),
        const SizedBox(height: 16),
        if (_aiSuggestionsEnabled) ...[
          _identitySuggestionButton(
            _IdentitySuggestField.vision,
            'Suggest company vision',
          ),
          const SizedBox(height: 16),
        ],
        _LabeledTextArea(
          label: 'Draft your company vision',
          hint:
              'Where is the organization headed? What future are you working toward…',
          controller: _visionTextController,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildMissionNoDraft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _NoAnswerDraftBanner(
          message:
              'You answered No—draft a proposed company mission.',
        ),
        const SizedBox(height: 16),
        const _MissionNoDefinitionAskPrompts(),
        const SizedBox(height: 16),
        if (_aiSuggestionsEnabled) ...[
          _identitySuggestionButton(
            _IdentitySuggestField.mission,
            'Suggest company mission',
          ),
          const SizedBox(height: 16),
        ],
        _LabeledTextArea(
          label: 'Draft your company mission',
          hint: _missionStatementHint,
          controller: _missionTextController,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildMissionConditional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const _MissionYesRefineAskPrompts(),
        const SizedBox(height: 16),
        _LabeledTextArea(
          label: 'Company Mission',
          hint: _missionStatementHint,
          controller: _missionTextController,
          maxLines: 4,
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

/// Prompts shown when Values = Yes, before the refine fields.
class _ValuesYesRefineAskPrompts extends StatelessWidget {
  const _ValuesYesRefineAskPrompts();

  static const _lines = <String>[
    'What are they, and are they clear to everyone?',
    'Who was involved in defining them?',
    'Are they consistently lived and shared (internally and externally)?',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If YES, refine by asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: bodyStyle?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(_lines[i], style: bodyStyle)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Prompts shown when Values = No, before the draft text field.
class _ValuesNoDefinitionAskPrompts extends StatelessWidget {
  const _ValuesNoDefinitionAskPrompts();

  static const _lines = <String>[
    'What behaviors are non-negotiable in how we operate with employees and customers?',
    'Which principles have driven our success so far?',
    'If holding to this value costs us, would we still keep it?',
    'What do we want to be known for—inside and outside the company?',
    'Where do we see gaps between stated values and actual behaviors?',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If NO, define by asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: bodyStyle?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(_lines[i], style: bodyStyle)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Prompts shown when Vision = Yes, before the refine fields.
class _VisionYesRefineAskPrompts extends StatelessWidget {
  const _VisionYesRefineAskPrompts();

  static const _lines = <String>[
    'Who helped define?',
    'Does it still inspire and align with where we’re headed?',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If YES, refine by asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: bodyStyle?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(_lines[i], style: bodyStyle)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Prompts shown when Vision = No, before the draft text field.
class _VisionNoDefinitionAskPrompts extends StatelessWidget {
  const _VisionNoDefinitionAskPrompts();

  static const _lines = <String>[
    'What does success look like for us in 5–10 years?',
    'How will we be different from today in scale, impact, or reputation?',
    'What “mountain” are we climbing—and why is it worth it?',
    'What story do we want employees, customers, and investors to tell about us?',
    'If resources were unlimited, what bold goal would we pursue?',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If NO, define by asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: bodyStyle?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(_lines[i], style: bodyStyle)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Prompts shown when Mission = Yes, before the refine fields.
class _MissionYesRefineAskPrompts extends StatelessWidget {
  const _MissionYesRefineAskPrompts();

  static const _lines = <String>[
    'Who helped define?',
    'Is it still relevant?',
    'Does it still inspire and guide us today?',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If YES, refine by asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: bodyStyle?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(_lines[i], style: bodyStyle)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Prompts shown when Mission = No, before the draft text field.
class _MissionNoDefinitionAskPrompts extends StatelessWidget {
  const _MissionNoDefinitionAskPrompts();

  static const _lines = <String>[
    'Why do we exist—what unique need do we fulfill?',
    'What would be lost if our company disappeared tomorrow?',
    'Who do we serve, and what problems are we solving?',
    'How does our work contribute to something bigger than ourselves?',
    'What about our mission makes you proud to work here?',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.45,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If NO, define by asking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: bodyStyle?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(_lines[i], style: bodyStyle)),
            ],
          ),
        ],
      ],
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
  final Widget? yesChild;
  final Widget? noChild;

  const _EnhancedYesNoQuestion({
    required this.heading,
    required this.prompt,
    required this.groupValue,
    required this.onChanged,
    this.yesChild,
    this.noChild,
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
        if (groupValue == _YesNo.yes && yesChild != null) yesChild!,
        if (groupValue == _YesNo.no && noChild != null) noChild!,
      ],
    );
  }
}

/// Shown when the user answers **No** so they are prompted to draft that topic.
class _NoAnswerDraftBanner extends StatelessWidget {
  final String message;

  const _NoAnswerDraftBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.edit_note_outlined,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
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
