import 'package:athari_partners/services/strategic_areas_repository.dart';
import 'package:flutter/foundation.dart';

/// In-memory Step 4 goals for local dev when Firebase persistence is skipped.
class GoalsSessionCache {
  GoalsSessionCache._();

  static final ValueNotifier<Map<String, AreaGoalsData>> goalsNotifier =
      ValueNotifier<Map<String, AreaGoalsData>>({});

  static Map<String, AreaGoalsData> get perAreaGoals =>
      Map<String, AreaGoalsData>.from(goalsNotifier.value);

  static void save(Map<String, AreaGoalsData> goals) {
    goalsNotifier.value = Map<String, AreaGoalsData>.from(goals);
  }

  static void clear() {
    goalsNotifier.value = {};
  }
}
