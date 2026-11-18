import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth_config.dart';
import 'kpi_dashboard_session_cache.dart';

class QuarterlyReviewEntry {
  const QuarterlyReviewEntry({
    required this.quarterKey,
    required this.quarterLabel,
    required this.reviewDate,
    required this.participants,
    required this.focusAreas,
  });

  final String quarterKey;
  final String quarterLabel;
  final String reviewDate;
  final String participants;
  final String focusAreas;

  QuarterlyReviewEntry copyWith({
    String? reviewDate,
    String? participants,
    String? focusAreas,
  }) {
    return QuarterlyReviewEntry(
      quarterKey: quarterKey,
      quarterLabel: quarterLabel,
      reviewDate: reviewDate ?? this.reviewDate,
      participants: participants ?? this.participants,
      focusAreas: focusAreas ?? this.focusAreas,
    );
  }

  Map<String, String> toMap() => {
        'reviewDate': reviewDate,
        'participants': participants,
        'focusAreas': focusAreas,
      };

  static QuarterlyReviewEntry fromMap({
    required String quarterKey,
    required String quarterLabel,
    Map<String, dynamic>? data,
  }) {
    String field(String key) => (data?[key] ?? '').toString().trim();
    return QuarterlyReviewEntry(
      quarterKey: quarterKey,
      quarterLabel: quarterLabel,
      reviewDate: field('reviewDate'),
      participants: field('participants'),
      focusAreas: field('focusAreas'),
    );
  }
}

class QuarterlyReviewScheduleService {
  QuarterlyReviewScheduleService._();

  static List<QuarterlyReviewEntry> defaultEntries([int? year]) {
    final y = year ?? DateTime.now().year;
    return [
      QuarterlyReviewEntry(
        quarterKey: 'q1',
        quarterLabel: 'Q1 $y',
        reviewDate: 'April 5, $y',
        participants: 'Leadership team, Department heads',
        focusAreas: 'Q1 performance, Q2 forecast, initiative updates',
      ),
      QuarterlyReviewEntry(
        quarterKey: 'q2',
        quarterLabel: 'Q2 $y',
        reviewDate: 'July 7, $y',
        participants: 'Leadership team, Department heads',
        focusAreas: 'Q2 performance, mid-year adjustments, H2 outlook',
      ),
      QuarterlyReviewEntry(
        quarterKey: 'q3',
        quarterLabel: 'Q3 $y',
        reviewDate: 'October 6, $y',
        participants: 'Leadership team, Department heads',
        focusAreas: 'Q3 performance, year-end forecast, strategic planning prep',
      ),
      QuarterlyReviewEntry(
        quarterKey: 'q4',
        quarterLabel: 'Q4 $y',
        reviewDate: 'January 11, ${y + 1}',
        participants: 'Leadership team, Department heads, Board',
        focusAreas: 'Annual performance review, Year 2 plan adjustments',
      ),
    ];
  }

  static List<QuarterlyReviewEntry> mergeWithDefaults(
    Map<String, Map<String, dynamic>> saved,
  ) {
    return defaultEntries().map((defaults) {
      final raw = saved[defaults.quarterKey];
      final merged = defaults.copyWith(
        reviewDate: _firstNonEmpty([
          if (raw != null) (raw['reviewDate'] ?? '').toString(),
          defaults.reviewDate,
        ]),
        participants: _firstNonEmpty([
          if (raw != null) (raw['participants'] ?? '').toString(),
          defaults.participants,
        ]),
        focusAreas: _firstNonEmpty([
          if (raw != null) (raw['focusAreas'] ?? '').toString(),
          defaults.focusAreas,
        ]),
      );
      return merged;
    }).toList();
  }

  static String _firstNonEmpty(List<String> candidates) {
    for (final c in candidates) {
      if (c.trim().isNotEmpty) return c.trim();
    }
    return '';
  }

  static Future<List<QuarterlyReviewEntry>> load(String? companyId) async {
    if (companyId == null || companyId.isEmpty) {
      return defaultEntries();
    }

    if (skipFirebasePersistence) {
      return mergeWithDefaults(KpiDashboardSessionCache.quarterlyReviewSchedule);
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('executeAndMonitor')
          .doc('kpisAndDashboard')
          .get();
      final raw = snap.data()?['quarterlyReviewSchedule'];
      if (raw is! Map) return defaultEntries();

      final saved = raw.map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map
              ? Map<String, dynamic>.from(value)
              : <String, dynamic>{},
        ),
      );
      return mergeWithDefaults(saved);
    } catch (_) {
      return defaultEntries();
    }
  }

  static Future<void> save(
    String companyId,
    List<QuarterlyReviewEntry> entries,
  ) async {
    final payload = {
      for (final entry in entries) entry.quarterKey: entry.toMap(),
    };

    if (skipFirebasePersistence) {
      KpiDashboardSessionCache.saveQuarterlyReviewSchedule(payload);
      return;
    }

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('kpisAndDashboard')
        .set({'quarterlyReviewSchedule': payload}, SetOptions(merge: true));
  }
}
