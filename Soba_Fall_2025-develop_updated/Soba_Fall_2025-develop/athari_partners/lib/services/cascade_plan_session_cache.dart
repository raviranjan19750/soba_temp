/// In-memory cascade plan for local dev when Firebase persistence is skipped.
class CascadePlanSessionCache {
  CascadePlanSessionCache._();

  static final Map<String, String> headNames = {};
  static Map<String, Map<String, List<Map<String, String>>>> cascadeByDept = {};

  static void update({
    Map<String, String>? heads,
    Map<String, Map<String, List<Map<String, String>>>>? cascade,
  }) {
    if (heads != null) {
      headNames
        ..clear()
        ..addAll(heads);
    }
    if (cascade != null) {
      cascadeByDept = cascade.map(
        (dept, areas) => MapEntry(
          dept,
          areas.map(
            (area, items) => MapEntry(
              area,
              items.map((e) => Map<String, String>.from(e)).toList(),
            ),
          ),
        ),
      );
    }
  }

  static void clear() {
    headNames.clear();
    cascadeByDept = {};
  }
}
