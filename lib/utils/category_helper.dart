// ==========================================
// 📦 CATEGORY HELPER
// Single Source of Truth for category names
// ==========================================

import 'package:wafferly/l10n/app_localizations.dart';
import '../config/category_config.dart';

// ==============================
// 🔹 Get Main Category Name
// ==============================
String getMainCategoryName(
  String categoryId,
  AppLocalizations t,
) {
  final category = mainCategories.firstWhere(
    (c) => c.id == categoryId,
    orElse: () => throw Exception("Category not found"),
  );

  return category.resolveTitle(t);
}

// ==============================
// 🔹 Get Sub Category Name
// ==============================
String getSubCategoryName(
  String subCategoryId,
  AppLocalizations t,
) {
  for (final category in mainCategories) {
    final sub = category.subCategories?.firstWhere(
      (s) => s.id == subCategoryId,
      orElse: () => SubCategoryConfig(id: '', title: (t) => ''),
    );

    if (sub != null && sub.id.isNotEmpty) {
      return sub.title(t);
    }
  }

  return subCategoryId; // fallback
}