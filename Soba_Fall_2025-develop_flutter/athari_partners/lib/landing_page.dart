  import 'package:athari_partners/signup_page.dart';
import 'package:flutter/material.dart';
  import 'package:flutter/gestures.dart';

  import 'login_page.dart';

  class AthariLandingPage extends StatefulWidget {
    final VoidCallback? onSignIn;
    final VoidCallback? onGetStarted;

    const AthariLandingPage({
      Key? key,
      this.onSignIn,
      this.onGetStarted,
    }) : super(key: key);

    @override
    State<AthariLandingPage> createState() => _AthariLandingPageState();
  }

  class _AthariLandingPageState extends State<AthariLandingPage> with SingleTickerProviderStateMixin {
    final ScrollController _scrollController = ScrollController();
    late AnimationController _animationController;
    bool _isScrolled = false;

    // Keys for each section
    final GlobalKey _heroKey = GlobalKey();
    final GlobalKey _featuresKey = GlobalKey();
    final GlobalKey _benefitsKey = GlobalKey();
    final GlobalKey _testimonialsKey = GlobalKey();

    @override
    void initState() {
      super.initState();
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..forward();

      _scrollController.addListener(() {
        if (_scrollController.offset > 50 && !_isScrolled) {
          setState(() => _isScrolled = true);
        } else if (_scrollController.offset <= 50 && _isScrolled) {
          setState(() => _isScrolled = false);
        }
      });
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

    @override
    void dispose() {
      _scrollController.dispose();
      _animationController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Navigation Bar
                  _buildNavigationBar(context),

                  // Hero Section
                  Container(key: _heroKey, child: _buildHeroSection(context)),

                  // Features Section
                  Container(key: _featuresKey, child: _buildFeaturesSection(context)),

                  // Why Choose Section (Benefits)
                  Container(key: _benefitsKey, child: _buildWhyChooseSection(context)),

                  // Testimonials Section
                  Container(key: _testimonialsKey, child: _buildTestimonialsSection(context)),

                  // CTA Section
                  _buildCTASection(context),

                  // Footer
                  _buildFooter(context),
                ],
              ),
            ),

            // Floating Back to Top Button
            if (_isScrolled)
              Positioned(
                right: 24,
                bottom: 24,
                child: _buildFloatingBackToTop(),
              ),
          ],
        ),
      );
    }

    Widget _buildFloatingBackToTop() {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedOpacity(
          opacity: _isScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5B6FED),
                  Color(0xFF4054D0),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B6FED).withOpacity(0.4),
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
        ),
      );
    }

    Widget _buildNavigationBar(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: _isScrolled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo - Clickable
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _scrollToSection(_heroKey),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF5B6FED),
                            Color(0xFF4054D0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B6FED).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ATHARI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'PARTNERS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Navigation Items
            if (!isMobile) ...[
              _buildNavItem('Features', () => _scrollToSection(_featuresKey)),
              const SizedBox(width: 32),
              _buildNavItem('Benefits', () => _scrollToSection(_benefitsKey)),
              const SizedBox(width: 32),
              _buildNavItem('Testimonials', () => _scrollToSection(_testimonialsKey)),
              const SizedBox(width: 32),

              // Sign In Button - Fixed
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: widget.onSignIn ?? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],

// Get Started Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B6FED),
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

    Widget _buildHeroSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: isMobile ? 60 : 120,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: FadeTransition(
          opacity: _animationController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            )),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B6FED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF5B6FED).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B6FED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Strategic Planning Made Simple',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5B6FED),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isMobile ? 40 : 64,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Transform Your Business\n',
                        style: TextStyle(color: Colors.grey.shade900),
                      ),
                      const TextSpan(
                        text: 'With Strategic Planning',
                        style: TextStyle(color: Color(0xFF5B6FED)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Subtitle
                Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    'Athari Partners helps you create, execute, and monitor strategic plans that drive real results. Turn your vision into actionable goals with our proven framework.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 17 : 21,
                      color: Colors.grey.shade700,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
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
                      onPressed: widget.onGetStarted ?? () {},
                      icon: Icons.rocket_launch,
                    ),
                    _buildSecondaryButton(
                      text: 'Watch Demo',
                      onPressed: () {},
                      icon: Icons.play_circle_outline,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Trust indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'No credit card required',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '14-day free trial',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Stats
                Wrap(
                  spacing: 48,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatItem('500+', 'Active Companies'),
                    _buildStatItem('95%', 'Goal Achievement'),
                    _buildStatItem('40%', 'Revenue Growth'),
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
            backgroundColor: const Color(0xFF5B6FED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 18,
            ),
            elevation: 0,
            shadowColor: const Color(0xFF5B6FED).withOpacity(0.4),
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
            foregroundColor: const Color(0xFF5B6FED),
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

    Widget _buildStatItem(String value, String label) {
      return Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5B6FED),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }

    Widget _buildFeaturesSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 80,
        ),
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            Text(
              'Everything You Need for Strategic Success',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 28 : 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Powerful tools to plan, execute, and monitor your strategy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 60),

            // Feature Cards
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.hub_outlined,
                          iconColor: const Color(0xFF5B6FED),
                          bgColor: const Color(0xFFE8EFFF),
                          title: 'Strategic Planning',
                          description: 'Define clear objectives and create actionable plans aligned with your company\'s vision and mission.',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.trending_up,
                          iconColor: const Color(0xFF4CAF50),
                          bgColor: const Color(0xFFE8F5E9),
                          title: 'Progress Tracking',
                          description: 'Monitor KPIs and milestones in real-time with intuitive dashboards and automated reporting.',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF9C27B0),
                          bgColor: const Color(0xFFF3E5F5),
                          title: 'Team Collaboration',
                          description: 'Align your entire organization with shared goals and transparent communication tools.',
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildFeatureCard(
                        icon: Icons.hub_outlined,
                        iconColor: const Color(0xFF5B6FED),
                        bgColor: const Color(0xFFE8EFFF),
                        title: 'Strategic Planning',
                        description: 'Define clear objectives and create actionable plans aligned with your company\'s vision and mission.',
                      ),
                      const SizedBox(height: 24),
                      _buildFeatureCard(
                        icon: Icons.trending_up,
                        iconColor: const Color(0xFF4CAF50),
                        bgColor: const Color(0xFFE8F5E9),
                        title: 'Progress Tracking',
                        description: 'Monitor KPIs and milestones in real-time with intuitive dashboards and automated reporting.',
                      ),
                      const SizedBox(height: 24),
                      _buildFeatureCard(
                        icon: Icons.people_outline,
                        iconColor: const Color(0xFF9C27B0),
                        bgColor: const Color(0xFFF3E5F5),
                        title: 'Team Collaboration',
                        description: 'Align your entire organization with shared goals and transparent communication tools.',
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    Widget _buildFeatureCard({
      required IconData icon,
      required Color iconColor,
      required Color bgColor,
      required String title,
      required String description,
    }) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: bgColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor,
                      iconColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildWhyChooseSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 80,
        ),
        child: Row(
          children: [
            // Left side - Benefits
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Choose Athari Partners?',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildBenefitItem(
                    'Proven Framework',
                    'Built on industry best practices and tested by hundreds of successful companies.',
                  ),
                  const SizedBox(height: 24),
                  _buildBenefitItem(
                    'Easy to Use',
                    'Intuitive interface designed for business leaders, not technical experts.',
                  ),
                  const SizedBox(height: 24),
                  _buildBenefitItem(
                    'Real-Time Insights',
                    'Make data-driven decisions with live dashboards and analytics.',
                  ),
                  const SizedBox(height: 24),
                  _buildBenefitItem(
                    'Expert Support',
                    'Access to strategic planning experts whenever you need guidance.',
                  ),
                ],
              ),
            ),

            if (!isMobile) ...[
              const SizedBox(width: 60),

              // Right side - CTA Card
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5B6FED),
                        Color(0xFF4054D0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join 500+ Companies Growing with Us',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Start your strategic planning journey today and see measurable results in weeks, not months.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5B6FED),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Get Started Free',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget _buildBenefitItem(String title, String description) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildTestimonialsSection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 80,
        ),
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            Text(
              'Trusted by Leading Companies',
              style: TextStyle(
                fontSize: isMobile ? 28 : 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'See what our clients say about their success',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 60),

            // Testimonials
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTestimonialCard(
                          initials: 'JD',
                          name: 'John Davis',
                          role: 'CEO, TechCorp',
                          color: const Color(0xFF5B6FED),
                          testimonial: '"Athari Partners transformed how we approach strategic planning. We\'ve seen a 40% increase in goal achievement since implementing their system."',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTestimonialCard(
                          initials: 'SM',
                          name: 'Sarah Miller',
                          role: 'COO, GrowthCo',
                          color: const Color(0xFF4CAF50),
                          testimonial: '"The clarity and alignment we\'ve achieved across our organization is remarkable. This platform is a game-changer."',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTestimonialCard(
                          initials: 'MR',
                          name: 'Mike Roberts',
                          role: 'VP Strategy, InnovateLabs',
                          color: const Color(0xFF9C27B0),
                          testimonial: '"Finally, a strategic planning tool that our entire team actually uses. The ROI has been incredible."',
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTestimonialCard(
                        initials: 'JD',
                        name: 'John Davis',
                        role: 'CEO, TechCorp',
                        color: const Color(0xFF5B6FED),
                        testimonial: '"Athari Partners transformed how we approach strategic planning. We\'ve seen a 40% increase in goal achievement since implementing their system."',
                      ),
                      const SizedBox(height: 24),
                      _buildTestimonialCard(
                        initials: 'SM',
                        name: 'Sarah Miller',
                        role: 'COO, GrowthCo',
                        color: const Color(0xFF4CAF50),
                        testimonial: '"The clarity and alignment we\'ve achieved across our organization is remarkable. This platform is a game-changer."',
                      ),
                      const SizedBox(height: 24),
                      _buildTestimonialCard(
                        initials: 'MR',
                        name: 'Mike Roberts',
                        role: 'VP Strategy, InnovateLabs',
                        color: const Color(0xFF9C27B0),
                        testimonial: '"Finally, a strategic planning tool that our entire team actually uses. The ROI has been incredible."',
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    Widget _buildTestimonialCard({
      required String initials,
      required String name,
      required String role,
      required Color color,
      required String testimonial,
    }) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars rating
            Row(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star,
                    size: 18,
                    color: Colors.amber.shade600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              testimonial,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildCTASection(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 80,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 32 : 80,
          vertical: isMobile ? 60 : 100,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B6FED),
              Color(0xFF4054D0),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B6FED).withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🚀 Ready to Get Started?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Transform Your Strategy Today',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 36 : 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'Join hundreds of companies achieving their strategic goals with Athari Partners. Start your journey to success today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 17 : 20,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 48),

            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: widget.onGetStarted ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5B6FED),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 32 : 48,
                    vertical: isMobile ? 20 : 24,
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Your Free Trial Today',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  'No credit card required',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cancel anytime',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildFooter(BuildContext context) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 40,
        ),
        color: const Color(0xFF1F2937),
        child: Column(
          children: [
            // Footer Content
            if (!isMobile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Description
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.business,
                            size: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Empowering businesses with strategic planning excellence.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product Links
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFooterLink('Features'),
                        _buildFooterLink('Pricing'),
                        _buildFooterLink('Case Studies'),
                        _buildFooterLink('Resources'),
                      ],
                    ),
                  ),

                  // Company Links
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFooterLink('About Us'),
                        _buildFooterLink('Careers'),
                        _buildFooterLink('Blog'),
                        _buildFooterLink('Contact'),
                      ],
                    ),
                  ),

                  // Legal Links
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Legal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFooterLink('Privacy Policy'),
                        _buildFooterLink('Terms of Service'),
                        _buildFooterLink('Cookie Policy'),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Mobile Footer
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Empowering businesses with strategic planning excellence.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),

            // Footer Bottom
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade700,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2025 Athari Partners. All rights reserved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),

                  // Social Media Icons
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildSocialIcon(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onPressed: () {},
                      ),
                      _buildSocialIcon(
                        icon: Icons.close, // X/Twitter
                        label: 'X',
                        onPressed: () {},
                      ),
                      _buildSocialIconCustom(
                        label: 'in', // LinkedIn
                        onPressed: () {},
                      ),
                      _buildSocialIcon(
                        icon: Icons.camera_alt, // Instagram
                        label: 'Instagram',
                        onPressed: () {},
                      ),
                      _buildSocialIconCustom(
                        label: 'YT', // YouTube
                        onPressed: () {},
                      ),
                      _buildSocialIcon(
                        icon: Icons.play_arrow, // TikTok
                        label: 'TikTok',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildFooterLink(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {},
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      );
    }

    Widget _buildSocialIcon({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: label,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(18),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildSocialIconCustom({
      required String label,
      required VoidCallback onPressed,
    }) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: label == 'in' ? 'LinkedIn' : label == 'YT' ? 'YouTube' : label,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(18),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // Example usage
  class AthariLandingScreen extends StatelessWidget {
    const AthariLandingScreen({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return AthariLandingPage(
        onSignIn: () {
          // Navigate to LoginPage when Sign In is clicked
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        },
        onGetStarted: () {
          // Handle get started navigation
          print('Navigate to Get Started');
        },
      );
    }
  }

