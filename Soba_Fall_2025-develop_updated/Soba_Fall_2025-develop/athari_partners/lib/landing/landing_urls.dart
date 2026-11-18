/// External links for the marketing landing page.
abstract final class LandingUrls {
  static const site = 'https://www.growthcatalysthq.com';
  static const contact = 'mailto:hello@growthcatalysthq.com';
  static const privacy = 'https://www.growthcatalysthq.com/privacy-policy';
  static const terms = 'https://www.growthcatalysthq.com/terms-of-service';
  static const cookies = 'https://www.growthcatalysthq.com/cookie-policy';
  static const blog = 'https://www.growthcatalysthq.com/blog';
  static const careers = 'https://www.growthcatalysthq.com/careers';
  static const caseStudies = 'https://www.growthcatalysthq.com/case-studies';

  /// YouTube video id for the product walkthrough (web embed + external link).
  /// Replace when your official demo is published.
  static const demoVideoId = 'LXb3EKGiInQ';

  static String get demoWatchUrl =>
      'https://www.youtube.com/watch?v=$demoVideoId';

  static String get demoEmbedUrl =>
      'https://www.youtube.com/embed/$demoVideoId?rel=0&modestbranding=1';

  static String get demoThumbnailUrl =>
      'https://img.youtube.com/vi/$demoVideoId/hqdefault.jpg';

  static const socialFacebook = 'https://www.facebook.com/';
  static const socialX = 'https://x.com/';
  static const socialLinkedIn = 'https://www.linkedin.com/company/growth-catalyst-hq';
  static const socialInstagram = 'https://www.instagram.com/';
  static const socialYouTube = 'https://www.youtube.com/';
  static const socialTikTok = 'https://www.tiktok.com/';
}
