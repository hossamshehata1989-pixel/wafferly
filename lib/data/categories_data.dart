import '../categories/category.dart';

final List<Category> categories = [

  Category(
    id: 1,
    titleKey: 'transport',
    icon: 'transport',
    subCategories: [
      SubCategory(titleKey: 'tuktuk', icon: 'tuktuk'),
      SubCategory(titleKey: 'microbus', icon: 'microbus'),
      SubCategory(titleKey: 'taxi_uber', icon: 'taxi'),
      SubCategory(titleKey: 'bus', icon: 'bus'),
      SubCategory(titleKey: 'metro', icon: 'metro'),
      SubCategory(titleKey: 'train', icon: 'train'),
    ],
  ),

  Category(
    id: 2,
    titleKey: 'bills',
    icon: 'bills',
    subCategories: [
      SubCategory(titleKey: 'electricity', icon: 'electricity'),
      SubCategory(titleKey: 'gas', icon: 'gas'),
      SubCategory(titleKey: 'water', icon: 'water'),
      SubCategory(titleKey: 'mobile_credit', icon: 'mobile'),
      SubCategory(titleKey: 'mobile_package', icon: 'mobile_data'),
      SubCategory(titleKey: 'home_internet', icon: 'wifi'),
      SubCategory(titleKey: 'landline_bill', icon: 'phone'),
      SubCategory(titleKey: 'elevator_maintenance', icon: 'maintenance'),
      SubCategory(titleKey: 'cleaning_fees', icon: 'cleaning'),
      SubCategory(titleKey: 'building_security', icon: 'security'),
    ],
  ),

  Category(
    id: 3,
    titleKey: 'supermarket',
    icon: 'supermarket',
    subCategories: [
      SubCategory(titleKey: 'milk', icon: 'milk'),
      SubCategory(titleKey: 'cheese', icon: 'cheese'),
      SubCategory(titleKey: 'yogurt', icon: 'yogurt'),
      SubCategory(titleKey: 'eggs', icon: 'eggs'),
      SubCategory(titleKey: 'canned_food', icon: 'canned'),
      SubCategory(titleKey: 'bread', icon: 'bread'),
      SubCategory(titleKey: 'rice', icon: 'rice'),
      SubCategory(titleKey: 'pasta', icon: 'pasta'),
      SubCategory(titleKey: 'oil_ghee', icon: 'oil'),
      SubCategory(titleKey: 'sugar', icon: 'sugar'),
      SubCategory(titleKey: 'tea', icon: 'tea'),
      SubCategory(titleKey: 'coffee', icon: 'coffee'),
      SubCategory(titleKey: 'legumes', icon: 'beans'),
      SubCategory(titleKey: 'spices', icon: 'spices'),
      SubCategory(titleKey: 'snacks_biscuits', icon: 'snacks'),
    ],
  ),

  Category(
    id: 4,
    titleKey: 'eat_out',
    icon: 'restaurant',
    subCategories: [
      SubCategory(titleKey: 'meals', icon: 'meal'),
      SubCategory(titleKey: 'sandwiches', icon: 'sandwich'),
      SubCategory(titleKey: 'crepe', icon: 'crepe'),
      SubCategory(titleKey: 'pizza', icon: 'pizza'),
      SubCategory(titleKey: 'pies', icon: 'pie'),
      SubCategory(titleKey: 'koshary', icon: 'koshary'),
      SubCategory(titleKey: 'casseroles', icon: 'food'),
      SubCategory(titleKey: 'desserts', icon: 'dessert'),
      SubCategory(titleKey: 'grill', icon: 'grill'),
    ],
  ),

 Category(            
    id: 5,
    titleKey: 'meat_fish',
    icon: 'meat',
    subCategories: [
      SubCategory(titleKey: 'meat', icon: 'meat'),
      SubCategory(titleKey: 'poultry', icon: 'chicken'),
      SubCategory(titleKey: 'fish', icon: 'fish'),
      SubCategory(titleKey: 'salted_fish', icon: 'fish'),
    ],
  ),

  Category(
    id: 6,
    titleKey: 'vegetables',
    icon: 'vegetables',
    subCategories: [
      SubCategory(titleKey: 'tomato', icon: 'tomato'),
      SubCategory(titleKey: 'potato', icon: 'potato'),
      SubCategory(titleKey: 'pepper', icon: 'pepper'),
      SubCategory(titleKey: 'cucumber', icon: 'cucumber'),
      SubCategory(titleKey: 'eggplant', icon: 'eggplant'),
      SubCategory(titleKey: 'parsley', icon: 'greens'),
    ],
  ),

  Category(
    id: 7,
    titleKey: 'fruits',
    icon: 'fruits',
    subCategories: [
      SubCategory(titleKey: 'banana', icon: 'banana'),
      SubCategory(titleKey: 'orange', icon: 'orange'),
      SubCategory(titleKey: 'grapes', icon: 'grapes'),
      SubCategory(titleKey: 'apple', icon: 'apple'),
      SubCategory(titleKey: 'guava', icon: 'guava'),
      SubCategory(titleKey: 'pear', icon: 'pear'),
      SubCategory(titleKey: 'mango', icon: 'mango'),
      SubCategory(titleKey: 'watermelon', icon: 'watermelon'),
    ],
  ),

  Category(
    id: 8,
    titleKey: 'smoking',
    icon: 'smoking',
    subCategories: [
      SubCategory(titleKey: 'cigarettes', icon: 'cigarette'),
      SubCategory(titleKey: 'shisha', icon: 'shisha'),
      SubCategory(titleKey: 'vape', icon: 'vape'),
      SubCategory(titleKey: 'iqos', icon: 'vape'),
    ],
  ),

  Category(
    id: 9,
    titleKey: 'health',
    icon: 'health',
    subCategories: [
      SubCategory(titleKey: 'doctor_visit', icon: 'doctor'),
      SubCategory(titleKey: 'medicine', icon: 'medicine'),
      SubCategory(titleKey: 'tests', icon: 'lab'),
      SubCategory(titleKey: 'xray', icon: 'xray'),
      SubCategory(titleKey: 'hospitals', icon: 'hospital'),
      SubCategory(titleKey: 'operations', icon: 'surgery'),
    ],
  ),

  Category(
    id: 10,
    titleKey: 'entertainment',
    icon: 'entertainment',
    subCategories: [
      SubCategory(titleKey: 'outings', icon: 'outdoor'),
      SubCategory(titleKey: 'cafe', icon: 'coffee'),
      SubCategory(titleKey: 'trips', icon: 'trip'),
      SubCategory(titleKey: 'travel', icon: 'travel'),
      SubCategory(titleKey: 'cinema', icon: 'cinema'),
      SubCategory(titleKey: 'amusement', icon: 'fun'),
    ],
  ),

  Category(
    id: 11,
    titleKey: 'education',
    icon: 'education',
    subCategories: [
      SubCategory(titleKey: 'private_lessons', icon: 'lesson'),
      SubCategory(titleKey: 'courses', icon: 'course'),
      SubCategory(titleKey: 'books', icon: 'book'),
      SubCategory(titleKey: 'stationery', icon: 'stationery'),
      SubCategory(titleKey: 'school_fees', icon: 'school'),
      SubCategory(titleKey: 'university_fees', icon: 'university'),
    ],
  ),

  Category(
    id: 12,
    titleKey: 'vehicles',
    icon: 'car',
    subCategories: [
      SubCategory(titleKey: 'fuel', icon: 'fuel'),
      SubCategory(titleKey: 'oil_change', icon: 'oil'),
      SubCategory(titleKey: 'car_maintenance', icon: 'maintenance'),
      SubCategory(titleKey: 'vehicle_purchase', icon: 'car'),
      SubCategory(titleKey: 'spare_parts', icon: 'tools'),
    ],
  ),

  Category(
    id: 13,
    titleKey: 'home',
    icon: 'home',
    subCategories: [
      SubCategory(titleKey: 'appliances', icon: 'appliance'),
      SubCategory(titleKey: 'home_maintenance', icon: 'maintenance'),
      SubCategory(titleKey: 'home_tools', icon: 'tools'),
      SubCategory(titleKey: 'home_cleaning', icon: 'cleaning'),
      SubCategory(titleKey: 'tissues', icon: 'tissue'),
      SubCategory(titleKey: 'furniture', icon: 'furniture'),
      SubCategory(titleKey: 'sets', icon: 'furniture'),
    ],
  ),

  Category(
    id: 14,
    titleKey: 'personal_care',
    icon: 'personal',
    subCategories: [
      SubCategory(titleKey: 'cosmetics', icon: 'cosmetics'),
      SubCategory(titleKey: 'accessories', icon: 'accessory'),
      SubCategory(titleKey: 'hair_care', icon: 'hair'),
      SubCategory(titleKey: 'body_care', icon: 'body'),
      SubCategory(titleKey: 'personal_devices', icon: 'device'),
    ],
  ),

  Category(
    id: 15,
    titleKey: 'tech',
    icon: 'tech',
    subCategories: [
      SubCategory(titleKey: 'tech_accessories', icon: 'accessory'),
      SubCategory(titleKey: 'tech_maintenance', icon: 'maintenance'),
      SubCategory(titleKey: 'chargers', icon: 'charger'),
      SubCategory(titleKey: 'headphones', icon: 'headphones'),
    ],
  ),

  Category(
    id: 16,
    titleKey: 'financial_obligations',
    icon: 'finance',
    subCategories: [
      SubCategory(titleKey: 'saving_group', icon: 'saving'),
      SubCategory(titleKey: 'loan', icon: 'loan'),
      SubCategory(titleKey: 'installments', icon: 'installment'),
      SubCategory(titleKey: 'social_insurance', icon: 'insurance'),
      SubCategory(titleKey: 'health_insurance', icon: 'insurance'),
      SubCategory(titleKey: 'car_insurance', icon: 'insurance'),
      SubCategory(titleKey: 'digital_subscriptions', icon: 'subscription'),
      SubCategory(titleKey: 'debts', icon: 'debt'),
    ],
  ),

  Category(
    id: 17,
    titleKey: 'government',
    icon: 'government',
    subCategories: [
      SubCategory(titleKey: 'fees', icon: 'fees'),
      SubCategory(titleKey: 'documents', icon: 'document'),
      SubCategory(titleKey: 'violations', icon: 'fine'),
    ],
  ),

  Category(
    id: 18,
    titleKey: 'gifts_events',
    icon: 'gift',
    subCategories: [
      SubCategory(titleKey: 'birthdays', icon: 'birthday'),
      SubCategory(titleKey: 'weddings', icon: 'wedding'),
      SubCategory(titleKey: 'family_visits', icon: 'family'),
      SubCategory(titleKey: 'hospital_visits', icon: 'hospital'),
      SubCategory(titleKey: 'eid_money', icon: 'money'),
      SubCategory(titleKey: 'gifts', icon: 'gift'),
    ],
  ),

  Category(
    id: 19,
    titleKey: 'hobbies',
    icon: 'hobby',
    subCategories: [
      SubCategory(titleKey: 'club_tools', icon: 'sport'),
      SubCategory(titleKey: 'club_membership', icon: 'club'),
      SubCategory(titleKey: 'gym_membership', icon: 'gym'),
      SubCategory(titleKey: 'gym_tools', icon: 'gym'),
    ],
  ),

  Category(
    id: 20,
    titleKey: 'baby',
    icon: 'baby',
    subCategories: [
      SubCategory(titleKey: 'baby_milk', icon: 'milk'),
      SubCategory(titleKey: 'diapers', icon: 'diaper'),
      SubCategory(titleKey: 'baby_cleaning', icon: 'baby'),
      SubCategory(titleKey: 'baby_clothes', icon: 'clothes'),
      SubCategory(titleKey: 'baby_toys', icon: 'toy'),
    ],
  ),

  Category(
    id: 21,
    titleKey: 'clothes',
    icon: 'clothes',
    subCategories: [
      SubCategory(titleKey: 'shirt', icon: 'shirt'),
      SubCategory(titleKey: 'pants', icon: 'pants'),
      SubCategory(titleKey: 'suit', icon: 'suit'),
      SubCategory(titleKey: 'jacket', icon: 'jacket'),
      SubCategory(titleKey: 'underwear', icon: 'underwear'),
      SubCategory(titleKey: 'tshirt', icon: 'tshirt'),
      SubCategory(titleKey: 'blouse', icon: 'blouse'),
      SubCategory(titleKey: 'dress', icon: 'dress'),
      SubCategory(titleKey: 'socks', icon: 'socks'),
    ],
  ),

  Category(
    id: 22,
    titleKey: 'shoes',
    icon: 'shoes',
    subCategories: [
      SubCategory(titleKey: 'shoe', icon: 'shoe'),
      SubCategory(titleKey: 'boot', icon: 'boot'),
      SubCategory(titleKey: 'sandal', icon: 'sandal'),
      SubCategory(titleKey: 'slipper', icon: 'slipper'),
      SubCategory(titleKey: 'crocs', icon: 'crocs'),
    ],
  ),
];
