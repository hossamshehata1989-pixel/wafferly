import '../categories/category.dart';

const List<Category> mainCategories = [

  /// TRANSPORT
  Category(
    id: 'transport',
    titleKey: 'transport',
    subCategories: [
      SubCategory(id: 'tuktuk', titleKey: 'tuktuk'),
      SubCategory(id: 'microbus', titleKey: 'microbus'),
      SubCategory(id: 'taxiUber', titleKey: 'taxiUber'),
      SubCategory(id: 'bus', titleKey: 'bus'),
      SubCategory(id: 'metro', titleKey: 'metro'),
      SubCategory(id: 'train', titleKey: 'train'),
    ],
  ),

  /// BILLS
  Category(
    id: 'bills',
    titleKey: 'bills',
    subCategories: [
      SubCategory(id: 'electricity', titleKey: 'electricity'),
      SubCategory(id: 'gas', titleKey: 'gas'),
      SubCategory(id: 'water', titleKey: 'water'),
      SubCategory(id: 'mobile_credit', titleKey: 'mobile_credit'),
      SubCategory(id: 'mobile_package', titleKey: 'mobile_package'),
      SubCategory(id: 'home_internet', titleKey: 'home_internet'),
      SubCategory(id: 'landline_bill', titleKey: 'landline_bill'),
      SubCategory(id: 'elevator_maintenance', titleKey: 'elevator_maintenance'),
      SubCategory(id: 'cleaning_fees', titleKey: 'cleaning_fees'),
      SubCategory(id: 'building_security', titleKey: 'building_security'),
    ],
  ),

  /// SUPERMARKET
  Category(
    id: 'supermarket',
    titleKey: 'supermarket',
    subCategories: [
      SubCategory(id: 'milk', titleKey: 'milk'),
      SubCategory(id: 'cheese', titleKey: 'cheese'),
      SubCategory(id: 'yogurt', titleKey: 'yogurt'),
      SubCategory(id: 'eggs', titleKey: 'eggs'),
      SubCategory(id: 'canned_food', titleKey: 'canned_food'),
      SubCategory(id: 'bread', titleKey: 'bread'),
      SubCategory(id: 'rice', titleKey: 'rice'),
      SubCategory(id: 'pasta', titleKey: 'pasta'),
      SubCategory(id: 'oil_ghee', titleKey: 'oil_ghee'),
      SubCategory(id: 'sugar', titleKey: 'sugar'),
      SubCategory(id: 'tea', titleKey: 'tea'),
      SubCategory(id: 'coffee', titleKey: 'coffee'),
      SubCategory(id: 'legumes', titleKey: 'legumes'),
      SubCategory(id: 'spices', titleKey: 'spices'),
      SubCategory(id: 'snacks_biscuits', titleKey: 'snacks_biscuits'),
    ],
  ),

  /// RESTAURANTS
  Category(
    id: 'restaurants',
    titleKey: 'eatOut',
    subCategories: [
      SubCategory(id: 'meals', titleKey: 'meals'),
      SubCategory(id: 'sandwiches', titleKey: 'sandwiches'),
      SubCategory(id: 'crepe', titleKey: 'crepe'),
      SubCategory(id: 'pizza', titleKey: 'pizza'),
      SubCategory(id: 'pies', titleKey: 'pies'),
      SubCategory(id: 'koshary', titleKey: 'koshary'),
      SubCategory(id: 'casseroles', titleKey: 'casseroles'),
      SubCategory(id: 'desserts', titleKey: 'desserts'),
      SubCategory(id: 'grill', titleKey: 'grill'),
    ],
  ),

  /// MEAT & FISH
  Category(
    id: 'meatFish',
    titleKey: 'meatFish',
    subCategories: [
      SubCategory(id: 'meat', titleKey: 'meat'),
      SubCategory(id: 'poultry', titleKey: 'poultry'),
      SubCategory(id: 'fish', titleKey: 'fish'),
      SubCategory(id: 'salted_fish', titleKey: 'salted_fish'),
    ],
  ),

  /// VEGETABLES
  Category(
    id: 'vegetables',
    titleKey: 'vegetables',
    subCategories: [
      SubCategory(id: 'tomato', titleKey: 'tomato'),
      SubCategory(id: 'potato', titleKey: 'potato'),
      SubCategory(id: 'pepper', titleKey: 'pepper'),
      SubCategory(id: 'cucumber', titleKey: 'cucumber'),
      SubCategory(id: 'eggplant', titleKey: 'eggplant'),
      SubCategory(id: 'parsley', titleKey: 'parsley'),
    ],
  ),

  /// FRUITS
  Category(
    id: 'fruits',
    titleKey: 'fruits',
    subCategories: [
      SubCategory(id: 'banana', titleKey: 'banana'),
      SubCategory(id: 'orange', titleKey: 'orange'),
      SubCategory(id: 'grapes', titleKey: 'grapes'),
      SubCategory(id: 'apple', titleKey: 'apple'),
      SubCategory(id: 'guava', titleKey: 'guava'),
      SubCategory(id: 'pear', titleKey: 'pear'),
      SubCategory(id: 'mango', titleKey: 'mango'),
      SubCategory(id: 'watermelon', titleKey: 'watermelon'),
    ],
  ),

  /// SMOKING
  Category(
    id: 'smoking',
    titleKey: 'smoking',
    subCategories: [
      SubCategory(id: 'cigarettes', titleKey: 'cigarettes'),
      SubCategory(id: 'shisha', titleKey: 'shisha'),
      SubCategory(id: 'vape', titleKey: 'vape'),
      SubCategory(id: 'iqos', titleKey: 'iqos'),
    ],
  ),

  /// HEALTH
  Category(
    id: 'health',
    titleKey: 'health',
    subCategories: [
      SubCategory(id: 'doctor_visit', titleKey: 'doctor_visit'),
      SubCategory(id: 'medicine', titleKey: 'medicine'),
      SubCategory(id: 'tests', titleKey: 'tests'),
      SubCategory(id: 'xray', titleKey: 'xray'),
      SubCategory(id: 'hospitals', titleKey: 'hospitals'),
      SubCategory(id: 'operations', titleKey: 'operations'),
    ],
  ),

  /// ENTERTAINMENT
  Category(
    id: 'entertainment',
    titleKey: 'entertainment',
    subCategories: [
      SubCategory(id: 'outings', titleKey: 'outings'),
      SubCategory(id: 'cafe', titleKey: 'cafe'),
      SubCategory(id: 'trips', titleKey: 'trips'),
      SubCategory(id: 'travel', titleKey: 'travel'),
      SubCategory(id: 'cinema', titleKey: 'cinema'),
      SubCategory(id: 'amusement', titleKey: 'amusement'),
    ],
  ),

  /// EDUCATION
  Category(
    id: 'education',
    titleKey: 'education',
    subCategories: [
      SubCategory(id: 'private_lessons', titleKey: 'private_lessons'),
      SubCategory(id: 'courses', titleKey: 'courses'),
      SubCategory(id: 'books', titleKey: 'books'),
      SubCategory(id: 'stationery', titleKey: 'stationery'),
      SubCategory(id: 'school_fees', titleKey: 'school_fees'),
      SubCategory(id: 'university_fees', titleKey: 'university_fees'),
    ],
  ),

  /// VEHICLES
  Category(
    id: 'vehicles',
    titleKey: 'vehicles',
    subCategories: [
      SubCategory(id: 'fuel', titleKey: 'fuel'),
      SubCategory(id: 'oil_change', titleKey: 'oil_change'),
      SubCategory(id: 'car_maintenance', titleKey: 'car_maintenance'),
      SubCategory(id: 'vehicle_purchase', titleKey: 'vehicle_purchase'),
      SubCategory(id: 'spare_parts', titleKey: 'spare_parts'),
    ],
  ),

  /// HOME
  Category(
    id: 'home',
    titleKey: 'home',
    subCategories: [
      SubCategory(id: 'appliances', titleKey: 'appliances'),
      SubCategory(id: 'home_maintenance', titleKey: 'home_maintenance'),
      SubCategory(id: 'home_tools', titleKey: 'home_tools'),
      SubCategory(id: 'home_cleaning', titleKey: 'home_cleaning'),
      SubCategory(id: 'tissues', titleKey: 'tissues'),
      SubCategory(id: 'furniture', titleKey: 'furniture'),
      SubCategory(id: 'sets', titleKey: 'sets'),
    ],
  ),

  /// PERSONAL CARE
  Category(
    id: 'personalCare',
    titleKey: 'personalCare',
    subCategories: [
      SubCategory(id: 'cosmetics', titleKey: 'cosmetics'),
      SubCategory(id: 'accessories', titleKey: 'accessories'),
      SubCategory(id: 'hair_care', titleKey: 'hair_care'),
      SubCategory(id: 'body_care', titleKey: 'body_care'),
      SubCategory(id: 'personal_devices', titleKey: 'personal_devices'),
    ],
  ),

  /// TECH
  Category(
    id: 'mobilePc',
    titleKey: 'mobilePc',
    subCategories: [
      SubCategory(id: 'tech_accessories', titleKey: 'tech_accessories'),
      SubCategory(id: 'tech_maintenance', titleKey: 'tech_maintenance'),
      SubCategory(id: 'chargers', titleKey: 'chargers'),
      SubCategory(id: 'headphones', titleKey: 'headphones'),
    ],
  ),

  /// FINANCIAL
  Category(
    id: 'financialCommitments',
    titleKey: 'financialCommitments',
    subCategories: [
      SubCategory(id: 'saving_group', titleKey: 'saving_group'),
      SubCategory(id: 'loan', titleKey: 'loan'),
      SubCategory(id: 'installments', titleKey: 'installments'),
      SubCategory(id: 'social_insurance', titleKey: 'social_insurance'),
      SubCategory(id: 'health_insurance', titleKey: 'health_insurance'),
      SubCategory(id: 'car_insurance', titleKey: 'car_insurance'),
      SubCategory(id: 'digital_subscriptions', titleKey: 'digital_subscriptions'),
      SubCategory(id: 'debts', titleKey: 'debts'),
    ],
  ),

  /// GOVERNMENT
  Category(
    id: 'governmentServices',
    titleKey: 'governmentServices',
    subCategories: [
      SubCategory(id: 'fees', titleKey: 'fees'),
      SubCategory(id: 'documents', titleKey: 'documents'),
      SubCategory(id: 'violations', titleKey: 'violations'),
    ],
  ),

  /// GIFTS
  Category(
    id: 'giftsOccasions',
    titleKey: 'giftsOccasions',
    subCategories: [
      SubCategory(id: 'birthdays', titleKey: 'birthdays'),
      SubCategory(id: 'weddings', titleKey: 'weddings'),
      SubCategory(id: 'family_visits', titleKey: 'family_visits'),
      SubCategory(id: 'hospital_visits', titleKey: 'hospital_visits'),
      SubCategory(id: 'eid_money', titleKey: 'eid_money'),
      SubCategory(id: 'gifts', titleKey: 'gifts'),
    ],
  ),

  /// HOBBIES
  Category(
    id: 'hobbies',
    titleKey: 'hobbies',
    subCategories: [
      SubCategory(id: 'club_tools', titleKey: 'club_tools'),
      SubCategory(id: 'club_membership', titleKey: 'club_membership'),
      SubCategory(id: 'gym_membership', titleKey: 'gym_membership'),
      SubCategory(id: 'gym_tools', titleKey: 'gym_tools'),
    ],
  ),

  /// BABY
  Category(
    id: 'baby',
    titleKey: 'baby',
    subCategories: [
      SubCategory(id: 'baby_milk', titleKey: 'baby_milk'),
      SubCategory(id: 'diapers', titleKey: 'diapers'),
      SubCategory(id: 'baby_cleaning', titleKey: 'baby_cleaning'),
      SubCategory(id: 'baby_clothes', titleKey: 'baby_clothes'),
      SubCategory(id: 'baby_toys', titleKey: 'baby_toys'),
    ],
  ),

  /// CLOTHES
  Category(
    id: 'clothes',
    titleKey: 'clothes',
    subCategories: [
      SubCategory(id: 'shirt', titleKey: 'shirt'),
      SubCategory(id: 'pants', titleKey: 'pants'),
      SubCategory(id: 'suit', titleKey: 'suit'),
      SubCategory(id: 'jacket', titleKey: 'jacket'),
      SubCategory(id: 'underwear', titleKey: 'underwear'),
      SubCategory(id: 'tshirt', titleKey: 'tshirt'),
      SubCategory(id: 'blouse', titleKey: 'blouse'),
      SubCategory(id: 'dress', titleKey: 'dress'),
      SubCategory(id: 'socks', titleKey: 'socks'),
    ],
  ),

  /// SHOES
  Category(
    id: 'shoes',
    titleKey: 'shoes',
    subCategories: [
      SubCategory(id: 'shoe', titleKey: 'shoe'),
      SubCategory(id: 'boot', titleKey: 'boot'),
      SubCategory(id: 'sandal', titleKey: 'sandal'),
      SubCategory(id: 'slipper', titleKey: 'slipper'),
      SubCategory(id: 'crocs', titleKey: 'crocs'),
    ],
  ),
];
