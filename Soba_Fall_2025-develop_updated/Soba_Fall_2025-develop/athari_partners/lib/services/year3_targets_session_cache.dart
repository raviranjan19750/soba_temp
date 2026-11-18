/// Step 3 financial targets for local dev when Firebase persistence is skipped.
class Year3TargetsSessionCache {
  Year3TargetsSessionCache._();

  static String y3Revenue = '';
  static String y3GrossMargin = '';
  static String y3Ebitda = '';
  static String y3Margin = '';
  static String y1Revenue = '';
  static String y1GrossMargin = '';
  static String y1Ebitda = '';
  static String y1Margin = '';
  static String y2Revenue = '';
  static String y2GrossMargin = '';
  static String y2Ebitda = '';
  static String y2Margin = '';

  static void update({
    String? y3Revenue,
    String? y3GrossMargin,
    String? y3Ebitda,
    String? y3Margin,
    String? y1Revenue,
    String? y1GrossMargin,
    String? y1Ebitda,
    String? y1Margin,
    String? y2Revenue,
    String? y2GrossMargin,
    String? y2Ebitda,
    String? y2Margin,
  }) {
    if (y3Revenue != null) Year3TargetsSessionCache.y3Revenue = y3Revenue;
    if (y3GrossMargin != null) {
      Year3TargetsSessionCache.y3GrossMargin = y3GrossMargin;
    }
    if (y3Ebitda != null) Year3TargetsSessionCache.y3Ebitda = y3Ebitda;
    if (y3Margin != null) Year3TargetsSessionCache.y3Margin = y3Margin;
    if (y1Revenue != null) Year3TargetsSessionCache.y1Revenue = y1Revenue;
    if (y1GrossMargin != null) {
      Year3TargetsSessionCache.y1GrossMargin = y1GrossMargin;
    }
    if (y1Ebitda != null) Year3TargetsSessionCache.y1Ebitda = y1Ebitda;
    if (y1Margin != null) Year3TargetsSessionCache.y1Margin = y1Margin;
    if (y2Revenue != null) Year3TargetsSessionCache.y2Revenue = y2Revenue;
    if (y2GrossMargin != null) {
      Year3TargetsSessionCache.y2GrossMargin = y2GrossMargin;
    }
    if (y2Ebitda != null) Year3TargetsSessionCache.y2Ebitda = y2Ebitda;
    if (y2Margin != null) Year3TargetsSessionCache.y2Margin = y2Margin;
  }
}
