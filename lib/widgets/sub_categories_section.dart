// 📦 استدعاء مكتبة Flutter الأساسية للـ UI
import 'package:flutter/material.dart';

// 🌍 استدعاء ملفات الترجمة (Arabic / English)
import '../l10n/app_localizations.dart';

// 📊 ملف البيانات اللي فيه الفئات الرئيسية والفرعية
import '../data/categories_data.dart';

// 🖼️ ملف تحديد مسار أيقونات SVG حسب الـ id
import '../utils/category_icons.dart';

// 📌 Bottom Sheet إضافة المصروف
import 'add_expense_bottom_sheet.dart';

// 🖼️ مكتبة عرض ملفات SVG
import 'package:flutter_svg/flutter_svg.dart';


// ============================================================
// 🔷 Widget مسؤول عن عرض الفئات الفرعية
// ============================================================

class SubCategoriesSection extends StatelessWidget {

  // 📍 رقم الفئة الرئيسية المختارة (transport, bills, ...)
  final int mainCategoryIndex;

  // 🏗️ Constructor لاستقبال رقم الفئة
  const SubCategoriesSection({
    super.key,
    required this.mainCategoryIndex,
  });

  // ============================================================
  // 🎨 BUILD METHOD → هنا بيتبني شكل الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {

    // 🌍 الحصول على الترجمة الحالية حسب لغة التطبيق
    final t = AppLocalizations.of(context)!;

    // 📂 الفئة الرئيسية المختارة
    final category = mainCategories[mainCategoryIndex];

    // 📂 قائمة الفئات الفرعية التابعة لها
    final subs = category.subCategories;

    // 📐 لو عدد الفئات > 10 نعرضهم في صفين بدل صف واحد
    final bool twoRows = subs.length > 10;

    // ============================================================
    // 🧱 بداية الـ Layout
    // ============================================================

    return Padding(

      // 🟦 مسافة خارجية يمين وشمال
      padding: const EdgeInsets.symmetric(horizontal: 12),

      child: Column(

        // 📌 محاذاة العناصر ناحية البداية (left في LTR)
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // ====================================================
          // 🔹 عنوان القسم (Sub Categories)
          // ====================================================

          Padding(                // مسافة داخلية حول العنوان
            padding: const EdgeInsets.symmetric(      // مسافة داخلية يمين وشمال
              horizontal: 4,      // مسافة داخلية فوق وتحت
              vertical: 10,       // مسافة داخلية فوق وتحت
            ),

            child: Text(
              t.subCategories, // 🌍 النص مترجم تلقائيًا

              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ====================================================
          // 🔹 الكارت الكبير اللي شايل الـ Grid
          // ====================================================

          Container(

            // 📏 ارتفاع ثابت (200 لو صفين - 100 لو صف واحد)
            height: twoRows ? 200 : 100,

            // 🧩 مسافة داخلية
            padding: const EdgeInsets.only(
              top: 5,    // مسافة داخلية فوق
              bottom: 5,    // مسافة داخلية تحت
              right: 7,        // مسافة داخلية يمين
            ),

            // 🎨 شكل الكارت (لون - حدود - ظل)
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.07),   // خلفية صفراء فاتحة

              // 🔵 حواف دائرية
              borderRadius: BorderRadius.circular(18),

              // 🟤 إطار خفيف
              border: Border.all(
                color: Colors.black.withOpacity(0.15),
              ),
            ),

            // ====================================================
            // 🔹 Scrollbar + GridView
            // ====================================================

            child: Scrollbar(

              thumbVisibility: false,   // إظهار مؤشر السكرول دائمًا
              radius: const Radius.circular(10),
              thickness: 4,

              child: GridView.builder(

                // ✨ سكرول ناعم
                physics: const BouncingScrollPhysics(),

                // 👉 السكرول أفقي
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(horizontal: 8),

                // 🔢 عدد العناصر
                itemCount: subs.length,

                // 🧮 طريقة توزيع العناصر داخل الجريد
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

                  // 📌 صفين أو صف واحد
                  crossAxisCount: twoRows ? 2 : 1,

                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,

                  // 📏 عرض كل عنصر
                  mainAxisExtent: 90,
                ),

                // ====================================================
                // 🔹 بناء كل عنصر داخل الجريد
                // ====================================================

                itemBuilder: (context, index) {

                  final sub = subs[index];

                  return GestureDetector(       // 👆 عند الضغط على الفئة

                    // 👆 عند الضغط على الفئة
                    onTap: () {
                      showAddExpenseSheet(
                        context,
                        _resolveSubTitle(t, sub.titleKey),
                      );
                    },

                    child: Card(       // 🎨 شكل الكارت (لون - حدود - ظل)

                      elevation: 5,    // ظل متوسط
                      shadowColor: Colors.black.withOpacity(0.5),   // لون ظل خفيف

                      shape: RoundedRectangleBorder(      // 🔵 حواف دائرية
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(                          // 🟤 إطار خفيف
                          color: Colors.blue.withOpacity(0.25),    // لون الإطار
                          width: 1,      // سمك الإطار
                        ),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),

                        child: Column(

                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [



                            // 🔷 أيقونة SVG
                            SvgPicture.asset(
                              getCategoryIcon(sub.id),
                              width: 30,
                              height: 30,
                            ),


                            // 🔷 اسم الفئة الفرعية
                            Text(
                              _resolveSubTitle(t, sub.titleKey),

                              textAlign: TextAlign.center,

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),


                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🌍 حل مشكلة المفاتيح الديناميكية في gen-l10n
  // ============================================================

  String _resolveSubTitle(AppLocalizations t, String key) {

    switch (key) {

      // 🚗 Transport
      case 'tuktuk': return t.tuktuk;
      case 'microbus': return t.microbus;
      case 'taxiUber': return t.taxiUber;
      case 'bus': return t.bus;
      case 'metro': return t.metro;
      case 'train': return t.train;

      // 💡 Bills
      case 'electricity': return t.electricity;
      case 'gas': return t.gas;
      case 'water': return t.water;
      case 'mobile_credit': return t.mobile_credit;
      case 'mobile_package': return t.mobile_package;
      case 'home_internet': return t.home_internet;
      case 'landline_bill': return t.landline_bill;
      case 'elevator_maintenance': return t.elevator_maintenance;
      case 'cleaning_fees': return t.cleaning_fees;
      case 'building_security': return t.building_security;

      // 🛒 Groceries
      case 'milk': return t.milk;
      case 'cheese': return t.cheese;
      case 'yogurt': return t.yogurt;
      case 'eggs': return t.eggs;
      case 'canned_food': return t.canned_food;
      case 'bread': return t.bread;
      case 'rice': return t.rice;
      case 'pasta': return t.pasta;
      case 'oil_ghee': return t.oil_ghee;
      case 'sugar': return t.sugar;
      case 'tea': return t.tea;
      case 'coffee': return t.coffee;
      case 'legumes': return t.legumes;
      case 'spices': return t.spices;
      case 'snacks_biscuits': return t.snacks_biscuits;

      default:
        return key; // 🛡️ fallback آمن
    }
  }
}
