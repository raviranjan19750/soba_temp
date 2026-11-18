part of '../landing_page.dart';

extension _LandingHeroPart on _MyCatalystPlanLandingPageState {
  Widget _buildHeroSection(BuildContext context) {
      final isMobile = _isMobile(context);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: isMobile ? 60 : 120,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: FadeTransition(
          opacity: _heroFade,
          child: SlideTransition(
            position: _heroSlide,
            child: Column(
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF1B5E20),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'MyCatalystPlan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Strategic planning software from GROWTH Catalyst HQ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Tag line
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isMobile ? 30 : 46,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                      letterSpacing: -0.8,
                    ),
                    children: [
                      TextSpan(
                        text: "Stop guessing. Great companies don't stumble into growth.\n",
                        style: TextStyle(color: Colors.grey.shade900),
                      ),
                      const TextSpan(
                        text: 'They plan it.',
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Hero description
                Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.grey.shade700,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: 'MyCatalystPlan',
                          style: TextStyle(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' is built for leadership teams serious about growth. A proven 5-step system that turns ambition into a '
                              'focused, executable strategy and keeps the whole organization moving toward it.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48),

                // Action Buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildPrimaryButton(
                      text: 'Start Your Free Trial',
                      onPressed: _handleGetStarted,
                      icon: Icons.rocket_launch,
                    ),
                    _buildSecondaryButton(
                      text: 'Watch Demo',
                      onPressed: () => _scrollToSection(_watchDemoKey),
                      icon: Icons.play_circle_outline,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (!authBypassEnabled) ...[
                  TextButton.icon(
                    onPressed: _handleJoinCompany,
                    icon: const Icon(Icons.group_add_outlined, size: 20),
                    label: const Text(
                      'Have an invite code? Join your team\'s company',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _handleSignIn,
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Trust indicators (wrap on narrow widths)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'No credit card to start',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          '14-day trial on paid tiers',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildPrimaryButton({
      required String text,
      required VoidCallback onPressed,
      required IconData icon,
    }) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 18,
            ),
            elevation: 0,
            shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 20),
            ],
          ),
        ),
      );
    }

  Widget _buildSecondaryButton({
      required String text,
      required VoidCallback onPressed,
      required IconData icon,
    }) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }
}

