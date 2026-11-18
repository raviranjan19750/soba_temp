import 'package:flutter/services.dart';

/// Parses currency text that may include commas, dollar signs, etc.
double? parseCurrency(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty || cleaned == '.' || cleaned == '-') return null;
  return double.tryParse(cleaned);
}

/// Formats a numeric value with thousands separators and two decimal places.
String formatCurrencyDisplay(double value) {
  final negative = value < 0;
  final abs = value.abs();
  final fixed = abs.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : '00';
  final withCommas = intPart.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '${negative ? '-' : ''}$withCommas.$decPart';
}

/// Formats raw user input for display with comma grouping.
String formatCurrencyText(String raw) {
  final value = parseCurrency(raw);
  if (value == null) return raw.trim();
  return formatCurrencyDisplay(value);
}

double? parsePercent(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty || cleaned == '.' || cleaned == '-') return null;
  return double.tryParse(cleaned);
}

String formatPercentDisplay(double value) {
  return value.toStringAsFixed(2);
}

/// Strips input to an optional leading minus and numeric decimal body.
({bool negative, String body}) _parseSignedNumericInput(String raw) {
  var text = raw.trim();
  var negative = false;
  if (text.startsWith('-')) {
    negative = true;
    text = text.substring(1);
  }
  text = text.replaceAll('-', '');
  return (negative: negative, body: text.replaceAll(RegExp(r'[^0-9.]'), ''));
}

String _formatSignedDecimal({
  required bool negative,
  required String body,
}) {
  if (body.isEmpty) {
    return negative ? '-' : '';
  }

  final dotIndex = body.indexOf('.');
  final intRaw = dotIndex == -1 ? body : body.substring(0, dotIndex);
  var decRaw = dotIndex == -1 ? '' : body.substring(dotIndex + 1);
  if (decRaw.length > 2) decRaw = decRaw.substring(0, 2);

  final intPart = intRaw.isEmpty ? '0' : intRaw;
  final formattedInt = intPart.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  final hasDot = dotIndex != -1;
  final unsigned = hasDot ? '$formattedInt.$decRaw' : formattedInt;
  return negative ? '-$unsigned' : unsigned;
}

/// Formats currency fields as the user types (optional minus, commas, 2 decimals).
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final parsed = _parseSignedNumericInput(newValue.text);
    if (parsed.body.isEmpty && !parsed.negative) {
      return const TextEditingValue();
    }

    final text = _formatSignedDecimal(
      negative: parsed.negative,
      body: parsed.body,
    );

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Allows signed percent entry with up to two decimal places.
class PercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final parsed = _parseSignedNumericInput(newValue.text);
    if (parsed.body.isEmpty && !parsed.negative) {
      return const TextEditingValue();
    }

    final dotIndex = parsed.body.indexOf('.');
    final intRaw = dotIndex == -1 ? parsed.body : parsed.body.substring(0, dotIndex);
    var decRaw = dotIndex == -1 ? '' : parsed.body.substring(dotIndex + 1);
    if (decRaw.length > 2) decRaw = decRaw.substring(0, 2);

    final unsigned = dotIndex == -1 ? intRaw : '$intRaw.$decRaw';
    final text = parsed.negative ? '-$unsigned' : unsigned;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
