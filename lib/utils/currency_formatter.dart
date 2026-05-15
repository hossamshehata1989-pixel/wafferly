// lib/utils/currency_formatter.dart

import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat("#,###");
    final formatted = formatter.format(amount.toInt());
    return "$formatted $currencyCode";
  }
}
