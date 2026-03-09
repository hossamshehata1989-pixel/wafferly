import '../categories/category.dart';

final List<Category> mainCategories = [

  /// DAILY TRANSPORT
  Category(
    id: 'dailyTransport',
    title: (t) => t.dailyTransport,
    subCategories: [
      SubCategory(id: 'tuktuk', title: (t) => t.tuktuk),
      SubCategory(id: 'microbus', title: (t) => t.microbus),
      SubCategory(id: 'taxiUber', title: (t) => t.taxiUber),
      SubCategory(id: 'bus', title: (t) => t.bus),
      SubCategory(id: 'metro', title: (t) => t.metro),
      SubCategory(id: 'train', title: (t) => t.train),
    ],
  ),

  /// BILLS
  Category(
    id: 'bills',
    title: (t) => t.bills,
    subCategories: [
      SubCategory(id: 'electricityBill', title: (t) => t.electricityBill),
      SubCategory(id: 'waterBill', title: (t) => t.waterBill),
      SubCategory(id: 'gasBill', title: (t) => t.gasBill),
      SubCategory(id: 'mobileRecharge', title: (t) => t.mobileRecharge),
      SubCategory(id: 'mobileInternet', title: (t) => t.mobileInternet),
      SubCategory(id: 'wifi', title: (t) => t.wifi),
      SubCategory(id: 'landlineBill', title: (t) => t.landlineBill),
      SubCategory(id: 'elevatorMaint', title: (t) => t.elevatorMaint),
      SubCategory(id: 'cleaningFees', title: (t) => t.cleaningFees),
      SubCategory(id: 'buildSecurity', title: (t) => t.buildSecurity),
    ],
  ),

  /// SUPERMARKET
  Category(
    id: 'supermarket',
    title: (t) => t.supermarket,
    subCategories: [
      SubCategory(id: 'waterBottle', title: (t) => t.waterBottle),
      SubCategory(id: 'milkPack', title: (t) => t.milkPack),
      SubCategory(id: 'cheese', title: (t) => t.cheese),
      SubCategory(id: 'yogurt', title: (t) => t.yogurt),
      SubCategory(id: 'eggs', title: (t) => t.eggs),
      SubCategory(id: 'cannedFood', title: (t) => t.cannedFood),
      SubCategory(id: 'bread', title: (t) => t.bread),
      SubCategory(id: 'rice', title: (t) => t.rice),
      SubCategory(id: 'pasta', title: (t) => t.pasta),
      SubCategory(id: 'oil', title: (t) => t.oil),
      SubCategory(id: 'ghee', title: (t) => t.ghee),
      SubCategory(id: 'sugar', title: (t) => t.sugar),
      SubCategory(id: 'teaPack', title: (t) => t.teaPack),
      SubCategory(id: 'coffeePack', title: (t) => t.coffeePack),
      SubCategory(id: 'legumes', title: (t) => t.legumes),
      SubCategory(id: 'frozenFood', title: (t) => t.frozenFood),
      SubCategory(id: 'spices', title: (t) => t.spices),
      SubCategory(id: 'snacks', title: (t) => t.snacks),
      SubCategory(id: 'biscuits', title: (t) => t.biscuits),
    ],
  ),

  /// DRINKS
  Category(
    id: 'drinks',
    title: (t) => t.drinks,
    subCategories: [

      SubCategory(id: 'tea', title: (t) => t.tea),
      SubCategory(id: 'coffee', title: (t) => t.coffee),
      SubCategory(id: 'hotDrinks', title: (t) => t.hotDrinks),
      SubCategory(id: 'herbalDrinks', title: (t) => t.herbalDrinks),
      SubCategory(id: 'cola', title: (t) => t.cola),
      SubCategory(id: 'juice', title: (t) => t.juice),
      SubCategory(id: 'naturalMilk', title: (t) => t.naturalMilk),
    ],
  ),

  /// FAST FOOD
  Category(
    id: 'fastFood',
    title: (t) => t.fastFood,
    subCategories: [

      SubCategory(id: 'meals', title: (t) => t.meals),
      SubCategory(id: 'sandwiches', title: (t) => t.sandwiches),
      SubCategory(id: 'crepe', title: (t) => t.crepe),
      SubCategory(id: 'pizza', title: (t) => t.pizza),
      SubCategory(id: 'pies', title: (t) => t.pies),
      SubCategory(id: 'koshary', title: (t) => t.koshary),
      SubCategory(id: 'casseroles', title: (t) => t.casseroles),
      SubCategory(id: 'desserts', title: (t) => t.desserts),
      SubCategory(id: 'grill', title: (t) => t.grill),
    ],
  ),

  /// MEAT & FISH
  Category(
    id: 'meatAndFish',
    title: (t) => t.meatFish,
    subCategories: [
      SubCategory(id: 'chicken', title: (t) => t.chicken),
      SubCategory(id: 'chickenPane', title: (t) => t.chickenPane),
      SubCategory(id: 'meat', title: (t) => t.meat),
      SubCategory(id: 'mincedMeat', title: (t) => t.mincedMeat),
      SubCategory(id: 'liver', title: (t) => t.liver),
      SubCategory(id: 'fish', title: (t) => t.fish),
      SubCategory(id: 'saltedFish', title: (t) => t.saltedFish),
    ],
  ),

  /// VEGETABLES
  Category(
    id: 'vegetables',
    title: (t) => t.vegetables,
    subCategories: [
      SubCategory(id: 'tomato', title: (t) => t.tomato),
      SubCategory(id: 'potato', title: (t) => t.potato),
      SubCategory(id: 'pepper', title: (t) => t.pepper),
      SubCategory(id: 'cucumber', title: (t) => t.cucumber),
      SubCategory(id: 'eggplant', title: (t) => t.eggplant),
      SubCategory(id: 'carrot', title: (t) => t.carrot),  
      SubCategory(id: 'onion', title: (t) => t.onion),
      SubCategory(id: 'garlic', title: (t) => t.garlic),
      SubCategory(id: 'stuffedVeget', title: (t) => t.stuffedVeget),
      SubCategory(id: 'okra', title: (t) => t.okra),
      SubCategory(id: 'molokhia', title: (t) => t.molokhia),
      SubCategory(id: 'spinach', title: (t) => t.spinach),
      SubCategory(id: 'greens', title: (t) => t.greens),
      SubCategory(id: 'parsley', title: (t) => t.parsley),
    ],
  ),

  /// FRUITS
  Category(
    id: 'fruits',
    title: (t) => t.fruits,
    subCategories: [
      SubCategory(id: 'banana', title: (t) => t.banana),
      SubCategory(id: 'orange', title: (t) => t.orange),
      SubCategory(id: 'grapes', title: (t) => t.grapes),
      SubCategory(id: 'apple', title: (t) => t.apple),
      SubCategory(id: 'guava', title: (t) => t.guava),
      SubCategory(id: 'pear', title: (t) => t.pear),
      SubCategory(id: 'mango', title: (t) => t.mango),
      SubCategory(id: 'strawberry', title: (t) => t.strawberry),
      SubCategory(id: 'watermelon', title: (t) => t.watermelon),
    ],
  ),

  /// SMOKING
  Category(
    id: 'smoking',
    title: (t) => t.smoking,
    subCategories: [
      SubCategory(id: 'cigarettes', title: (t) => t.cigarettes),
      SubCategory(id: 'shisha', title: (t) => t.shisha),
      SubCategory(id: 'vape', title: (t) => t.vape),
      SubCategory(id: 'iqos', title: (t) => t.iqos),
    ],
  ),

  /// HEALTH
  Category(
    id: 'health',
    title: (t) => t.health,
    subCategories: [
      SubCategory(id: 'doctorVisit', title: (t) => t.doctorVisit),
      SubCategory(id: 'medicine', title: (t) => t.medicine),
      SubCategory(id: 'tests', title: (t) => t.tests),
      SubCategory(id: 'xray', title: (t) => t.xray),
      SubCategory(id: 'hospitals', title: (t) => t.hospitals),
      SubCategory(id: 'operations', title: (t) => t.operations),
    ],
  ),

  /// ENTERTAINMENT
  Category(
    id: 'entertainment',
    title: (t) => t.entertainment,
    subCategories: [
      SubCategory(id: 'outings', title: (t) => t.outings),
      SubCategory(id: 'cafe', title: (t) => t.cafe),
      SubCategory(id: 'trips', title: (t) => t.trips),
      SubCategory(id: 'travel', title: (t) => t.travel),
      SubCategory(id: 'cinema', title: (t) => t.cinema),
      SubCategory(id: 'amusement', title: (t) => t.amusement),
    ],
  ),

  /// EDUCATION
  Category(
    id: 'education',
    title: (t) => t.education,
    subCategories: [
      SubCategory(id: 'privateLessons', title: (t) => t.privateLessons),
      SubCategory(id: 'courses', title: (t) => t.courses),
      SubCategory(id: 'books', title: (t) => t.books),
      SubCategory(id: 'stationery', title: (t) => t.stationery),
      SubCategory(id: 'supplies', title: (t) => t.supplies),
      SubCategory(id: 'schoolFees', title: (t) => t.schoolFees),
      SubCategory(id: 'universityFees', title: (t) => t.universityFees),
    ],
  ),

  /// VEHICLES
  Category(
    id: 'vehicles',
    title: (t) => t.vehicles,
    subCategories: [
      SubCategory(id: 'fuel', title: (t) => t.fuel),
      SubCategory(id: 'oilChange', title: (t) => t.oilChange),
      SubCategory(id: 'carMaintenance', title: (t) => t.carMaintenance),
      SubCategory(id: 'vehiclePurchase', title: (t) => t.vehiclePurchase),
      SubCategory(id: 'spareParts', title: (t) => t.spareParts),
    ],
  ),

  /// HOME
  Category(
    id: 'home',
    title: (t) => t.home,
    subCategories: [
      SubCategory(id: 'appliances', title: (t) => t.appliances),
      SubCategory(id: 'homeMaintenance', title: (t) => t.homeMaintenance),
      SubCategory(id: 'homeTools', title: (t) => t.homeTools),
      SubCategory(id: 'homeCleaning', title: (t) => t.homeCleaning),
      SubCategory(id: 'tissues', title: (t) => t.tissues),
      SubCategory(id: 'furniture', title: (t) => t.furniture),
      SubCategory(id: 'sets', title: (t) => t.sets),
    ],
  ),

  /// PERSONAL CARE
  Category(
    id: 'personalCare',
    title: (t) => t.personalCare,
    subCategories: [
      SubCategory(id: 'cosmetics', title: (t) => t.cosmetics),
      SubCategory(id: 'accessories', title: (t) => t.accessories),
      SubCategory(id: 'hairCare', title: (t) => t.hairCare),
      SubCategory(id: 'bodyCare', title: (t) => t.bodyCare),
      SubCategory(id: 'personalDevices', title: (t) => t.personalDevices),
    ],
  ),

  /// MOBILE & PC
  Category(
    id: 'mobilePc',
    title: (t) => t.mobilePc,
    subCategories: [
      SubCategory(id: 'techAccessories', title: (t) => t.techAccessories),
      SubCategory(id: 'techMaintenance', title: (t) => t.techMaintenance),
      SubCategory(id: 'chargers', title: (t) => t.chargers),
      SubCategory(id: 'headphones', title: (t) => t.headphones),
    ],
  ),

  /// FINANCIALS
  Category(
    id: 'financials',
    title: (t) => t.financials,
    subCategories: [
      SubCategory(id: 'savingGroup', title: (t) => t.savingGroup),
      SubCategory(id: 'loan', title: (t) => t.loan),
      SubCategory(id: 'installments', title: (t) => t.installments),
      SubCategory(id: 'socialInsurance', title: (t) => t.socialInsurance),
      SubCategory(id: 'healthInsurance', title: (t) => t.healthInsurance),
      SubCategory(id: 'carInsurance', title: (t) => t.carInsurance),
      SubCategory(id: 'digitalSubs', title: (t) => t.digitalSubs),
      SubCategory(id: 'debts', title: (t) => t.debts),
    ],
  ),

  /// GOVERNMENT
  Category(
    id: 'governServices',
    title: (t) => t.governServices,
    subCategories: [
      SubCategory(id: 'fees', title: (t) => t.fees),
      SubCategory(id: 'documents', title: (t) => t.documents),
      SubCategory(id: 'violations', title: (t) => t.violations),
    ],
  ),

  /// GIFTS
  Category(
    id: 'giftsOccasions',
    title: (t) => t.giftsOccasions,
    subCategories: [
      SubCategory(id: 'birthdays', title: (t) => t.birthdays),
      SubCategory(id: 'weddings', title: (t) => t.weddings),
      SubCategory(id: 'familyVisits', title: (t) => t.familyVisits),
      SubCategory(id: 'hospitalVisits', title: (t) => t.hospitalVisits),
      SubCategory(id: 'eidMoney', title: (t) => t.eidMoney),
      SubCategory(id: 'gifts', title: (t) => t.gifts),
    ],
  ),

  /// HOBBIES
  Category(
    id: 'hobbies',
    title: (t) => t.hobbies,
    subCategories: [
      SubCategory(id: 'sportsSubscriptions', title: (t) => t.sportsSubscriptions),
      SubCategory(id: 'sportsEquipment', title: (t) => t.sportsEquipment),
      SubCategory(id: 'sportsSupplements', title: (t) => t.sportsSupplements),
      SubCategory(id: 'pets', title: (t) => t.pets),
      SubCategory(id: 'videoGames', title: (t) => t.videoGames),
      SubCategory(id: 'skating', title: (t) => t.skating),
      SubCategory(id: 'gardeningAndPlants', title: (t) => t.gardeningAndPlants),
      SubCategory(id: 'reading', title: (t) => t.reading),
      SubCategory(id: 'music', title: (t) => t.music),
      SubCategory(id: 'arts', title: (t) => t.arts),
      SubCategory(id: 'photography', title: (t) => t.photography),
     SubCategory(id: 'handmade', title: (t) => t.handmade),

    ],
  ),

  /// BABY
  Category(
    id: 'baby',
    title: (t) => t.baby,
    subCategories: [
      SubCategory(id: 'babyMilk', title: (t) => t.babyMilk),
      SubCategory(id: 'babyFood', title: (t) => t.babyFood),
      SubCategory(id: 'diapers', title: (t) => t.diapers),
      SubCategory(id: 'babyCleaning', title: (t) => t.babyCleaning),
      SubCategory(id: 'babyClothes', title: (t) => t.babyClothes),
      SubCategory(id: 'babyToys', title: (t) => t.babyToys),
    ],
  ),

  /// CLOTHES
  Category(
    id: 'clothes',
    title: (t) => t.clothes,
    subCategories: [
      SubCategory(id: 'shirt', title: (t) => t.shirt),
      SubCategory(id: 'pants', title: (t) => t.pants),
      SubCategory(id: 'suit', title: (t) => t.suit),
      SubCategory(id: 'jacket', title: (t) => t.jacket),
      SubCategory(id: 'underwear', title: (t) => t.underwear),
      SubCategory(id: 'tshirt', title: (t) => t.tshirt),
      SubCategory(id: 'blouse', title: (t) => t.blouse),
      SubCategory(id: 'dress', title: (t) => t.dress),
      SubCategory(id: 'socks', title: (t) => t.socks),
    ],
  ),

  /// SHOES
  Category(
    id: 'shoes',
    title: (t) => t.shoes,
    subCategories: [
      SubCategory(id: 'shoe', title: (t) => t.shoe),
      SubCategory(id: 'sneakers', title: (t) => t.sneakers),
      SubCategory(id: 'sandal', title: (t) => t.sandal),
      SubCategory(id: 'slipper', title: (t) => t.slipper),
      SubCategory(id: 'crocs', title: (t) => t.crocs),
    ],
  ),

];