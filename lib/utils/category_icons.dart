import '../core/app_assets.dart';

/// ===============================
/// Main Categories Icons
/// ===============================
const Map<String, String> categoryIcons = {
  // Transport & Movement
  'transport': AppAssets.categoryTransport,

  // Bills
  'bills': AppAssets.categoryBills,

  // Food & Daily Needs
  'supermarket': AppAssets.categorySupermarket,
  'restaurants': AppAssets.categoryRestaurants,
  'meatFish': AppAssets.categoryMeatFish,
  'vegetables': AppAssets.categoryVegetables,
  'fruits': AppAssets.categoryFruits,

  // Lifestyle
  'smoking': AppAssets.categorySmoking,
  'health': AppAssets.categoryHealth,
  'entertainment': AppAssets.categoryEntertainment,
  'education': AppAssets.categoryEducation,
  'hobbies': AppAssets.categoryHobbies,

  // Assets & Home
  'vehicles': AppAssets.categoryVehicles,
  'home': AppAssets.categoryHome,
  'personalCare': AppAssets.categoryPersonalCare,

  // Family
  'baby': AppAssets.categoryBaby,
  'clothes': AppAssets.categoryClothes,
  'shoes': AppAssets.categoryShoes,
};

/// ===============================
/// Get Category Icon (Safe)
/// ===============================
String getCategoryIcon(String categoryId) {
  return categoryIcons[categoryId] ??
      AppAssets.categoryPlaceholder;
}
