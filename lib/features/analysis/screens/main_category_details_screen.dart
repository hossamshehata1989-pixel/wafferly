// lib/features/analysis/screens/main_category_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/transaction.dart';
import '../../../config/category_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/category_icons.dart';
import '../widgets/custom_donut_chart.dart';
import '../../../utils/category_helper.dart';

class MainCategoryDetailsScreen extends StatelessWidget {
  final String mainCategoryId;
  final String mainCategoryName;
  final List<Transaction> expenses;
  final DateTime startDate;
  final DateTime endDate;

  const MainCategoryDetailsScreen({
    super.key,
    required this.mainCategoryId,
    required this.mainCategoryName,
    required this.expenses,
    required this.startDate,
    required this.endDate,
  });

  // ✅ ألوان ثابتة للفئات الفرعية
  Color _getSubCategoryColor(String subCategoryId) {
    final colors = {
      // مواصلات يومية - فرعية
      'tuktuk': const Color(0xFF4ECDC4),
      'microbus': const Color(0xFF4ECDC4),
      'taxiUber': const Color(0xFF4ECDC4),
      'bus': const Color(0xFF4ECDC4),
      'metro': const Color(0xFF4ECDC4),
      'train': const Color(0xFF4ECDC4),
      
      // فواتير - فرعية
      'electricityBill': const Color(0xFFAA96DA),
      'gasBill': const Color(0xFFAA96DA),
      'waterBill': const Color(0xFFAA96DA),
      'mobileRecharge': const Color(0xFFAA96DA),
      'mobileInternet': const Color(0xFFAA96DA),
      'wifi': const Color(0xFFAA96DA),
      'landlineBill': const Color(0xFFAA96DA),
      'elevatorMaint': const Color(0xFFAA96DA),
      'cleaningFees': const Color(0xFFAA96DA),
      'buildSecurity': const Color(0xFFAA96DA),
      
      // سوبر ماركت - فرعية
      'waterBottle': const Color(0xFFFF6B6B),
      'milkPack': const Color(0xFFFF6B6B),
      'cheese': const Color(0xFFFF6B6B),
      'yogurt': const Color(0xFFFF6B6B),
      'eggs': const Color(0xFFFF6B6B),
      'cannedFood': const Color(0xFFFF6B6B),
      'bread': const Color(0xFFFF6B6B),
      'rice': const Color(0xFFFF6B6B),
      'pasta': const Color(0xFFFF6B6B),
      'oil': const Color(0xFFFF6B6B),
      'ghee': const Color(0xFFFF6B6B),
      'sugar': const Color(0xFFFF6B6B),
      'teaPack': const Color(0xFFFF6B6B),
      'coffeePack': const Color(0xFFFF6B6B),
      'legumes': const Color(0xFFFF6B6B),
      'frozenFood': const Color(0xFFFF6B6B),
      'spices': const Color(0xFFFF6B6B),
      'snacks': const Color(0xFFFF6B6B),
      'biscuits': const Color(0xFFFF6B6B),
      
      // مشروبات - فرعية
      'tea': const Color(0xFFA8E6CF),
      'coffee': const Color(0xFFA8E6CF),
      'hotDrinks': const Color(0xFFA8E6CF),
      'herbalDrinks': const Color(0xFFA8E6CF),
      'cola': const Color(0xFFA8E6CF),
      'juice': const Color(0xFFA8E6CF),
      'naturalMilk': const Color(0xFFA8E6CF),
      
      // أكل بره - فرعية
      'meals': const Color(0xFFFF6B6B),
      'sandwiches': const Color(0xFFFF6B6B),
      'crepe': const Color(0xFFFF6B6B),
      'pizza': const Color(0xFFFF6B6B),
      'pies': const Color(0xFFFF6B6B),
      'koshary': const Color(0xFFFF6B6B),
      'casseroles': const Color(0xFFFF6B6B),
      'desserts': const Color(0xFFFF6B6B),
      'grill': const Color(0xFFFF6B6B),
      
      // لحوم وأسماك - فرعية
      'chicken': const Color(0xFFFF6B6B),
      'chickenPane': const Color(0xFFFF6B6B),
      'meat': const Color(0xFFFF6B6B),
      'mincedMeat': const Color(0xFFFF6B6B),
      'liver': const Color(0xFFFF6B6B),
      'fish': const Color(0xFFFF6B6B),
      'saltedFish': const Color(0xFFFF6B6B),
      
      // خضروات - فرعية
      'tomato': const Color(0xFFA8E6CF),
      'potato': const Color(0xFFA8E6CF),
      'pepper': const Color(0xFFA8E6CF),
      'cucumber': const Color(0xFFA8E6CF),
      'eggplant': const Color(0xFFA8E6CF),
      'carrot': const Color(0xFFA8E6CF),
      'onion': const Color(0xFFA8E6CF),
      'garlic': const Color(0xFFA8E6CF),
      'stuffedVeget': const Color(0xFFA8E6CF),
      'okra': const Color(0xFFA8E6CF),
      'molokhia': const Color(0xFFA8E6CF),
      'spinach': const Color(0xFFA8E6CF),
      'greens': const Color(0xFFA8E6CF),
      'parsley': const Color(0xFFA8E6CF),
      
      // فاكهة - فرعية
      'banana': const Color(0xFFA8E6CF),
      'orange': const Color(0xFFA8E6CF),
      'grapes': const Color(0xFFA8E6CF),
      'apple': const Color(0xFFA8E6CF),
      'guava': const Color(0xFFA8E6CF),
      'pear': const Color(0xFFA8E6CF),
      'mango': const Color(0xFFA8E6CF),
      'strawberry': const Color(0xFFA8E6CF),
      'watermelon': const Color(0xFFA8E6CF),
      
      // تدخين - فرعية
      'cigarettes': const Color(0xFFFF8B94),
      'shisha': const Color(0xFFFF8B94),
      'vape': const Color(0xFFFF8B94),
      'iqos': const Color(0xFFFF8B94),
      
      // صحة - فرعية
      'doctorVisit': const Color(0xFFFF8B94),
      'medicine': const Color(0xFFFF8B94),
      'tests': const Color(0xFFFF8B94),
      'xray': const Color(0xFFFF8B94),
      'hospitals': const Color(0xFFFF8B94),
      'operations': const Color(0xFFFF8B94),
      
      // ترفيه - فرعية
      'outings': const Color(0xFFFFE66D),
      'cafe': const Color(0xFFFFE66D),
      'trips': const Color(0xFFFFE66D),
      'travel': const Color(0xFFFFE66D),
      'cinema': const Color(0xFFFFE66D),
      'amusement': const Color(0xFFFFE66D),
      
      // تعليم - فرعية
      'privateLessons': const Color(0xFFFFE66D),
      'courses': const Color(0xFFFFE66D),
      'books': const Color(0xFFFFE66D),
      'stationery': const Color(0xFFFFE66D),
      'supplies': const Color(0xFFFFE66D),
      'schoolFees': const Color(0xFFFFE66D),
      'universityFees': const Color(0xFFFFE66D),
      
      // مركبات - فرعية
      'fuel': const Color(0xFF4ECDC4),
      'oilChange': const Color(0xFF4ECDC4),
      'carMaintenance': const Color(0xFF4ECDC4),
      'vehiclePurchase': const Color(0xFF4ECDC4),
      'spareParts': const Color(0xFF4ECDC4),
      
      // المنزل - فرعية
      'appliances': const Color(0xFFAA96DA),
      'homeMaintenance': const Color(0xFFAA96DA),
      'homeTools': const Color(0xFFAA96DA),
      'homeCleaning': const Color(0xFFAA96DA),
      'tissues': const Color(0xFFAA96DA),
      'furniture': const Color(0xFFAA96DA),
      'sets': const Color(0xFFAA96DA),
      
      // هوايات - فرعية
      'sportsSubscriptions': const Color(0xFFFFE66D),
      'sportsEquipment': const Color(0xFFFFE66D),
      'sportsSupplements': const Color(0xFFFFE66D),
      'pets': const Color(0xFFFFE66D),
      'videoGames': const Color(0xFFFFE66D),
      'skating': const Color(0xFFFFE66D),
      'gardeningAndPlants': const Color(0xFFFFE66D),
      'reading': const Color(0xFFFFE66D),
      'music': const Color(0xFFFFE66D),
      'arts': const Color(0xFFFFE66D),
      'photography': const Color(0xFFFFE66D),
      'handmade': const Color(0xFFFFE66D),
      
      // بيبي - فرعية
      'babyMilk': const Color(0xFFFF8B94),
      'babyFood': const Color(0xFFFF8B94),
      'diapers': const Color(0xFFFF8B94),
      'babyCleaning': const Color(0xFFFF8B94),
      'babyClothes': const Color(0xFFFF8B94),
      'babyToys': const Color(0xFFFF8B94),
      
      // ملابس - فرعية
      'shirt': const Color(0xFFFF6B6B),
      'pants': const Color(0xFFFF6B6B),
      'suit': const Color(0xFFFF6B6B),
      'jacket': const Color(0xFFFF6B6B),
      'underwear': const Color(0xFFFF6B6B),
      'tshirt': const Color(0xFFFF6B6B),
      'blouse': const Color(0xFFFF6B6B),
      'dress': const Color(0xFFFF6B6B),
      'socks': const Color(0xFFFF6B6B),
      
      // أحذية - فرعية
      'shoe': const Color(0xFFFF6B6B),
      'sneakers': const Color(0xFFFF6B6B),
      'sandal': const Color(0xFFFF6B6B),
      'slipper': const Color(0xFFFF6B6B),
      'crocs': const Color(0xFFFF6B6B),
      
      // خدمات حكومية - فرعية
      'fees': const Color(0xFFAA96DA),
      'documents': const Color(0xFFAA96DA),
      'violations': const Color(0xFFAA96DA),
      
      // هدايا ومناسبات - فرعية
      'birthdays': const Color(0xFFFFE66D),
      'weddings': const Color(0xFFFFE66D),
      'familyVisits': const Color(0xFFFFE66D),
      'hospitalVisits': const Color(0xFFFFE66D),
      'eidMoney': const Color(0xFFFFE66D),
      'gifts': const Color(0xFFFFE66D),
      
      // التزامات مالية - فرعية
      'savingGroup': const Color(0xFFAA96DA),
      'loan': const Color(0xFFAA96DA),
      'installments': const Color(0xFFAA96DA),
      'socialInsurance': const Color(0xFFAA96DA),
      'healthInsurance': const Color(0xFFAA96DA),
      'carInsurance': const Color(0xFFAA96DA),
      'digitalSubs': const Color(0xFFAA96DA),
      'debts': const Color(0xFFAA96DA),
      
      // عناية شخصية - فرعية
      'cosmetics': const Color(0xFFFF8B94),
      'accessories': const Color(0xFFFF8B94),
      'hairCare': const Color(0xFFFF8B94),
      'bodyCare': const Color(0xFFFF8B94),
      'personalDevices': const Color(0xFFFF8B94),
      
      // موبايل وكمبيوتر - فرعية
      'techAccessories': const Color(0xFF4ECDC4),
      'techMaintenance': const Color(0xFF4ECDC4),
      'chargers': const Color(0xFF4ECDC4),
      'headphones': const Color(0xFF4ECDC4),
    };
    return colors[subCategoryId] ?? const Color(0xFFA8E6CF);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formatter = NumberFormat("#,###");
    
    // ✅ تجميع المصروفات حسب الفئة الفرعية
    final Map<String, SubCategoryData> subCategoriesMap = {};
    for (final expense in expenses) {
      final subId = expense.subCategoryId ?? expense.categoryId;
      
      // ========== DEBUG TRACE ==========
      print("\n🔍 [MainCategoryDetailsScreen] Processing expense:");
      print("   expense.id: ${expense.id}");
      print("   subId (from subCategoryId ?? categoryId): '$subId'");
      print("   expense.subCategoryId: '${expense.subCategoryId}'");
      print("   expense.categoryId: '${expense.categoryId}'");
      print("   amount: ${expense.amount}");
      // =================================

      final subName = expense.subCategoryId != null
          ? getSubCategoryName(expense.subCategoryId!, t)
          : getMainCategoryName(expense.categoryId, t);
          
      // ========== DEBUG TRACE ==========
      print("   resolved subName: '$subName'");
      // =================================
      
      if (subCategoriesMap.containsKey(subId)) {
        subCategoriesMap[subId] = SubCategoryData(
          id: subId,
          name: subName,
          total: subCategoriesMap[subId]!.total + expense.amount,
        );
      } else {
        subCategoriesMap[subId] = SubCategoryData(
          id: subId,
          name: subName,
          total: expense.amount,
        );
      }
    }
    
    final subCategoryList = subCategoriesMap.values.toList();
    subCategoryList.sort((a, b) => b.total.compareTo(a.total));
    
    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    
    final donutData = subCategoryList.map((e) => DonutData(e.name, e.total)).toList();
    
    String formatCurrency(double amount) {
      if (isArabic) {
        return "${formatter.format(amount.toInt())} ج.م";
      } else {
        return "${formatter.format(amount.toInt())} EGP";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          mainCategoryName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ كارت الملخص
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'إجمالي $mainCategoryName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(totalAmount),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ✅ الدائرة (الفئات الفرعية)
            if (subCategoryList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'تفاصيل الفئات الفرعية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomDonutChart(
                      data: donutData,
                      baseColor: Colors.blue,
                      size: 180,
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // ✅ قائمة الفئات الفرعية مع الأيقونات والألوان الثابتة
            if (subCategoryList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'قائمة الفئات الفرعية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...subCategoryList.map((subCategory) {
                      final percentage = totalAmount > 0 
                          ? (subCategory.total / totalAmount) * 100 
                          : 0;
                      final subColor = _getSubCategoryColor(subCategory.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // ✅ أيقونة الفئة الفرعية
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: subColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.asset(
                                getCategoryIcon(subCategory.id),
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.category,
                                  size: 24,
                                  color: subColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ✅ اسم الفئة والنسبة
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subCategory.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ✅ المبلغ
                            Text(
                              formatCurrency(subCategory.total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            
            if (subCategoryList.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'لا توجد مصروفات في هذه الفئة',
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ✅ كلاس مساعد لتخزين بيانات الفئة الفرعية
class SubCategoryData {
  final String id;
  final String name;
  final double total;
  
  SubCategoryData({
    required this.id,
    required this.name,
    required this.total,
  });
}