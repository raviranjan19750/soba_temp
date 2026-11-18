import 'package:athari_partners/utils/currency_input.dart';
import 'package:flutter/material.dart';

/// Which historical financial cell the user last edited (per column).
enum HistoricalFinancialField {
  revenue,
  grossMarginDollar,
  grossMarginPct,
  ebitdaDollar,
  ebitdaPct,
}

/// Keeps revenue-linked $ and % pairs in sync for one historical table column.
class HistoricalFinancialSync {
  HistoricalFinancialSync._();

  static HistoricalFinancialField? fieldForRowKey(String rowKey) {
    switch (rowKey) {
      case 'revenue':
        return HistoricalFinancialField.revenue;
      case 'gross_margin_dollar':
        return HistoricalFinancialField.grossMarginDollar;
      case 'gross_margin_pct':
        return HistoricalFinancialField.grossMarginPct;
      case 'ebitda_dollar':
        return HistoricalFinancialField.ebitdaDollar;
      case 'ebitda_pct':
        return HistoricalFinancialField.ebitdaPct;
      default:
        return null;
    }
  }

  static void syncColumn({
    required Map<String, TextEditingController> columnCtrls,
    required HistoricalFinancialField source,
  }) {
    final revenueCtrl = columnCtrls['revenue'];
    if (revenueCtrl == null) return;

    final revenue = parseCurrency(revenueCtrl.text);
    final hasRevenue =
        revenueCtrl.text.trim().isNotEmpty && revenue != null && revenue != 0;

    switch (source) {
      case HistoricalFinancialField.revenue:
        if (!hasRevenue) return;
        _syncPairFromRevenue(
          revenue: revenue,
          dollarCtrl: columnCtrls['gross_margin_dollar'],
          pctCtrl: columnCtrls['gross_margin_pct'],
        );
        _syncPairFromRevenue(
          revenue: revenue,
          dollarCtrl: columnCtrls['ebitda_dollar'],
          pctCtrl: columnCtrls['ebitda_pct'],
        );
      case HistoricalFinancialField.grossMarginDollar:
        if (!hasRevenue) return;
        _syncPctFromDollar(
          revenue: revenue,
          dollarCtrl: columnCtrls['gross_margin_dollar'],
          pctCtrl: columnCtrls['gross_margin_pct'],
        );
      case HistoricalFinancialField.grossMarginPct:
        if (!hasRevenue) return;
        _syncDollarFromPct(
          revenue: revenue,
          dollarCtrl: columnCtrls['gross_margin_dollar'],
          pctCtrl: columnCtrls['gross_margin_pct'],
        );
      case HistoricalFinancialField.ebitdaDollar:
        if (!hasRevenue) return;
        _syncPctFromDollar(
          revenue: revenue,
          dollarCtrl: columnCtrls['ebitda_dollar'],
          pctCtrl: columnCtrls['ebitda_pct'],
        );
      case HistoricalFinancialField.ebitdaPct:
        if (!hasRevenue) return;
        _syncDollarFromPct(
          revenue: revenue,
          dollarCtrl: columnCtrls['ebitda_dollar'],
          pctCtrl: columnCtrls['ebitda_pct'],
        );
    }
  }

  static void _syncPairFromRevenue({
    required double revenue,
    required TextEditingController? dollarCtrl,
    required TextEditingController? pctCtrl,
  }) {
    if (dollarCtrl == null || pctCtrl == null) return;

    final pct = parsePercent(pctCtrl.text);
    final dollar = parseCurrency(dollarCtrl.text);
    final pctFilled = pctCtrl.text.trim().isNotEmpty && pct != null;
    final dollarFilled = dollarCtrl.text.trim().isNotEmpty && dollar != null;

    if (pctFilled) {
      _setControllerText(
        dollarCtrl,
        formatCurrencyDisplay(revenue * pct / 100),
      );
    } else if (dollarFilled) {
      _setControllerText(
        pctCtrl,
        formatPercentDisplay(dollar / revenue * 100),
      );
    }
  }

  static void _syncPctFromDollar({
    required double revenue,
    required TextEditingController? dollarCtrl,
    required TextEditingController? pctCtrl,
  }) {
    if (dollarCtrl == null || pctCtrl == null) return;
    if (dollarCtrl.text.trim().isEmpty) return;
    final dollar = parseCurrency(dollarCtrl.text);
    if (dollar == null) return;
    _setControllerText(
      pctCtrl,
      formatPercentDisplay(dollar / revenue * 100),
    );
  }

  static void _syncDollarFromPct({
    required double revenue,
    required TextEditingController? dollarCtrl,
    required TextEditingController? pctCtrl,
  }) {
    if (dollarCtrl == null || pctCtrl == null) return;
    if (pctCtrl.text.trim().isEmpty) return;
    final pct = parsePercent(pctCtrl.text);
    if (pct == null) return;
    _setControllerText(
      dollarCtrl,
      formatCurrencyDisplay(revenue * pct / 100),
    );
  }

  static void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.text = text;
  }
}
