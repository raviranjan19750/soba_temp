import 'dart:typed_data';

/// In-memory company profile for local dev when Firebase persistence is skipped.
class CompanyProfileSessionCache {
  static String companyName = '';
  static String industry = '';
  static String website = '';
  static String companySize = '';
  static String fiscalYearEnd = '';
  static String description = '';
  static String addressLine1 = '';
  static String addressLine2 = '';
  static String city = '';
  static String stateRegion = '';
  static String postalCode = '';
  static String country = '';
  static String logoUrl = '';
  static Uint8List? logoBytes;
  static String financialPeriodLabel = '';
  static String financialRevenue = '';
  static String financialGrossMarginDollar = '';
  static String financialGrossMarginPct = '';
  static String financialEbitdaDollar = '';
  static String financialEbitdaPct = '';
  static String financialCashBalance = '';
  static List<Map<String, dynamic>> managementTeam = [];

  static void update({
    String? companyName,
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
    String? logoUrl,
    Uint8List? logoBytes,
    bool clearLogoBytes = false,
  }) {
    if (companyName != null) CompanyProfileSessionCache.companyName = companyName;
    if (industry != null) CompanyProfileSessionCache.industry = industry;
    if (website != null) CompanyProfileSessionCache.website = website;
    if (companySize != null) CompanyProfileSessionCache.companySize = companySize;
    if (fiscalYearEnd != null) {
      CompanyProfileSessionCache.fiscalYearEnd = fiscalYearEnd;
    }
    if (description != null) CompanyProfileSessionCache.description = description;
    if (addressLine1 != null) {
      CompanyProfileSessionCache.addressLine1 = addressLine1;
    }
    if (addressLine2 != null) {
      CompanyProfileSessionCache.addressLine2 = addressLine2;
    }
    if (city != null) CompanyProfileSessionCache.city = city;
    if (stateRegion != null) {
      CompanyProfileSessionCache.stateRegion = stateRegion;
    }
    if (postalCode != null) CompanyProfileSessionCache.postalCode = postalCode;
    if (country != null) CompanyProfileSessionCache.country = country;
    if (logoUrl != null) CompanyProfileSessionCache.logoUrl = logoUrl;
    if (clearLogoBytes) {
      CompanyProfileSessionCache.logoBytes = null;
    } else if (logoBytes != null) {
      CompanyProfileSessionCache.logoBytes = logoBytes;
    }
  }

  static void updateFinancials({
    String? periodLabel,
    String? revenue,
    String? grossMarginDollar,
    String? grossMarginPct,
    String? ebitdaDollar,
    String? ebitdaPct,
    String? cashBalance,
  }) {
    if (periodLabel != null) {
      CompanyProfileSessionCache.financialPeriodLabel = periodLabel;
    }
    if (revenue != null) CompanyProfileSessionCache.financialRevenue = revenue;
    if (grossMarginDollar != null) {
      CompanyProfileSessionCache.financialGrossMarginDollar = grossMarginDollar;
    }
    if (grossMarginPct != null) {
      CompanyProfileSessionCache.financialGrossMarginPct = grossMarginPct;
    }
    if (ebitdaDollar != null) {
      CompanyProfileSessionCache.financialEbitdaDollar = ebitdaDollar;
    }
    if (ebitdaPct != null) {
      CompanyProfileSessionCache.financialEbitdaPct = ebitdaPct;
    }
    if (cashBalance != null) {
      CompanyProfileSessionCache.financialCashBalance = cashBalance;
    }
  }

  static void setManagementTeam(List<Map<String, dynamic>> members) {
    CompanyProfileSessionCache.managementTeam = members
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
