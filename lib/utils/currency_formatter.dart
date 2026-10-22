// lib/utils/currency_formatter.dart

import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Existing whole-unit formatting, kept for screens that intentionally omit
  /// fractional units.
  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat("#,###");
    final formatted = formatter.format(amount.toInt());
    return "$formatted $currencyCode";
  }

  /// Precise display for financial reports where fractional units matter.
  static String formatPrecise(double amount, String currencyCode) {
    final formatter = NumberFormat("#,##0.##");
    return "${formatter.format(amount)} $currencyCode";
  }
}
