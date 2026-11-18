import 'package:flutter/material.dart';
import 'auth_config.dart';
import 'services/goals_session_cache.dart';
import 'services/initiative_metric_suggestions.dart';
import 'services/kpi_dashboard_tracking.dart';
import 'services/plan_progress_service.dart';
import 'services/strategic_areas_session_cache.dart';
import 'widgets/dashboard_tracking_table.dart';
import 'widgets/quarterly_review_schedule.dart';

/// Step 5 execution dashboard — goals, initiatives, key metrics, quarterly tracking.
class KpisDashboardPage extends StatefulWidget {
  const KpisDashboardPage({
    super.key,
    this.onProgressChanged,
  });

  final VoidCallback? onProgressChanged;

  @override
  State<KpisDashboardPage> createState() => _KpisDashboardPageState();
}

class _KpisDashboardPageState extends State<KpisDashboardPage> {
  String? companyId;
  bool loading = true;
  String? _loadError;
  List<DashboardAreaGroup> _trackingGroups = [];
  VoidCallback? _sessionDataListener;
  bool _saving = false;
  int _activeQuarter = dashboardCurrentQuarter();
  final Map<String, TextEditingController> _controllers = {};
  bool _suggestingAllMetrics = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (skipFirebasePersistence) {
      _sessionDataListener = () {
        if (mounted) _loadData(showSpinner: false);
      };
      StrategicAreasSessionCache.areasNotifier
          .addListener(_sessionDataListener!);
      GoalsSessionCache.goalsNotifier.addListener(_sessionDataListener!);
    }
  }

  @override
  void dispose() {
    if (_sessionDataListener != null) {
      StrategicAreasSessionCache.areasNotifier
          .removeListener(_sessionDataListener!);
      GoalsSessionCache.goalsNotifier.removeListener(_sessionDataListener!);
    }
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  void _bindControllers(List<DashboardAreaGroup> groups) {
    _disposeControllers();
    for (final group in groups) {
      for (final row in group.rows) {
        for (final field in const [
          'measures',
          'owner',
          'q1Target',
          'q2Target',
          'q3Target',
          'q4Target',
          'q1',
          'q2',
          'q3',
          'q4',
          'fullYear',
        ]) {
          final key = DashboardTrackingTable.controllerKey(row, field);
          _controllers[key] = TextEditingController(
            text: _readField(row, field),
          );
        }
      }
    }
  }

  String _readField(DashboardTrackingRow row, String field) {
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

  DashboardTrackingRow _rowFromControllers(DashboardTrackingRow row) {
    String read(String field) =>
        _controllers[DashboardTrackingTable.controllerKey(row, field)]
            ?.text
            .trim() ??
        '';

    final q1Target = read('q1Target');
    return row.copyWith(
      measures: read('measures'),
      targets: q1Target,
      owner: read('owner'),
      q1Target: q1Target,
      q2Target: read('q2Target'),
      q3Target: read('q3Target'),
      q4Target: read('q4Target'),
      q1: read('q1'),
      q2: read('q2'),
      q3: read('q3'),
      q4: read('q4'),
      fullYear: read('fullYear'),
    ).withComputedYtd();
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        loading = true;
        _loadError = null;
      });
    }
    try {
      companyId = await loadCompanyIdForCurrentUser();
      if (companyId == null || companyId!.isEmpty) {
        if (mounted) {
          setState(() {
            _trackingGroups = [];
            loading = false;
            _loadError =
                'Company workspace not loaded. Sign in again or finish setup.';
          });
        }
        return;
      }
      final groups = await KpiDashboardTrackingService.loadGroups(companyId);
      if (mounted) {
        _bindControllers(groups);
        setState(() {
          _trackingGroups = groups;
          loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _trackingGroups = [];
          loading = false;
          _loadError = 'Could not load dashboard. Tap retry.';
        });
      }
    }
  }

  Future<void> _save() async {
    if (companyId == null || _trackingGroups.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = _trackingGroups
          .map(
            (group) => DashboardAreaGroup(
              area: group.area,
              goal: group.goal,
              rows: group.rows.map(_rowFromControllers).toList(),
            ),
          )
          .toList();

      await KpiDashboardTrackingService.saveGroups(companyId!, updated);
      if (!skipFirebasePersistence) {
        await PlanProgressService.cacheProgress(companyId!);
      }
      widget.onProgressChanged?.call();
      if (!mounted) return;
      await _loadData(showSpinner: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Q$_activeQuarter dashboard saved'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _aiSuggestionsEnabled => aiSuggestionsEnabled;

  Future<void> _applyMetric(DashboardTrackingRow row, String metric) async {
    final key = DashboardTrackingTable.controllerKey(row, 'measures');
    _controllers[key]?.text = metric;
    if (mounted) setState(() {});
  }

  Future<void> _showMetricPicker(DashboardTrackingRow row) async {
    final suggestions = InitiativeMetricSuggestions.suggest(
      area: row.area,
      goal: row.goal,
      initiative: row.initiative,
    );
    if (!mounted) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _MetricSuggestionSheet(
        initiative: row.initiative,
        suggestions: suggestions,
        aiEnabled: _aiSuggestionsEnabled,
        onAiSuggest: () => InitiativeMetricSuggestions.suggestWithAi(
          area: row.area,
          goal: row.goal,
          initiative: row.initiative,
        ),
      ),
    );

    if (picked != null && picked.isNotEmpty) {
      await _applyMetric(row, picked);
    }
  }

  Future<void> _suggestAllMetrics() async {
    setState(() => _suggestingAllMetrics = true);
    var count = 0;
    for (final group in _trackingGroups) {
      for (final row in group.rows) {
        final key = DashboardTrackingTable.controllerKey(row, 'measures');
        final controller = _controllers[key];
        if (controller == null || controller.text.trim().isNotEmpty) continue;
        controller.text = InitiativeMetricSuggestions.primarySuggestion(
          area: row.area,
          goal: group.goal,
          initiative: row.initiative,
        );
        count++;
      }
    }
    if (!mounted) return;
    setState(() => _suggestingAllMetrics = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'All initiatives already have metrics defined'
              : 'Suggested metrics for $count initiative${count == 1 ? '' : 's'}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final currentYear = DateTime.now().year;
    final hasRows = _trackingGroups.any((g) => g.rows.isNotEmpty);

    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          if (_loadError != null) ...[
            _ErrorBanner(message: _loadError!, onRetry: () => _loadData()),
            const SizedBox(height: 12),
          ],
          _DashboardHeader(
            currentYear: currentYear,
            activeQuarter: _activeQuarter,
            hasRows: hasRows,
            onQuarterChanged: (q) => setState(() => _activeQuarter = q),
            onSuggestAllMetrics: hasRows ? _suggestAllMetrics : null,
            suggestingAllMetrics: _suggestingAllMetrics,
          ),
          const SizedBox(height: 12),
          if (!hasRows)
            _EmptyDashboard(
              message: _loadError ??
                  'Save strategic areas in Step 3 and Year 1 goals in Step 4. '
                      'This dashboard fills automatically with one row per initiative.',
            )
          else
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DashboardTrackingTable(
                  groups: _trackingGroups,
                  currentYear: currentYear,
                  activeQuarter: _activeQuarter,
                  editable: true,
                  controllers: _controllers,
                  onSuggestMetric: _showMetricPicker,
                ),
              ),
            ),
          if (hasRows && companyId != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving…' : 'Save Q$_activeQuarter dashboard'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          QuarterlyReviewScheduleSection(companyId: companyId),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.currentYear,
    required this.activeQuarter,
    required this.hasRows,
    required this.onQuarterChanged,
    this.onSuggestAllMetrics,
    this.suggestingAllMetrics = false,
  });

  final int currentYear;
  final int activeQuarter;
  final bool hasRows;
  final ValueChanged<int> onQuarterChanged;
  final VoidCallback? onSuggestAllMetrics;
  final bool suggestingAllMetrics;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year 1 KPI dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          hasRows
              ? 'For each initiative, define the key metric and quarterly targets '
                  '(left). Each quarter, enter actual results in the blue columns '
                  'and update YTD actuals.'
              : 'Complete Steps 3–4 to pull in strategic areas, goals, and initiatives.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
        ),
        if (hasRows) ...[
          const SizedBox(height: 14),
          Text(
            'Working quarter — $currentYear',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...List.generate(4, (i) {
                final q = i + 1;
                final selected = q == activeQuarter;
                return ChoiceChip(
                  label: Text(
                    'Q$q',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => onQuarterChanged(q),
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 14,
                    vertical: 2,
                  ),
                );
              }),
              if (onSuggestAllMetrics != null)
                OutlinedButton.icon(
                  onPressed: suggestingAllMetrics ? null : onSuggestAllMetrics,
                  icon: suggestingAllMetrics
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined, size: 16),
                  label: Text(
                    isMobile ? 'Suggest metrics' : 'Suggest metrics for empty rows',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Q$activeQuarter target and actual columns are highlighted. '
            'Use the lightbulb in the Measures column for per-initiative suggestions. '
            'Scroll horizontally to see all quarters. YTD auto-fills from numeric '
            'quarterly actuals when left blank on save.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isError = message != null &&
        message!.contains('not loaded');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.table_chart_outlined,
            size: 44,
            color: isError ? const Color(0xFFB45309) : Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            isError ? 'Dashboard unavailable' : 'No goals or initiatives yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                'Save strategic areas in Step 3 and Year 1 goals in Step 4. '
                    'This dashboard fills automatically with one row per initiative.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF9A3412), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MetricSuggestionSheet extends StatefulWidget {
  const _MetricSuggestionSheet({
    required this.initiative,
    required this.suggestions,
    required this.aiEnabled,
    required this.onAiSuggest,
  });

  final String initiative;
  final List<String> suggestions;
  final bool aiEnabled;
  final Future<String?> Function() onAiSuggest;

  @override
  State<_MetricSuggestionSheet> createState() => _MetricSuggestionSheetState();
}

class _MetricSuggestionSheetState extends State<_MetricSuggestionSheet> {
  bool _aiLoading = false;
  String? _aiSuggestion;
  String? _aiError;

  Future<void> _loadAiSuggestion() async {
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    final result = await widget.onAiSuggest();
    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      if (result != null && result.trim().isNotEmpty) {
        _aiSuggestion = result.trim();
      } else {
        _aiError = 'AI suggestion unavailable. Pick an option below.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initiativeLabel = widget.initiative.trim().isEmpty
        ? 'this initiative'
        : widget.initiative.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Suggested metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a KPI to track: $initiativeLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            for (final metric in widget.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, metric),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_outlined,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          metric,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.aiEnabled) ...[
              const Divider(height: 24),
              if (_aiSuggestion != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, _aiSuggestion),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      backgroundColor: const Color(0xFFEFF6FF),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _aiSuggestion!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _aiLoading ? null : _loadAiSuggestion,
                icon: _aiLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_outlined, size: 18),
                label: Text(
                  _aiSuggestion == null
                      ? 'Generate AI suggestion'
                      : 'Regenerate AI suggestion',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (_aiError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _aiError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
