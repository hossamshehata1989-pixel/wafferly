// lib/features/analysis/registry/category_registry.dart

import 'package:flutter/material.dart';
import '../../../config/category_config.dart';
import '../../../l10n/app_localizations.dart';

/// Centralized category lookup registry
/// Built once, used everywhere - no duplicate loops in widgets
class CategoryRegistry {
  // Private constructor - cannot be instantiated
  CategoryRegistry._();

  static bool _initialized = false;

  // ============ MAPS (built once) ============
  static final Map<String, CategoryConfig> _mainCategoryMap = {};
  static final Map<String, SubCategoryConfig> _subCategoryMap = {};
  static final Map<String, String> _subToParentMap = {};

  // ============ COLORS ============
  static final Map<String, Color> _mainColors = {};

  // ============ ICONS (explicit mapping - no dynamic path) ============
  static final Map<String, String> _mainIcons = {};

  // ==========================================
  // 🚀 INITIALIZATION (idempotent)
  // ==========================================
  static void initialize() {
    if (_initialized) return;

    _buildMainCategoryMaps();
    _buildSubCategoryMaps();
    _buildColorMaps();
    _buildIconMaps();
    _validateCategories();

    _initialized = true;
  }

  // ==========================================
  // 🔧 PRIVATE BUILDERS
  // ==========================================

  static void _buildMainCategoryMaps() {
    // Expense categories
    for (final category in expenseCategories) {
      _mainCategoryMap[category.id] = category;
    }
    // Income categories
    for (final category in incomeCategories) {
      _mainCategoryMap[category.id] = category;
    }
  }

  static void _buildSubCategoryMaps() {
    for (final category in expenseCategories) {
      for (final sub in category.subCategories ?? []) {
        _subCategoryMap[sub.id] = sub;
        _subToParentMap[sub.id] = category.id;
      }
    }
  }

  static void _buildColorMaps() {
    _mainColors.addAll({
      // Expense main categories
      'dailyTransport': const Color(0xFF4ECDC4),
      'bills': const Color(0xFFAA96DA),
      'supermarket': const Color(0xFFFF6B6B),
      'drinks': const Color(0xFFA8E6CF),
      'fastFood': const Color(0xFFFF6B6B),
      'meatFish': const Color(0xFFFF6B6B),
      'vegetables': const Color(0xFFA8E6CF),
      'fruits': const Color(0xFFA8E6CF),
      'smoking': const Color(0xFFFF8B94),
      'health': const Color(0xFFFF8B94),
      'entertainment': const Color(0xFFFFE66D),
      'education': const Color(0xFFFFE66D),
      'vehicles': const Color(0xFF4ECDC4),
      'home': const Color(0xFFAA96DA),
      'personalCare': const Color(0xFFFF8B94),
      'mobilePc': const Color(0xFF4ECDC4),
      'financials': const Color(0xFFAA96DA),
      'governServices': const Color(0xFFAA96DA),
      'giftsOccasions': const Color(0xFFFFE66D),
      'hobbies': const Color(0xFFFFE66D),
      'baby': const Color(0xFFFF8B94),
      'clothes': const Color(0xFFFF6B6B),
      'shoes': const Color(0xFFFF6B6B),
      // Income main categories
      'salary': const Color(0xFF2ECC71),
      'dailyIncome': const Color(0xFF2ECC71),
      'bonus': const Color(0xFFF39C12),
      'rewards': const Color(0xFFF39C12),
      'freelance': const Color(0xFF9B59B6),
    });
  }

  static void _buildIconMaps() {
    // Main categories only - no subcategory icons (UI will handle)
    _mainIcons.addAll({
      // Expense main categories
      'dailyTransport': 'assets/icons/categories/category_transport.svg',
      'bills': 'assets/icons/categories/category_bills.svg',
      'supermarket': 'assets/icons/categories/category_supermarket.svg',
      'drinks': 'assets/icons/categories/category_drinks.svg',
      'fastFood': 'assets/icons/categories/category_restaurants.svg',
      'meatFish': 'assets/icons/categories/category_meat_fish.svg',
      'vegetables': 'assets/icons/categories/category_vegetables.svg',
      'fruits': 'assets/icons/categories/category_fruits.svg',
      'smoking': 'assets/icons/categories/category_smoking.svg',
      'health': 'assets/icons/categories/category_health.svg',
      'entertainment': 'assets/icons/categories/category_entertainment.svg',
      'education': 'assets/icons/categories/category_education.svg',
      'vehicles': 'assets/icons/categories/category_vehicles.svg',
      'home': 'assets/icons/categories/category_home.svg',
      'personalCare': 'assets/icons/categories/category_personal_care.svg',
      'mobilePc': 'assets/icons/categories/category_tech.svg',
      'financials':
          'assets/icons/categories/category_financial_obligations.svg',
      'governServices': 'assets/icons/categories/category_government.svg',
      'giftsOccasions': 'assets/icons/categories/category_gifts_events.svg',
      'hobbies': 'assets/icons/categories/category_hobbies.svg',
      'baby': 'assets/icons/categories/category_baby.svg',
      'clothes': 'assets/icons/categories/category_clothes.svg',
      'shoes': 'assets/icons/categories/category_shoes.svg',
      // Income main categories
      'salary': 'assets/icons/categories/category_salary.svg',
      'dailyIncome': 'assets/icons/categories/category_daily_income.svg',
      'bonus': 'assets/icons/categories/category_bonus.svg',
      'rewards': 'assets/icons/categories/category_rewards.svg',
      'freelance': 'assets/icons/categories/category_freelance.svg',
    });
  }

  static void _validateCategories() {
    // Check main categories only - subcategories are optional
    for (final id in _mainCategoryMap.keys) {
      if (!_mainIcons.containsKey(id)) {
        debugPrint('⚠️ CategoryRegistry: Missing icon for main category: $id');
      }
      if (!_mainColors.containsKey(id)) {
        debugPrint('⚠️ CategoryRegistry: Missing color for main category: $id');
      }
    }
  }

  // ==========================================
  // 📖 PUBLIC API
  // ==========================================

  /// Get main category name (safe - returns id if not found)
  /// No guessing - main categories only
  static String getMainCategoryName(String id, AppLocalizations t) {
    final main = _mainCategoryMap[id];
    if (main != null) {
      return main.resolveTitle(t);
    }

    debugPrint('⚠️ CategoryRegistry: Main category not found: $id');
    return id;
  }

  /// Get sub category name (safe - returns id if not found)
  static String getSubCategoryName(String id, AppLocalizations t) {
    final sub = _subCategoryMap[id];
    if (sub != null) {
      return sub.title(t);
    }

    debugPrint('⚠️ CategoryRegistry: Sub category not found: $id');
    return id;
  }

  /// Get icon path (returns null if not found - UI handles fallback)
  static String? getIcon(String id) {
    final icon = _mainIcons[id];
    if (icon != null) {
      return icon;
    }

    debugPrint('⚠️ CategoryRegistry: Icon not found for: $id');
    return null;
  }

  /// Get color for main category (returns default if not found)
  static Color getColor(String id) {
    final mainColor = _mainColors[id];
    if (mainColor != null) {
      return mainColor;
    }

    debugPrint('⚠️ CategoryRegistry: Color not found for: $id');
    return const Color(0xFFA8E6CF);
  }

  /// Check if category exists as main category
  static bool isMainCategory(String id) {
    return _mainCategoryMap.containsKey(id);
  }

  /// Check if ID is a sub category
  static bool isSubCategory(String id) {
    return _subCategoryMap.containsKey(id);
  }

  /// Get parent main category ID (returns null if not a sub category)
  static String? getParentMainId(String subId) {
    return _subToParentMap[subId];
  }

  static CategoryConfig? getMainCategory(String id) {
    return _mainCategoryMap[id];
  }

  static List<SubCategoryConfig> getSubCategories(String mainCategoryId) {
    return _mainCategoryMap[mainCategoryId]?.subCategories ?? [];
  }
}
