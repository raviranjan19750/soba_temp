import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../auth_config.dart';
import 'company_profile_session_cache.dart';

class CompanyRecentFinancials {
  const CompanyRecentFinancials({
    this.periodLabel = '',
    this.revenue = '',
    this.grossMarginDollar = '',
    this.grossMarginPct = '',
    this.ebitdaDollar = '',
    this.ebitdaPct = '',
    this.cashBalance = '',
  });

  final String periodLabel;
  final String revenue;
  final String grossMarginDollar;
  final String grossMarginPct;
  final String ebitdaDollar;
  final String ebitdaPct;
  final String cashBalance;

  bool get hasAnyValue =>
      periodLabel.trim().isNotEmpty ||
      revenue.trim().isNotEmpty ||
      grossMarginDollar.trim().isNotEmpty ||
      grossMarginPct.trim().isNotEmpty ||
      ebitdaDollar.trim().isNotEmpty ||
      ebitdaPct.trim().isNotEmpty ||
      cashBalance.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'periodLabel': periodLabel,
      'revenue': revenue,
      'grossMarginDollar': grossMarginDollar,
      'grossMarginPct': grossMarginPct,
      'ebitdaDollar': ebitdaDollar,
      'ebitdaPct': ebitdaPct,
      'cashBalance': cashBalance,
    };
  }

  static CompanyRecentFinancials fromMap(dynamic raw) {
    if (raw is! Map) return const CompanyRecentFinancials();
    final m = Map<String, dynamic>.from(raw);
    String field(String key) => (m[key] ?? '').toString().trim();
    return CompanyRecentFinancials(
      periodLabel: field('periodLabel'),
      revenue: field('revenue'),
      grossMarginDollar: field('grossMarginDollar'),
      grossMarginPct: field('grossMarginPct'),
      ebitdaDollar: field('ebitdaDollar'),
      ebitdaPct: field('ebitdaPct'),
      cashBalance: field('cashBalance'),
    );
  }

  static CompanyRecentFinancials fromSessionCache() {
    return CompanyRecentFinancials(
      periodLabel: CompanyProfileSessionCache.financialPeriodLabel,
      revenue: CompanyProfileSessionCache.financialRevenue,
      grossMarginDollar: CompanyProfileSessionCache.financialGrossMarginDollar,
      grossMarginPct: CompanyProfileSessionCache.financialGrossMarginPct,
      ebitdaDollar: CompanyProfileSessionCache.financialEbitdaDollar,
      ebitdaPct: CompanyProfileSessionCache.financialEbitdaPct,
      cashBalance: CompanyProfileSessionCache.financialCashBalance,
    );
  }

  void applyToSessionCache() {
    CompanyProfileSessionCache.updateFinancials(
      periodLabel: periodLabel,
      revenue: revenue,
      grossMarginDollar: grossMarginDollar,
      grossMarginPct: grossMarginPct,
      ebitdaDollar: ebitdaDollar,
      ebitdaPct: ebitdaPct,
      cashBalance: cashBalance,
    );
  }
}

class ManagementTeamMember {
  const ManagementTeamMember({
    this.title = '',
    this.fullName = '',
    this.email = '',
  });

  final String title;
  final String fullName;
  final String email;

  bool get isComplete =>
      title.trim().isNotEmpty &&
      fullName.trim().isNotEmpty &&
      email.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'fullName': fullName,
      'email': email,
    };
  }

  static ManagementTeamMember fromMap(dynamic raw) {
    if (raw is! Map) return const ManagementTeamMember();
    final m = Map<String, dynamic>.from(raw);
    return ManagementTeamMember(
      title: (m['title'] ?? '').toString().trim(),
      fullName: (m['fullName'] ?? '').toString().trim(),
      email: (m['email'] ?? '').toString().trim(),
    );
  }
}

class CompanyProfileData {
  const CompanyProfileData({
    required this.companyName,
    this.logoUrl = '',
    this.industry = '',
    this.website = '',
    this.companySize = '',
    this.fiscalYearEnd = '',
    this.description = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.stateRegion = '',
    this.postalCode = '',
    this.country = '',
    this.recentFinancials = const CompanyRecentFinancials(),
    this.managementTeam = const [],
    this.logoBytes,
  });

  final String companyName;
  final String logoUrl;
  final String industry;
  final String website;
  final String companySize;
  final String fiscalYearEnd;
  final String description;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String stateRegion;
  final String postalCode;
  final String country;
  final CompanyRecentFinancials recentFinancials;
  final List<ManagementTeamMember> managementTeam;
  final Uint8List? logoBytes;

  CompanyProfileData copyWith({
    String? companyName,
    String? logoUrl,
    String? industry,
    String? website,
    String? companySize,
    String? fiscalYearEnd,
    String? description,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? stateRegion,
    String? postalCode,
    String? country,
    CompanyRecentFinancials? recentFinancials,
    List<ManagementTeamMember>? managementTeam,
    Uint8List? logoBytes,
    bool clearLogoBytes = false,
  }) {
    return CompanyProfileData(
      companyName: companyName ?? this.companyName,
      logoUrl: logoUrl ?? this.logoUrl,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      companySize: companySize ?? this.companySize,
      fiscalYearEnd: fiscalYearEnd ?? this.fiscalYearEnd,
      description: description ?? this.description,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      stateRegion: stateRegion ?? this.stateRegion,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      recentFinancials: recentFinancials ?? this.recentFinancials,
      managementTeam: managementTeam ?? this.managementTeam,
      logoBytes: clearLogoBytes ? null : (logoBytes ?? this.logoBytes),
    );
  }

  Map<String, dynamic> toFirestore({String? logoUrlOverride}) {
    final payload = <String, dynamic>{
      'companyName': companyName,
      'industry': industry,
      'website': website,
      'companySize': companySize,
      'fiscalYearEnd': fiscalYearEnd,
      'description': description,
      'addressLine1': addressLine1,
      'city': city,
      'stateRegion': stateRegion,
      'postalCode': postalCode,
      'country': country,
      'recentFinancials': recentFinancials.toMap(),
      'managementTeam': managementTeam.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final resolvedLogo = logoUrlOverride ?? logoUrl;
    if (resolvedLogo.trim().isNotEmpty) {
      payload['logoUrl'] = resolvedLogo.trim();
    }
    if (addressLine2.trim().isEmpty) {
      payload['addressLine2'] = FieldValue.delete();
    } else {
      payload['addressLine2'] = addressLine2;
    }
    return payload;
  }

  static CompanyProfileData fromMap(Map<String, dynamic> data) {
    return CompanyProfileData(
      companyName: (data['companyName'] ?? '').toString().trim(),
      logoUrl: (data['logoUrl'] ?? '').toString().trim(),
      industry: (data['industry'] ?? '').toString().trim(),
      website: (data['website'] ?? '').toString().trim(),
      companySize: (data['companySize'] ?? '').toString().trim(),
      fiscalYearEnd: (data['fiscalYearEnd'] ?? '').toString().trim(),
      description: (data['description'] ?? '').toString().trim(),
      addressLine1: (data['addressLine1'] ?? '').toString().trim(),
      addressLine2: (data['addressLine2'] ?? '').toString().trim(),
      city: (data['city'] ?? '').toString().trim(),
      stateRegion: (data['stateRegion'] ?? '').toString().trim(),
      postalCode: (data['postalCode'] ?? '').toString().trim(),
      country: (data['country'] ?? '').toString().trim(),
      recentFinancials:
          CompanyRecentFinancials.fromMap(data['recentFinancials']),
      managementTeam: _parseManagementTeam(data['managementTeam']),
    );
  }

  static List<ManagementTeamMember> _parseManagementTeam(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(ManagementTeamMember.fromMap)
        .where(
          (m) =>
              m.title.isNotEmpty ||
              m.fullName.isNotEmpty ||
              m.email.isNotEmpty,
        )
        .toList();
  }

  static CompanyProfileData fromSessionCache() {
    return CompanyProfileData(
      companyName: CompanyProfileSessionCache.companyName,
      logoUrl: CompanyProfileSessionCache.logoUrl,
      industry: CompanyProfileSessionCache.industry,
      website: CompanyProfileSessionCache.website,
      companySize: CompanyProfileSessionCache.companySize,
      fiscalYearEnd: CompanyProfileSessionCache.fiscalYearEnd,
      description: CompanyProfileSessionCache.description,
      addressLine1: CompanyProfileSessionCache.addressLine1,
      addressLine2: CompanyProfileSessionCache.addressLine2,
      city: CompanyProfileSessionCache.city,
      stateRegion: CompanyProfileSessionCache.stateRegion,
      postalCode: CompanyProfileSessionCache.postalCode,
      country: CompanyProfileSessionCache.country,
      recentFinancials: CompanyRecentFinancials.fromSessionCache(),
      managementTeam: CompanyProfileSessionCache.managementTeam
          .map(ManagementTeamMember.fromMap)
          .toList(),
      logoBytes: CompanyProfileSessionCache.logoBytes,
    );
  }

  void applyToSessionCache() {
    CompanyProfileSessionCache.update(
      companyName: companyName,
      industry: industry,
      website: website,
      companySize: companySize,
      fiscalYearEnd: fiscalYearEnd,
      description: description,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      stateRegion: stateRegion,
      postalCode: postalCode,
      country: country,
      logoUrl: logoUrl,
      logoBytes: logoBytes,
      clearLogoBytes: logoBytes == null,
    );
    recentFinancials.applyToSessionCache();
    CompanyProfileSessionCache.setManagementTeam(
      managementTeam.map((m) => m.toMap()).toList(),
    );
  }
}

class CompanyProfileService {
  static const managementTitleOptions = [
    'Chief Executive Officer (CEO)',
    'Chief Financial Officer (CFO)',
    'Chief Operating Officer (COO)',
    'Chief Technology Officer (CTO)',
    'Chief Marketing Officer (CMO)',
    'President',
    'Vice President',
    'General Manager',
    'Board Chair',
    'Board Member',
    'Other',
  ];

  static const companySizeOptions = [
    '1–10 employees',
    '11–50 employees',
    '51–200 employees',
    '201–500 employees',
    '500+ employees',
  ];

  static const fiscalYearEndOptions = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static Future<CompanyProfileData> load(String? companyId) async {
    if (skipFirebasePersistence || companyId == null) {
      return CompanyProfileData.fromSessionCache();
    }

    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();
    if (!snap.exists || snap.data() == null) {
      return const CompanyProfileData(companyName: '');
    }
    return CompanyProfileData.fromMap(snap.data()!);
  }

  static Future<String?> uploadLogo({
    required String companyId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (skipFirebasePersistence) return null;

    final lower = fileName.toLowerCase();
    final isJpeg = lower.endsWith('.jpg') || lower.endsWith('.jpeg');
    final mime = isJpeg ? 'image/jpeg' : 'image/png';
    final ext = isJpeg ? 'jpg' : 'png';
    final ref = FirebaseStorage.instance.ref('companies/$companyId/logo.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: mime));
    return ref.getDownloadURL();
  }

  static Future<void> save({
    required String? companyId,
    required CompanyProfileData profile,
    Uint8List? pendingLogoBytes,
    String? pendingLogoFileName,
    bool removeLogo = false,
  }) async {
    if (skipFirebasePersistence || companyId == null) {
      var next = profile;
      if (removeLogo) {
        next = next.copyWith(logoUrl: '', clearLogoBytes: true);
      } else if (pendingLogoBytes != null) {
        next = next.copyWith(logoBytes: pendingLogoBytes);
      }
      next.applyToSessionCache();
      return;
    }

    var logoUrl = profile.logoUrl;
    if (removeLogo) {
      logoUrl = '';
      try {
        await FirebaseStorage.instance
            .ref('companies/$companyId')
            .child('logo.png')
            .delete();
      } catch (_) {}
      try {
        await FirebaseStorage.instance
            .ref('companies/$companyId')
            .child('logo.jpg')
            .delete();
      } catch (_) {}
    } else if (pendingLogoBytes != null && pendingLogoBytes.isNotEmpty) {
      final uploaded = await uploadLogo(
        companyId: companyId,
        bytes: pendingLogoBytes,
        fileName: pendingLogoFileName ?? 'logo.png',
      );
      if (uploaded != null) logoUrl = uploaded;
    }

    final payload = profile.toFirestore(logoUrlOverride: logoUrl);
    if (removeLogo) {
      payload['logoUrl'] = FieldValue.delete();
    }

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .set(payload, SetOptions(merge: true));

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null) {
      final organization = <String, dynamic>{
        'companyName': profile.companyName,
        'addressLine1': profile.addressLine1,
        'city': profile.city,
        'stateRegion': profile.stateRegion,
        'postalCode': profile.postalCode,
        'country': profile.country,
      };
      if (profile.addressLine2.isNotEmpty) {
        organization['addressLine2'] = profile.addressLine2;
      }
      await FirebaseFirestore.instance.collection('users').doc(authUid).set(
        {
          'accountProfile': {
            'organization': organization,
          },
        },
        SetOptions(merge: true),
      );
    }
  }
}
