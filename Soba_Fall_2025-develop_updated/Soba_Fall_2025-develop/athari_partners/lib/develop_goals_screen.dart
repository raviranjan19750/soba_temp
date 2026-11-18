import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_config.dart';
import 'services/plan_progress_service.dart';
import 'services/strategic_areas_repository.dart';
import 'services/goals_session_cache.dart';
import 'services/strategic_areas_session_cache.dart';
import 'utils/debounced_auto_save.dart';

/// Goals & Initiatives (Step #4): one goal and up to three initiatives per strategic area
/// chosen in Step #3 ([strategicPlanning/strategic_areas] → `areas`).
class DevelopGoalsScreen extends StatefulWidget {
  const DevelopGoalsScreen({super.key, this.onSaveAndContinue});

  final Future<void> Function()? onSaveAndContinue;

  @override
  State<DevelopGoalsScreen> createState() => _DevelopGoalsScreenState();
}

class _DevelopGoalsScreenState extends State<DevelopGoalsScreen> {
  String? _companyId;
  bool _loading = true;
  String? _loadError;

  /// Order matches Step #3 selection (Firestore `areas` list order).
  List<String> _focusAreas = [];

  final Map<String, TextEditingController> _goalByArea = {};
  final Map<String, List<TextEditingController>> _initiativeByArea = {};

  /// Keeps Goals & Initiatives in sync when Step #3 saves `strategic_areas`.
  StreamSubscription<DocumentSnapshot>? _strategicAreasSubscription;
  VoidCallback? _sessionAreasListener;

  final DebouncedAutoSave _autoSave = DebouncedAutoSave();
  AutoSaveState _saveState = AutoSaveState.idle;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      _companyId = await loadCompanyIdForCurrentUser();
      if (_companyId == null || _companyId!.isEmpty) {
        setState(() {
          _loading = false;
          _loadError = 'Not signed in.';
        });
        return;
      }

      await _refreshAreasAndGoalsFromFirestore();

      if (!skipFirebasePersistence) {
        _strategicAreasSubscription?.cancel();
        _strategicAreasSubscription = FirebaseFirestore.instance
            .collection('companies')
            .doc(_companyId)
            .collection('strategicPlanning')
            .doc('strategic_areas')
            .snapshots()
            .listen(
              _onStrategicAreasSnapshot,
              onError: (_) {},
            );
      } else {
        _sessionAreasListener ??= _onSessionAreasChanged;
        StrategicAreasSessionCache.areasNotifier
            .addListener(_sessionAreasListener!);
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      final isDenied = e is FirebaseException && e.code == 'permission-denied';
      final msg = isDenied || e.toString().contains('permission-denied')
          ? 'Firestore denied access (missing rules for your company data). '
                'In Firebase Console → Firestore → Rules, deploy rules that allow '
                'signed-in users to read/write documents under '
                'companies/{theirCompanyId}. This repo includes firestore.rules — run '
                '`firebase deploy --only firestore:rules` from the project folder.'
          : 'Could not load data: $e';
      setState(() {
        _loading = false;
        _loadError = msg;
      });
    }
  }

  Map<String, dynamic>? _firestoreDataAsMap(Object? raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  List<String> _parseAreasList(Map<String, dynamic>? data) {
    final areas = <String>[];
    if (data == null) return areas;
    final raw = data['areas'];
    if (raw is List) {
      for (final e in raw) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) areas.add(s);
      }
    }
    return areas;
  }

  Map<String, dynamic> _parsePerAreaGoalsMap(Map<String, dynamic>? planData) {
    if (planData == null) return {};
    final m = planData['perAreaGoals'];
    if (m is Map) return Map<String, dynamic>.from(m);
    return {};
  }

  bool _sameAreasList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Loads strategic areas from Step #3 and any saved per-area goals.
  Future<void> _refreshAreasAndGoalsFromFirestore() async {
    if (_companyId == null || _companyId!.isEmpty) return;

    List<String> areas;
    Map<String, dynamic> perArea;

    if (skipFirebasePersistence) {
      areas = StrategicAreasSessionCache.areas;
      perArea = {
        for (final entry in GoalsSessionCache.perAreaGoals.entries)
          entry.key: {
            'goal': entry.value.goal,
            'initiatives': entry.value.initiatives,
          },
      };
    } else {
      areas = await StrategicAreasRepository.loadAreas(_companyId);
      final goalsByArea =
          await StrategicAreasRepository.loadPerAreaGoals(_companyId);
      perArea = {
        for (final entry in goalsByArea.entries)
          entry.key: {
            'goal': entry.value.goal,
            'initiatives': entry.value.initiatives,
          },
      };
    }

    _replaceControllersForAreas(areas, perArea);
    if (mounted) setState(() {});
  }

  void _onSessionAreasChanged() {
    if (!mounted || !skipFirebasePersistence) return;
    final areas = StrategicAreasSessionCache.areas;
    if (_sameAreasList(areas, _focusAreas)) return;
    _replaceControllersForAreas(areas, {});
    setState(() {});
  }

  Future<void> _onStrategicAreasSnapshot(DocumentSnapshot snap) async {
    if (!mounted || _companyId == null || _companyId!.isEmpty) return;

    try {
      final areas = snap.exists
          ? _parseAreasList(_firestoreDataAsMap(snap.data()))
          : <String>[];
      if (_sameAreasList(areas, _focusAreas)) return;
      await _refreshAreasAndGoalsFromFirestore();
    } catch (_) {
      // Listener errors are non-fatal; initial load already surfaced issues.
    }
  }

  void _replaceControllersForAreas(
    List<String> areas,
    Map<String, dynamic> perArea,
  ) {
    _disposeControllers();
    _focusAreas = List<String>.from(areas);
    for (final area in _focusAreas) {
      final saved = perArea[area];
      Map<String, dynamic>? row;
      if (saved is Map) {
        row = Map<String, dynamic>.from(saved);
      }
      _goalByArea[area] =
          TextEditingController(text: row?['goal']?.toString() ?? '')
            ..addListener(_scheduleAutoSave);
      final list = List<String>.from(row?['initiatives'] ?? const []);
      while (list.length < 3) {
        list.add('');
      }
      _initiativeByArea[area] = [
        for (final text in list)
          TextEditingController(text: text)..addListener(_scheduleAutoSave),
      ];
    }
  }

  void _disposeControllers() {
    for (final c in _goalByArea.values) {
      c.dispose();
    }
    for (final list in _initiativeByArea.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    _goalByArea.clear();
    _initiativeByArea.clear();
  }

  @override
  void dispose() {
    _strategicAreasSubscription?.cancel();
    if (_sessionAreasListener != null) {
      StrategicAreasSessionCache.areasNotifier
          .removeListener(_sessionAreasListener!);
    }
    _autoSave.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _scheduleAutoSave() {
    _autoSave.schedule(
      () => _save(silent: true),
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

  Future<void> _save({bool silent = false}) async {
    if (_companyId == null || _companyId!.isEmpty) return;
    if (_focusAreas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save strategic areas in Step #3 first.'),
          ),
        );
      }
      return;
    }

    final perAreaGoals = <String, dynamic>{};
    for (final area in _focusAreas) {
      final goal = _goalByArea[area]?.text.trim() ?? '';
      final inits = _initiativeByArea[area] ?? [];
      final initiatives = <String>[
        for (var i = 0; i < 3; i++)
          i < inits.length ? inits[i].text.trim() : '',
      ];
      perAreaGoals[area] = {
        'goal': goal,
        'initiatives': initiatives,
      };
    }

    try {
      if (skipFirebasePersistence) {
        final cached = <String, AreaGoalsData>{};
        for (final area in _focusAreas) {
          final row = perAreaGoals[area];
          if (row is! Map) continue;
          final inits = row['initiatives'];
          cached[area] = AreaGoalsData(
            goal: (row['goal'] ?? '').toString(),
            initiatives: inits is List
                ? inits.map((e) => e?.toString() ?? '').toList()
                : <String>[],
          );
        }
        GoalsSessionCache.save(cached);
        await PlanProgressService.cacheProgress(_companyId!);
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goals and initiatives saved')),
          );
        }
        return;
      }
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_companyId)
          .collection('yearOnePlan')
          .doc('goalsAndInitiatives')
          .set(
            {
              'perAreaGoals': perAreaGoals,
              'perAreaGoalsUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
      await PlanProgressService.cacheProgress(_companyId!);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals and initiatives saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_loadError!, style: TextStyle(color: Colors.red.shade700)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Develop goals & initiatives for each focus area',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AutoSaveStatusChip(
                    state: _saveState,
                    errorMessage: _saveError,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _focusAreas.isEmpty
                              ? 'No strategic areas yet. Go to Step #3 → Strategic Areas, choose 3–5 focus areas, and tap Save & Continue. Saved areas transfer here automatically (including while this page is open).'
                              : 'Sections below match your saved strategic areas from Step #3. When that list changes and saves, this screen updates. Add one goal and two or three initiatives per area (leave initiative 3 blank if you only need two).',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_focusAreas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                children: [
                  for (var i = 0; i < _focusAreas.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _AreaGoalCard(
                      areaTitle: _focusAreas[i],
                      goalController: _goalByArea[_focusAreas[i]]!,
                      initiativeControllers: _initiativeByArea[_focusAreas[i]]!,
                    ),
                  ],
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _focusAreas.isEmpty
                      ? null
                      : () async {
                          await _save();
                          if (!mounted) return;
                          await widget.onSaveAndContinue?.call();
                        },
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
        ],
      ),
    );
  }
}

class _AreaGoalCard extends StatelessWidget {
  const _AreaGoalCard({
    required this.areaTitle,
    required this.goalController,
    required this.initiativeControllers,
  });

  final String areaTitle;
  final TextEditingController goalController;
  final List<TextEditingController> initiativeControllers;

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: Colors.green.shade700, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    areaTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: goalController,
              maxLines: 3,
              decoration: _decoration(
                'Goal for this area',
                hint: 'One clear goal aligned with this function…',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Initiatives (2–3)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < initiativeControllers.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              TextField(
                controller: initiativeControllers[i],
                maxLines: 2,
                decoration: _decoration(
                  'Initiative ${i + 1}',
                  hint: i == 2 ? 'Optional third initiative' : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
