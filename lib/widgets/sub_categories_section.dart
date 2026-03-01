// 📦 Flutter
import 'package:flutter/material.dart';

// 🌍 Localization
import '../l10n/app_localizations.dart';

// 📊 Data
import '../data/categories_data.dart';

// 🖼️ Icons
import '../utils/category_icons.dart';

// 📌 Bottom Sheet
import 'add_expense_bottom_sheet.dart';

// 🖼️ SVG
import 'package:flutter_svg/flutter_svg.dart';

class SubCategoriesSection extends StatelessWidget {  
  final int mainCategoryIndex;      // 🔥 جديد: مؤشر الفئة الرئيسية

  const SubCategoriesSection({     
    super.key,       /// 🔥 جديد: إضافة المفتاح
    required this.mainCategoryIndex,             /// 🔥 جديد: جعل مؤشر الفئة الرئيسية مطلوبًا
  });   

  @override
  Widget build(BuildContext context) {         // 🔥 جديد: بناء الواجهة
    final t = AppLocalizations.of(context)!;              // 🔥 جديد: الحصول على الترجمات

    final category = mainCategories[mainCategoryIndex];     // 🔥 جديد: الحصول على بيانات الفئة الرئيسية
    final subs = category.subCategories;        // 🔥 جديد: الحصول على الفئات الفرعية

    final bool twoRows = subs.length > 9;     // 🔥 جديد: تحديد إذا كان هناك أكثر من 10 فئات فرعية لعرض صفين

    return Padding(                  // 🔥 جديد: إضافة تباعد أفقي
      padding: const EdgeInsets.symmetric(horizontal: 8),       // 🔥 جديد: تباعد 8 من الجانبين
      child: Column(                                      // 🔥 جديد: استخدام عمود لعرض العنوان والقائمة
        crossAxisAlignment: CrossAxisAlignment.start,   // 🔥 جديد: محاذاة العناصر إلى اليسار
        children: [                // 🔥 جديد: قائمة العناصر

          /// 🔹 Title        // 🔥 جديد: إضافة عنوان القسم
          Padding(
            padding: const EdgeInsets.symmetric(   // 🔥 جديد: تباعد كلمة (التصنيفات الفرعية")
              horizontal: 15,
              vertical: 1,
            ),
            child: Text(
              t.subCategories,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// 🔹 Container
          Container(
            height: twoRows ? 140 : 70,   // 🔥 تعديل الارتفاع بناءً على عدد العناصر
            padding: const EdgeInsets.only(
              top: 2,
              bottom: 2,
              right: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.black.withOpacity(0.15),
              ),
            ),

            child: Scrollbar(
              radius: const Radius.circular(10),
              thickness: 4,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: subs.length,

                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: twoRows ? 2 : 1,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                     childAspectRatio: 1,
                    ),

                itemBuilder: (context, index) {
                  final sub = subs[index];

                  return GestureDetector(
                    onTap: () {
                      showAddExpenseSheet(
                        context,
                        sub.title(t), // 🔥 الجديد
                      );
                    },

                    child: Card(
                      elevation: 5,
                      shadowColor:
                          Colors.black.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.blue
                              .withOpacity(0.25),
                          width: 1,
                        ),
                      ),

                      child: Padding(   // 🔥 جديد: إضافة تباعد داخل البطاقة
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 2,
                        ),

                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [

                            /// 🔷 Icon
                            SvgPicture.asset(
                              getCategoryIcon(sub.id),
                              width: 25,
                              height: 25,
                              placeholderBuilder:
                                  (context) =>
                                      const Icon(
                                Icons.image_not_supported,
                                size: 25,
                              ),
                            ),

                            /// 🔷 Text                     // 🔥 الجديد: عرض اسم الفئة الفرعية
                            Text(                      // 🔥 الجديد: عرض اسم الفئة الفرعية
                              sub.title(t),               // 🔥 الجديد
                              textAlign: TextAlign.center,
                              softWrap: true,     // 🔥 الجديد: السماح بالتفاف النص
                              maxLines: 2,     // 🔥 جديد: الحد الأقصى لعدد الأسطر
                              overflow:    // 🔥 جديد: التعامل مع النص الطويل
                                  TextOverflow.ellipsis,   // 🔥 جديد
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
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
}