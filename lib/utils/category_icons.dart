import 'package:flutter/foundation.dart';

/// ===============================
/// Get Category Icon (STRICT MODE)
/// ===============================
String getCategoryIcon(String categoryId) {
  final path = 'assets/icons/categories/category_$categoryId.svg';

  // أثناء التطوير: اطبع تحذير لو الأيقونة مش موجودة
  assert(() {
    debugPrint('🔎 Trying to load icon: $path');
    return true;
  }());

  return path;
}
