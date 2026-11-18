import 'package:flutter/material.dart';

/// Shared layout tokens for the marketing landing page.
abstract final class LandingTheme {
  static const accent = Color(0xFF2E7D32);
  static const accentDeep = Color(0xFF1B5E20);
  static const mobileBreakpoint = 768.0;
  static const maxContentWidth = 1100.0;
  static const footerBg = Color(0xFF1F2937);

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;
}
