/// In-memory KPI state for local dev when Firebase persistence is skipped.
class KpiDashboardSessionCache {
  KpiDashboardSessionCache._();

  static final Map<String, bool> checkboxValues = {};
  static Map<String, Map<String, dynamic>> initiativeTracking = {};
  static Map<String, Map<String, dynamic>> quarterlyReviewSchedule = {};

  static bool getValue(String id) => checkboxValues[id] ?? false;

  static void setValue(String id, bool value) {
    checkboxValues[id] = value;
  }

  static void saveInitiativeTracking(Map<String, Map<String, String>> data) {
    initiativeTracking = data.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  static void saveQuarterlyReviewSchedule(Map<String, Map<String, String>> data) {
    quarterlyReviewSchedule = data.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  static void clear() {
    checkboxValues.clear();
    initiativeTracking.clear();
    quarterlyReviewSchedule.clear();
  }
}
