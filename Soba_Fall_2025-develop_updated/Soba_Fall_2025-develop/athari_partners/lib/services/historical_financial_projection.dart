import 'package:athari_partners/utils/currency_input.dart';

/// Annualizes YTD historical financial inputs into a year-end projection.
class HistoricalFinancialProjection {
  HistoricalFinancialProjection._();

  static int defaultCalendarQuarter([DateTime? asOf]) {
    final month = (asOf ?? DateTime.now()).month;
    return ((month - 1) ~/ 3 + 1).clamp(1, 4);
  }

  static double annualizationFactor(int quarter) =>
      4.0 / quarter.clamp(1, 4);

  static String quarterLabel(int quarter) => 'Q${quarter.clamp(1, 4)}';

  /// Projects a standard financial row from YTD inputs.
  static String? projectFinancialRow({
    required String rowKey,
    required Map<String, String> ytdValuesByRowKey,
    required int quarter,
  }) {
    switch (rowKey) {
      case 'gross_margin_pct':
        return _projectRatioPct(
          numeratorYtd: ytdValuesByRowKey['gross_margin_dollar'],
          denominatorYtd: ytdValuesByRowKey['revenue'],
          quarter: quarter,
          fallbackYtd: ytdValuesByRowKey['gross_margin_pct'],
        );
      case 'ebitda_pct':
        return _projectRatioPct(
          numeratorYtd: ytdValuesByRowKey['ebitda_dollar'],
          denominatorYtd: ytdValuesByRowKey['revenue'],
          quarter: quarter,
          fallbackYtd: ytdValuesByRowKey['ebitda_pct'],
        );
      case 'revenue':
      case 'gross_margin_dollar':
      case 'ebitda_dollar':
        return _annualizeCurrency(ytdValuesByRowKey[rowKey], quarter);
      default:
        return _annualizeNumber(ytdValuesByRowKey[rowKey], quarter);
    }
  }

  /// Projects an additional metric cell from its YTD value and format.
  static String? projectAdditionalMetric({
    required String ytdText,
    required String formatKey,
    required int quarter,
  }) {
    switch (formatKey) {
      case 'currency':
        return _annualizeCurrency(ytdText, quarter);
      case 'number':
        return _annualizeNumber(ytdText, quarter);
      case 'percent':
        return _holdPercent(ytdText);
      default:
        return _annualizeNumber(ytdText, quarter);
    }
  }

  static String? _annualizeCurrency(String? ytdText, int quarter) {
    if (ytdText == null || ytdText.trim().isEmpty) return null;
    final value = parseCurrency(ytdText);
    if (value == null) return null;
    return formatCurrencyDisplay(value * annualizationFactor(quarter));
  }

  static String? _annualizeNumber(String? ytdText, int quarter) {
    if (ytdText == null || ytdText.trim().isEmpty) return null;
    final value = parseCurrency(ytdText);
    if (value == null) return null;
    final projected = value * annualizationFactor(quarter);
    if (projected == projected.roundToDouble()) {
      return projected.round().toString();
    }
    return projected.toStringAsFixed(2);
  }

  static String? _holdPercent(String? ytdText) {
    if (ytdText == null || ytdText.trim().isEmpty) return null;
    final value = parsePercent(ytdText);
    if (value == null) return ytdText.trim();
    return formatPercentDisplay(value);
  }

  static String? _projectRatioPct({
    required String? numeratorYtd,
    required String? denominatorYtd,
    required int quarter,
    required String? fallbackYtd,
  }) {
    final numerator = parseCurrency(numeratorYtd);
    final denominator = parseCurrency(denominatorYtd);
    if (numerator != null &&
        denominator != null &&
        denominator != 0 &&
        (numeratorYtd?.trim().isNotEmpty ?? false) &&
        (denominatorYtd?.trim().isNotEmpty ?? false)) {
      final factor = annualizationFactor(quarter);
      final projectedNumerator = numerator * factor;
      final projectedDenominator = denominator * factor;
      if (projectedDenominator == 0) return _holdPercent(fallbackYtd);
      return formatPercentDisplay(
        projectedNumerator / projectedDenominator * 100,
      );
    }
    return _holdPercent(fallbackYtd);
  }
}
