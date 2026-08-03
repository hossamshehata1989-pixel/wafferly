import 'package:flutter/material.dart';

class ExpenseSheetState {
  /// الفئة الحالية المختارة
  static final ValueNotifier<String?> selectedCategory = ValueNotifier(null);
}
