import 'package:athari_partners/auth_config.dart';
import 'package:athari_partners/catalyst_planning_step_content.dart';
import 'package:athari_partners/catalyst_planning_step_detail_page.dart';
import 'package:athari_partners/index_screen.dart';
import 'package:athari_partners/landing/landing_demo_player.dart';
import 'package:athari_partners/landing/landing_lazy_section.dart';
import 'package:athari_partners/landing/landing_theme.dart';
import 'package:athari_partners/landing/landing_urls.dart';
import 'package:athari_partners/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_page.dart';

part 'landing/landing_nav.part.dart';
part 'landing/landing_hero.part.dart';
part 'landing/landing_methodology.part.dart';
part 'landing/landing_audience.part.dart';
part 'landing/landing_benefits.part.dart';
part 'landing/landing_pricing.part.dart';
part 'landing/landing_demo_cta.part.dart';
part 'landing/landing_footer.part.dart';

class MyCatalystPlanLandingPage extends StatefulWidget {
  final VoidCallback? onSignIn;
  final VoidCallback? onGetStarted;

  const MyCatalystPlanLandingPage({
    super.key,
    this.onSignIn,
    this.onGetStarted,
  });

  @override
  State<MyCatalystPlanLandingPage> createState() =>
      _MyCatalystPlanLandingPageState();
}

class _MyCatalystPlanLandingPageState extends State<MyCatalystPlanLandingPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);
  late AnimationController _animationController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _strategicPlanningSectionKey = GlobalKey();
  final GlobalKey _methodologyBreakdownKey = GlobalKey();
  final GlobalKey _whoItsForKey = GlobalKey();
  final GlobalKey _growthCatalystHqKey = GlobalKey();
  final GlobalKey _benefitsKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _watchDemoKey = GlobalKey();

  bool _isMobile(BuildContext context) => LandingTheme.isMobile(context);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_heroFade);
    _animationController.forward();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 50;
    if (scrolled != _isScrolled.value) {
      _isScrolled.value = scrolled;
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showMobileNavMenu(BuildContext context) {
    final items = <(String label, VoidCallback onTap)>[
      ('Methodology', () => _scrollToSection(_methodologyBreakdownKey)),
      ('Benefits', () => _scrollToSection(_benefitsKey)),
      ('Pricing', () => _scrollToSection(_pricingKey)),
      ('Watch Demo', () => _scrollToSection(_watchDemoKey)),
      ('Growth Catalyst HQ', () => _scrollToSection(_growthCatalystHqKey)),
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                ListTile(
                  title: Text(
                    item.$1,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    item.$2();
                  },
                ),
              if (authBypassEnabled)
                ListTile(
                  title: const Text(
                    'Open app',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleSignIn();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const IndexScreen()),
      (route) => false,
    );
  }

  void _handleSignIn() {
    if (widget.onSignIn != null) {
      widget.onSignIn!();
    } else if (authBypassEnabled) {
      _openApp();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _handleGetStarted() {
    if (widget.onGetStarted != null) {
      widget.onGetStarted!();
    } else if (authBypassEnabled) {
      _openApp();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  void _handleJoinCompany() {
    if (authBypassEnabled) {
      _openApp();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignupPage(joinExistingCompany: true),
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _isScrolled,
                builder: (context, isScrolled, _) =>
                    _buildNavigationBar(context, isScrolled),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Container(
                        key: _heroKey,
                        child: _buildHeroSection(context),
                      ),
                      Container(
                        key: _strategicPlanningSectionKey,
                        child: Column(
                          children: [
                            Container(
                              key: _methodologyBreakdownKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildStrategicPlanningIntroSection(context),
                                  _buildStrategicPlanningFiveStepsSection(context),
                                ],
                              ),
                            ),
                            LandingLazySection(
                              scrollController: _scrollController,
                              placeholderHeight: 520,
                              builder: (ctx) => Container(
                                key: _whoItsForKey,
                                child: _buildWhoItsForSection(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                      LandingLazySection(
                        scrollController: _scrollController,
                        placeholderHeight: 560,
                        builder: (ctx) => Container(
                          key: _benefitsKey,
                          child: _buildWhyChooseSection(ctx),
                        ),
                      ),
                      LandingLazySection(
                        scrollController: _scrollController,
                        placeholderHeight: 720,
                        builder: (ctx) => Container(
                          key: _pricingKey,
                          child: _buildPricingSection(ctx),
                        ),
                      ),
                      LandingLazySection(
                        scrollController: _scrollController,
                        placeholderHeight: 420,
                        builder: (ctx) => Container(
                          key: _watchDemoKey,
                          child: _buildWatchDemoSection(ctx),
                        ),
                      ),
                      LandingLazySection(
                        scrollController: _scrollController,
                        placeholderHeight: 380,
                        builder: (ctx) => _buildCTASection(ctx),
                      ),
                      LandingLazySection(
                        scrollController: _scrollController,
                        placeholderHeight: 480,
                        builder: (ctx) => Container(
                          key: _growthCatalystHqKey,
                          child: _buildGrowthCatalystHqSection(ctx),
                        ),
                      ),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isScrolled,
            builder: (context, isScrolled, _) {
              if (!isScrolled) return const SizedBox.shrink();
              return Positioned(
                right: 24,
                bottom: 24,
                child: _buildFloatingBackToTop(),
              );
            },
          ),
        ],
      ),
    );
  }
}
