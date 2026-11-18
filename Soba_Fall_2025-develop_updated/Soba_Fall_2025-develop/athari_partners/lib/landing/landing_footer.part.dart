part of '../landing_page.dart';

extension _LandingFooterPart on _MyCatalystPlanLandingPageState {
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
                          'GROWTH Catalyst HQ is the parent company. MyCatalystPlan is our software for developing, tracking, and sharing your strategic plan; our consulting arm helps you execute.',
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
                        _buildFooterLink('Pricing', () => _scrollToSection(_pricingKey)),
                        _buildFooterLink(
                          'Case Studies',
                          () => _launchExternalUrl(LandingUrls.caseStudies),
                        ),
                        _buildFooterLink('Resources', () => _scrollToSection(_methodologyBreakdownKey)),
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
                        _buildFooterLink('About Us', () => _scrollToSection(_growthCatalystHqKey)),
                        _buildFooterLink(
                          'Careers',
                          () => _launchExternalUrl(LandingUrls.careers),
                        ),
                        _buildFooterLink(
                          'Blog',
                          () => _launchExternalUrl(LandingUrls.blog),
                        ),
                        _buildFooterLink(
                          'Contact',
                          () => _launchExternalUrl(LandingUrls.contact),
                        ),
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
                        _buildFooterLink(
                          'Privacy Policy',
                          () => _launchExternalUrl(LandingUrls.privacy),
                        ),
                        _buildFooterLink(
                          'Terms of Service',
                          () => _launchExternalUrl(LandingUrls.terms),
                        ),
                        _buildFooterLink(
                          'Cookie Policy',
                          () => _launchExternalUrl(LandingUrls.cookies),
                        ),
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
                    'GROWTH Catalyst HQ is the parent company. MyCatalystPlan is our software for developing, tracking, and sharing your strategic plan; our consulting arm helps you execute.',
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
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Â© 2026 GROWTH Catalyst HQ. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: _footerSocialIcons(),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Â© 2026 GROWTH Catalyst HQ. All rights reserved.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          children: _footerSocialIcons(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

  List<Widget> _footerSocialIcons() {
      return [
        _buildSocialIcon(
          icon: Icons.facebook,
          label: 'Facebook',
          onPressed: () => _launchExternalUrl(LandingUrls.socialFacebook),
        ),
        _buildSocialIcon(
          icon: Icons.close,
          label: 'X',
          onPressed: () => _launchExternalUrl(LandingUrls.socialX),
        ),
        _buildSocialIconCustom(
          label: 'in',
          onPressed: () => _launchExternalUrl(LandingUrls.socialLinkedIn),
        ),
        _buildSocialIcon(
          icon: Icons.camera_alt,
          label: 'Instagram',
          onPressed: () => _launchExternalUrl(LandingUrls.socialInstagram),
        ),
        _buildSocialIconCustom(
          label: 'YT',
          onPressed: () => _launchExternalUrl(LandingUrls.socialYouTube),
        ),
        _buildSocialIcon(
          icon: Icons.play_arrow,
          label: 'TikTok',
          onPressed: () => _launchExternalUrl(LandingUrls.socialTikTok),
        ),
      ];
    }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
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
