/// =======================================================
/// Wafferly - Category Configuration
/// Single source of truth for all categories
/// =======================================================

import '../core/app_assets.dart';
import '../l10n/app_localizations.dart';

class CategoryConfig {
  final String id;
  final String icon;
  final List<SubCategoryConfig>? subCategories;

  const CategoryConfig({
    required this.id,
    required this.icon,
    this.subCategories,
  });

  /// 🔷 Resolve localized title
  String resolveTitle(AppLocalizations t) {
    switch (id) {
      case 'dailyTransport': return t.dailyTransport;
      case 'bills': return t.bills;
      case 'supermarket': return t.supermarket;
      case 'drinks': return t.drinks;
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
      case 'financials': return t.financials;
      case 'governServices': return t.governServices;
      case 'giftsOccasions': return t.giftsOccasions;
      case 'hobbies': return t.hobbies;
      case 'baby': return t.baby;
      case 'clothes': return t.clothes;
      case 'shoes': return t.shoes;
      default: return id;
    }
  }
}

class SubCategoryConfig {
  final String id;
  final String Function(AppLocalizations) title;

  const SubCategoryConfig({
    required this.id,
    required this.title,
  });
}

/// =======================================================
/// 🔷 Main Categories with SubCategories
/// Using correct asset names from AppAssets
/// =======================================================

final List<CategoryConfig> mainCategories = [
  /// DAILY TRANSPORT
  CategoryConfig(
    id: 'dailyTransport',
    icon: AppAssets.categoryTransport, // ✅ التصحيح: categoryTransport
    subCategories: [
      SubCategoryConfig(id: 'tuktuk', title: (t) => t.tuktuk),
      SubCategoryConfig(id: 'microbus', title: (t) => t.microbus),
      SubCategoryConfig(id: 'taxiUber', title: (t) => t.taxiUber),
      SubCategoryConfig(id: 'bus', title: (t) => t.bus),
      SubCategoryConfig(id: 'metro', title: (t) => t.metro),
      SubCategoryConfig(id: 'train', title: (t) => t.train),
    ],
  ),

  /// BILLS
  CategoryConfig(
    id: 'bills',
    icon: AppAssets.categoryBills,
    subCategories: [
      SubCategoryConfig(id: 'electricityBill', title: (t) => t.electricityBill),
      SubCategoryConfig(id: 'waterBill', title: (t) => t.waterBill),
      SubCategoryConfig(id: 'gasBill', title: (t) => t.gasBill),
      SubCategoryConfig(id: 'mobileRecharge', title: (t) => t.mobileRecharge),
      SubCategoryConfig(id: 'mobileInternet', title: (t) => t.mobileInternet),
      SubCategoryConfig(id: 'wifi', title: (t) => t.wifi),
      SubCategoryConfig(id: 'landlineBill', title: (t) => t.landlineBill),
      SubCategoryConfig(id: 'elevatorMaint', title: (t) => t.elevatorMaint),
      SubCategoryConfig(id: 'cleaningFees', title: (t) => t.cleaningFees),
      SubCategoryConfig(id: 'buildSecurity', title: (t) => t.buildSecurity),
    ],
  ),

  /// SUPERMARKET
  CategoryConfig(
    id: 'supermarket',
    icon: AppAssets.categorySupermarket,
    subCategories: [
      SubCategoryConfig(id: 'waterBottle', title: (t) => t.waterBottle),
      SubCategoryConfig(id: 'milkPack', title: (t) => t.milkPack),
      SubCategoryConfig(id: 'cheese', title: (t) => t.cheese),
      SubCategoryConfig(id: 'yogurt', title: (t) => t.yogurt),
      SubCategoryConfig(id: 'eggs', title: (t) => t.eggs),
      SubCategoryConfig(id: 'cannedFood', title: (t) => t.cannedFood),
      SubCategoryConfig(id: 'bread', title: (t) => t.bread),
      SubCategoryConfig(id: 'rice', title: (t) => t.rice),
      SubCategoryConfig(id: 'pasta', title: (t) => t.pasta),
      SubCategoryConfig(id: 'oil', title: (t) => t.oil),
      SubCategoryConfig(id: 'ghee', title: (t) => t.ghee),
      SubCategoryConfig(id: 'sugar', title: (t) => t.sugar),
      SubCategoryConfig(id: 'teaPack', title: (t) => t.teaPack),
      SubCategoryConfig(id: 'coffeePack', title: (t) => t.coffeePack),
      SubCategoryConfig(id: 'legumes', title: (t) => t.legumes),
      SubCategoryConfig(id: 'frozenFood', title: (t) => t.frozenFood),
      SubCategoryConfig(id: 'spices', title: (t) => t.spices),
      SubCategoryConfig(id: 'snacks', title: (t) => t.snacks),
      SubCategoryConfig(id: 'biscuits', title: (t) => t.biscuits),
    ],
  ),

  /// DRINKS
  CategoryConfig(
    id: 'drinks',
    icon: AppAssets.categoryPlaceholder, // ✅ placeholder
    subCategories: [
      SubCategoryConfig(id: 'tea', title: (t) => t.tea),
      SubCategoryConfig(id: 'coffee', title: (t) => t.coffee),
      SubCategoryConfig(id: 'hotDrinks', title: (t) => t.hotDrinks),
      SubCategoryConfig(id: 'herbalDrinks', title: (t) => t.herbalDrinks),
      SubCategoryConfig(id: 'cola', title: (t) => t.cola),
      SubCategoryConfig(id: 'juice', title: (t) => t.juice),
      SubCategoryConfig(id: 'naturalMilk', title: (t) => t.naturalMilk),
    ],
  ),

  /// FAST FOOD
  CategoryConfig(
    id: 'fastFood',
    icon: AppAssets.categoryRestaurants, // ✅ التصحيح: categoryRestaurants
    subCategories: [
      SubCategoryConfig(id: 'meals', title: (t) => t.meals),
      SubCategoryConfig(id: 'sandwiches', title: (t) => t.sandwiches),
      SubCategoryConfig(id: 'crepe', title: (t) => t.crepe),
      SubCategoryConfig(id: 'pizza', title: (t) => t.pizza),
      SubCategoryConfig(id: 'pies', title: (t) => t.pies),
      SubCategoryConfig(id: 'koshary', title: (t) => t.koshary),
      SubCategoryConfig(id: 'casseroles', title: (t) => t.casseroles),
      SubCategoryConfig(id: 'desserts', title: (t) => t.desserts),
      SubCategoryConfig(id: 'grill', title: (t) => t.grill),
    ],
  ),

  /// MEAT & FISH
  CategoryConfig(
    id: 'meatFish',
    icon: AppAssets.categoryMeatFish,
    subCategories: [
      SubCategoryConfig(id: 'chicken', title: (t) => t.chicken),
      SubCategoryConfig(id: 'chickenPane', title: (t) => t.chickenPane),
      SubCategoryConfig(id: 'meat', title: (t) => t.meat),
      SubCategoryConfig(id: 'mincedMeat', title: (t) => t.mincedMeat),
      SubCategoryConfig(id: 'liver', title: (t) => t.liver),
      SubCategoryConfig(id: 'fish', title: (t) => t.fish),
      SubCategoryConfig(id: 'saltedFish', title: (t) => t.saltedFish),
    ],
  ),

  /// VEGETABLES
  CategoryConfig(
    id: 'vegetables',
    icon: AppAssets.categoryVegetables,
    subCategories: [
      SubCategoryConfig(id: 'tomato', title: (t) => t.tomato),
      SubCategoryConfig(id: 'potato', title: (t) => t.potato),
      SubCategoryConfig(id: 'pepper', title: (t) => t.pepper),
      SubCategoryConfig(id: 'cucumber', title: (t) => t.cucumber),
      SubCategoryConfig(id: 'eggplant', title: (t) => t.eggplant),
      SubCategoryConfig(id: 'carrot', title: (t) => t.carrot),
      SubCategoryConfig(id: 'onion', title: (t) => t.onion),
      SubCategoryConfig(id: 'garlic', title: (t) => t.garlic),
      SubCategoryConfig(id: 'stuffedVeget', title: (t) => t.stuffedVeget),
      SubCategoryConfig(id: 'okra', title: (t) => t.okra),
      SubCategoryConfig(id: 'molokhia', title: (t) => t.molokhia),
      SubCategoryConfig(id: 'spinach', title: (t) => t.spinach),
      SubCategoryConfig(id: 'greens', title: (t) => t.greens),
      SubCategoryConfig(id: 'parsley', title: (t) => t.parsley),
    ],
  ),

  /// FRUITS
  CategoryConfig(
    id: 'fruits',
    icon: AppAssets.categoryFruits,
    subCategories: [
      SubCategoryConfig(id: 'banana', title: (t) => t.banana),
      SubCategoryConfig(id: 'orange', title: (t) => t.orange),
      SubCategoryConfig(id: 'grapes', title: (t) => t.grapes),
      SubCategoryConfig(id: 'apple', title: (t) => t.apple),
      SubCategoryConfig(id: 'guava', title: (t) => t.guava),
      SubCategoryConfig(id: 'pear', title: (t) => t.pear),
      SubCategoryConfig(id: 'mango', title: (t) => t.mango),
      SubCategoryConfig(id: 'strawberry', title: (t) => t.strawberry),
      SubCategoryConfig(id: 'watermelon', title: (t) => t.watermelon),
    ],
  ),

  /// SMOKING
  CategoryConfig(
    id: 'smoking',
    icon: AppAssets.categorySmoking,
    subCategories: [
      SubCategoryConfig(id: 'cigarettes', title: (t) => t.cigarettes),
      SubCategoryConfig(id: 'shisha', title: (t) => t.shisha),
      SubCategoryConfig(id: 'vape', title: (t) => t.vape),
      SubCategoryConfig(id: 'iqos', title: (t) => t.iqos),
    ],
  ),

  /// HEALTH
  CategoryConfig(
    id: 'health',
    icon: AppAssets.categoryHealth,
    subCategories: [
      SubCategoryConfig(id: 'doctorVisit', title: (t) => t.doctorVisit),
      SubCategoryConfig(id: 'medicine', title: (t) => t.medicine),
      SubCategoryConfig(id: 'tests', title: (t) => t.tests),
      SubCategoryConfig(id: 'xray', title: (t) => t.xray),
      SubCategoryConfig(id: 'hospitals', title: (t) => t.hospitals),
      SubCategoryConfig(id: 'operations', title: (t) => t.operations),
    ],
  ),

  /// ENTERTAINMENT
  CategoryConfig(
    id: 'entertainment',
    icon: AppAssets.categoryEntertainment,
    subCategories: [
      SubCategoryConfig(id: 'outings', title: (t) => t.outings),
      SubCategoryConfig(id: 'cafe', title: (t) => t.cafe),
      SubCategoryConfig(id: 'trips', title: (t) => t.trips),
      SubCategoryConfig(id: 'travel', title: (t) => t.travel),
      SubCategoryConfig(id: 'cinema', title: (t) => t.cinema),
      SubCategoryConfig(id: 'amusement', title: (t) => t.amusement),
    ],
  ),

  /// EDUCATION
  CategoryConfig(
    id: 'education',
    icon: AppAssets.categoryEducation,
    subCategories: [
      SubCategoryConfig(id: 'privateLessons', title: (t) => t.privateLessons),
      SubCategoryConfig(id: 'courses', title: (t) => t.courses),
      SubCategoryConfig(id: 'books', title: (t) => t.books),
      SubCategoryConfig(id: 'stationery', title: (t) => t.stationery),
      SubCategoryConfig(id: 'supplies', title: (t) => t.supplies),
      SubCategoryConfig(id: 'schoolFees', title: (t) => t.schoolFees),
      SubCategoryConfig(id: 'universityFees', title: (t) => t.universityFees),
    ],
  ),

  /// VEHICLES
  CategoryConfig(
    id: 'vehicles',
    icon: AppAssets.categoryVehicles,
    subCategories: [
      SubCategoryConfig(id: 'fuel', title: (t) => t.fuel),
      SubCategoryConfig(id: 'oilChange', title: (t) => t.oilChange),
      SubCategoryConfig(id: 'carMaintenance', title: (t) => t.carMaintenance),
      SubCategoryConfig(id: 'vehiclePurchase', title: (t) => t.vehiclePurchase),
      SubCategoryConfig(id: 'spareParts', title: (t) => t.spareParts),
    ],
  ),

  /// HOME
  CategoryConfig(
    id: 'home',
    icon: AppAssets.categoryHome,
    subCategories: [
      SubCategoryConfig(id: 'appliances', title: (t) => t.appliances),
      SubCategoryConfig(id: 'homeMaintenance', title: (t) => t.homeMaintenance),
      SubCategoryConfig(id: 'homeTools', title: (t) => t.homeTools),
      SubCategoryConfig(id: 'homeCleaning', title: (t) => t.homeCleaning),
      SubCategoryConfig(id: 'tissues', title: (t) => t.tissues),
      SubCategoryConfig(id: 'furniture', title: (t) => t.furniture),
      SubCategoryConfig(id: 'sets', title: (t) => t.sets),
    ],
  ),

  /// PERSONAL CARE
  CategoryConfig(
    id: 'personalCare',
    icon: AppAssets.categoryPersonalCare,
    subCategories: [
      SubCategoryConfig(id: 'cosmetics', title: (t) => t.cosmetics),
      SubCategoryConfig(id: 'accessories', title: (t) => t.accessories),
      SubCategoryConfig(id: 'hairCare', title: (t) => t.hairCare),
      SubCategoryConfig(id: 'bodyCare', title: (t) => t.bodyCare),
      SubCategoryConfig(id: 'personalDevices', title: (t) => t.personalDevices),
    ],
  ),

  /// MOBILE & PC
  CategoryConfig(
    id: 'mobilePc',
    icon: AppAssets.categoryMobilePc,
    subCategories: [
      SubCategoryConfig(id: 'techAccessories', title: (t) => t.techAccessories),
      SubCategoryConfig(id: 'techMaintenance', title: (t) => t.techMaintenance),
      SubCategoryConfig(id: 'chargers', title: (t) => t.chargers),
      SubCategoryConfig(id: 'headphones', title: (t) => t.headphones),
    ],
  ),

  /// FINANCIALS
  CategoryConfig(
    id: 'financials',
    icon: AppAssets.categoryFinancialCommitments,
    subCategories: [
      SubCategoryConfig(id: 'savingGroup', title: (t) => t.savingGroup),
      SubCategoryConfig(id: 'loan', title: (t) => t.loan),
      SubCategoryConfig(id: 'installments', title: (t) => t.installments),
      SubCategoryConfig(id: 'socialInsurance', title: (t) => t.socialInsurance),
      SubCategoryConfig(id: 'healthInsurance', title: (t) => t.healthInsurance),
      SubCategoryConfig(id: 'carInsurance', title: (t) => t.carInsurance),
      SubCategoryConfig(id: 'digitalSubs', title: (t) => t.digitalSubs),
      SubCategoryConfig(id: 'debts', title: (t) => t.debts),
    ],
  ),

  /// GOVERNMENT SERVICES
  CategoryConfig(
    id: 'governServices',
    icon: AppAssets.categoryGovernmentServices,
    subCategories: [
      SubCategoryConfig(id: 'fees', title: (t) => t.fees),
      SubCategoryConfig(id: 'documents', title: (t) => t.documents),
      SubCategoryConfig(id: 'violations', title: (t) => t.violations),
    ],
  ),

  /// GIFTS & OCCASIONS
  CategoryConfig(
    id: 'giftsOccasions',
    icon: AppAssets.categoryGiftsOccasions,
    subCategories: [
      SubCategoryConfig(id: 'birthdays', title: (t) => t.birthdays),
      SubCategoryConfig(id: 'weddings', title: (t) => t.weddings),
      SubCategoryConfig(id: 'familyVisits', title: (t) => t.familyVisits),
      SubCategoryConfig(id: 'hospitalVisits', title: (t) => t.hospitalVisits),
      SubCategoryConfig(id: 'eidMoney', title: (t) => t.eidMoney),
      SubCategoryConfig(id: 'gifts', title: (t) => t.gifts),
    ],
  ),

  /// HOBBIES
  CategoryConfig(
    id: 'hobbies',
    icon: AppAssets.categoryHobbies,
    subCategories: [
      SubCategoryConfig(id: 'sportsSubscriptions', title: (t) => t.sportsSubscriptions),
      SubCategoryConfig(id: 'sportsEquipment', title: (t) => t.sportsEquipment),
      SubCategoryConfig(id: 'sportsSupplements', title: (t) => t.sportsSupplements),
      SubCategoryConfig(id: 'pets', title: (t) => t.pets),
      SubCategoryConfig(id: 'videoGames', title: (t) => t.videoGames),
      SubCategoryConfig(id: 'skating', title: (t) => t.skating),
      SubCategoryConfig(id: 'gardeningAndPlants', title: (t) => t.gardeningAndPlants),
      SubCategoryConfig(id: 'reading', title: (t) => t.reading),
      SubCategoryConfig(id: 'music', title: (t) => t.music),
      SubCategoryConfig(id: 'arts', title: (t) => t.arts),
      SubCategoryConfig(id: 'photography', title: (t) => t.photography),
      SubCategoryConfig(id: 'handmade', title: (t) => t.handmade),
    ],
  ),

  /// BABY
  CategoryConfig(
    id: 'baby',
    icon: AppAssets.categoryBaby,
    subCategories: [
      SubCategoryConfig(id: 'babyMilk', title: (t) => t.babyMilk),
      SubCategoryConfig(id: 'babyFood', title: (t) => t.babyFood),
      SubCategoryConfig(id: 'diapers', title: (t) => t.diapers),
      SubCategoryConfig(id: 'babyCleaning', title: (t) => t.babyCleaning),
      SubCategoryConfig(id: 'babyClothes', title: (t) => t.babyClothes),
      SubCategoryConfig(id: 'babyToys', title: (t) => t.babyToys),
    ],
  ),

  /// CLOTHES
  CategoryConfig(
    id: 'clothes',
    icon: AppAssets.categoryClothes,
    subCategories: [
      SubCategoryConfig(id: 'shirt', title: (t) => t.shirt),
      SubCategoryConfig(id: 'pants', title: (t) => t.pants),
      SubCategoryConfig(id: 'suit', title: (t) => t.suit),
      SubCategoryConfig(id: 'jacket', title: (t) => t.jacket),
      SubCategoryConfig(id: 'underwear', title: (t) => t.underwear),
      SubCategoryConfig(id: 'tshirt', title: (t) => t.tshirt),
      SubCategoryConfig(id: 'blouse', title: (t) => t.blouse),
      SubCategoryConfig(id: 'dress', title: (t) => t.dress),
      SubCategoryConfig(id: 'socks', title: (t) => t.socks),
    ],
  ),

  /// SHOES
  CategoryConfig(
    id: 'shoes',
    icon: AppAssets.categoryShoes,
    subCategories: [
      SubCategoryConfig(id: 'shoe', title: (t) => t.shoe),
      SubCategoryConfig(id: 'sneakers', title: (t) => t.sneakers),
      SubCategoryConfig(id: 'sandal', title: (t) => t.sandal),
      SubCategoryConfig(id: 'slipper', title: (t) => t.slipper),
      SubCategoryConfig(id: 'crocs', title: (t) => t.crocs),
    ],
  ),
];