part of '../landing_page.dart';

extension _LandingNavPart on _MyCatalystPlanLandingPageState {
  Widget _buildFloatingBackToTop() {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LandingTheme.accent,
                LandingTheme.accentDeep,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LandingTheme.accent.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                );
              },
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildNavigationBar(BuildContext context, bool isScrolled) {
      final isMobile = _isMobile(context);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: isScrolled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Logo - Clickable (flex so long subtitle can ellipsize on narrow desktop widths)
            Flexible(
              flex: 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _scrollToSection(_heroKey),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2E7D32),
                              Color(0xFF1B5E20),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_graph_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.35,
                                  color: Colors.white,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            Text(
                              'A product of GROWTH Catalyst HQ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (!isMobile) ...[
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavItem(
                          'Methodology',
                          () => _scrollToSection(_methodologyBreakdownKey),
                        ),
                        const SizedBox(width: 16),
                        _buildNavItem('Benefits', () => _scrollToSection(_benefitsKey)),
                        const SizedBox(width: 16),
                        _buildNavItem('Pricing', () => _scrollToSection(_pricingKey)),
                        const SizedBox(width: 16),
                        _buildNavItem('Watch Demo', () => _scrollToSection(_watchDemoKey)),
                        const SizedBox(width: 16),
                        _buildNavItem(
                          'Growth Catalyst HQ',
                          () => _scrollToSection(_growthCatalystHqKey),
                        ),
                        const SizedBox(width: 16),
                        if (authBypassEnabled)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: InkWell(
                              onTap: _handleSignIn,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: const Text(
                                  'Open app',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Menu',
                onPressed: () => _showMobileNavMenu(context),
                icon: const Icon(Icons.menu_rounded),
                color: Colors.grey.shade800,
              ),
              const Spacer(),
            ],

            if (!authBypassEnabled) ...[
              TextButton(
                onPressed: _handleSignIn,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 2 : 4),
              TextButton(
                onPressed: _handleJoinCompany,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  isMobile ? 'Join' : 'Join company',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 4 : 8),
            ],

            // Get Started Button
            ElevatedButton(
              onPressed: _handleGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  Widget _buildNavItem(String text, VoidCallback onTap) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
}

