import 'package:flutter/services.dart';

class WafferlyInputFormatters {
  const WafferlyInputFormatters._();

  /// يمنع إدخال الأرقام داخل أسماء الأشخاص.
  static final personName = FilteringTextInputFormatter.allow(
    RegExp(r"[a-zA-Z\u0600-\u06FF ]"),
  );

  /// يسمح بالأرقام فقط.
  static final numbersOnly = FilteringTextInputFormatter.digitsOnly;
}
