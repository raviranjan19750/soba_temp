import 'package:flutter/foundation.dart';

/// In-memory bridge for Step 3 → Step 4 when Firebase persistence is skipped
/// (e.g. `BYPASS_AUTH=true` local dev).
class StrategicAreasSessionCache {
  StrategicAreasSessionCache._();

  static final ValueNotifier<List<String>> areasNotifier =
      ValueNotifier<List<String>>([]);

  static List<String> get areas => List<String>.from(areasNotifier.value);

  static void setAreas(List<String> list) {
    areasNotifier.value = List<String>.from(list);
  }

  static void clear() {
    areasNotifier.value = [];
  }
}
