/// =======================================================
/// Wafferly - Category Configuration
/// Single source of truth for all categories
/// =======================================================

import '../core/app_assets.dart';
import '../l10n/app_localizations.dart';

class CategoryConfig {
  final String id;
  final String icon;

  const CategoryConfig({
    required this.id,
    required this.icon,
  });

  /// 🔷 Resolve localized title
  String resolveTitle(AppLocalizations t) {
    switch (id) {
      case 'dailyTransport': return t.dailyTransport;
      case 'bills': return t.bills;
      case 'supermarket': return t.supermarket;
      case 'fastFood': return t.fastFood;
      case 'meatFish': return t.meatFish;
      case 'vegetables': return t.vegetables;
      case 'fruits': return t.fruits;
      case 'smoking': return t.smoking;
      case 'health': return t.health;
      case 'entertainment': return t.entertainment;
      case 'education': return t.education;
      case 'vehicles': return t.vehicles;
      case 'home': return t.home;
      case 'personalCare': return t.personalCare;
      case 'mobilePc': return t.mobilePc;
      case 'financialCommitments': return t.financialCommitments;
      case 'governmentServices': return t.governmentServices;
      case 'C': return t.giftsOccasions;
      case 'hobbies': return t.hobbies;
      case 'baby': return t.baby;
      case 'clothes': return t.clothes;
      case 'shoes': return t.shoes;
      default:
        return id;
    }
  }
}

/// =======================================================
/// 🔷 Main Categories List
/// =======================================================

const List<CategoryConfig> mainCategories = [
  CategoryConfig(id: 'dailyTransport', icon: AppAssets.categoryDailyTransport),
  CategoryConfig(id: 'bills', icon: AppAssets.categoryBills),
  CategoryConfig(id: 'supermarket', icon: AppAssets.categorySupermarket),
  CategoryConfig(id: 'fastFood', icon: AppAssets.categoryFastFood),
  CategoryConfig(id: 'meatFish', icon: AppAssets.categoryMeatFish),
  CategoryConfig(id: 'vegetables', icon: AppAssets.categoryVegetables),
  CategoryConfig(id: 'fruits', icon: AppAssets.categoryFruits),
  CategoryConfig(id: 'smoking', icon: AppAssets.categorySmoking),
  CategoryConfig(id: 'health', icon: AppAssets.categoryHealth),
  CategoryConfig(id: 'entertainment', icon: AppAssets.categoryEntertainment),
  CategoryConfig(id: 'education', icon: AppAssets.categoryEducation),
  CategoryConfig(id: 'vehicles', icon: AppAssets.categoryVehicles),
  CategoryConfig(id: 'home', icon: AppAssets.categoryHome),
  CategoryConfig(id: 'personalCare', icon: AppAssets.categoryPersonalCare),
  CategoryConfig(id: 'mobilePc', icon: AppAssets.categoryMobilePc),
  CategoryConfig(id: 'financialCommitments', icon: AppAssets.categoryFinancialCommitments),
  CategoryConfig(id: 'governmentServices', icon: AppAssets.categoryGovernmentServices),
  CategoryConfig(id: 'giftsOccasions', icon: AppAssets.categoryGiftsOccasions),
  CategoryConfig(id: 'hobbies', icon: AppAssets.categoryHobbies),
  CategoryConfig(id: 'baby', icon: AppAssets.categoryBaby),
  CategoryConfig(id: 'clothes', icon: AppAssets.categoryClothes),
  CategoryConfig(id: 'shoes', icon: AppAssets.categoryShoes),
];
