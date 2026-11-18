/// Step 1 identity fields for local dev when Firebase persistence is skipped.
class IdentitySessionCache {
  IdentitySessionCache._();

  static String vision = '';
  static String mission = '';
  static String values = '';

  static void update({
    String? vision,
    String? mission,
    String? values,
  }) {
    if (vision != null) IdentitySessionCache.vision = vision;
    if (mission != null) IdentitySessionCache.mission = mission;
    if (values != null) IdentitySessionCache.values = values;
  }
}
