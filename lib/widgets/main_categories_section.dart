import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import '../l10n/app_localizations.dart';
import '../categories/category.dart';
import '../data/categories_data.dart';
import 'category_card.dart';

class MainCategoriesSection extends StatefulWidget {     
  final int selectedIndex;
  final Function(int) onSelect;

  const MainCategoriesSection({    
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<MainCategoriesSection> createState() =>
      _MainCategoriesSectionState();
}

class _MainCategoriesSectionState // 🔴 StatefulWidget لتمكين إعادة الترتيب والحذف
    extends State<MainCategoriesSection> { // 🔴 قائمة الفئات القابلة للتعديل
  late List<Category> categoriesList; // 🔴 ثوابت التصميم

  static const double cardHeight = 65; // ارتفاع كل كارت
  static const double visibleRows = 3.2; // لعرض 3 صفوف + جزء من الصف الرابع

  @override    // تهيئة الحالة
  void initState() {   // نسخ القائمة الأصلية
    super.initState();     // 🔴 نسخ القائمة الأصلية للسماح بالتعديل دون التأثير على المصدر
    categoriesList = List.from(mainCategories);     // 🔴 يمكن إضافة فئات جديدة هنا إذا أردت
  }

  /// 🔴 BottomSheet حذف فئة
  void _showDeleteSheet(            // تأكيد الحذف
      BuildContext context, int index) {          // الحصول على النصوص المترجمة
    final t = AppLocalizations.of(context)!;      // عرض الـ BottomSheet

    showModalBottomSheet(            
      context: context,                         // تصميم الـ BottomSheet
      shape: const RoundedRectangleBorder(       
        borderRadius:          
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {                   // محتوى الـ BottomSheet
        return Padding(            
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,         // جعل الـ Column يأخذ أقل مساحة ممكنة
            children: [             // عنوان التأكيد
              Text(              // 🔴 نص العنوان
                t.deleteCategory,      // "حذف الفئة"
                style: const TextStyle(          // تصميم العنوان
                  fontSize: 18,       // حجم الخط
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),             //

              /// زر الحذف
              ListTile(             // 🔴 زر الحذف
                leading:           // أيقونة الحذف
                    const Icon(Icons.delete, color: Colors.red),         // نص الزر
                title: Text(               // 🔴 نص الزر
                  t.delete,                // "حذف"
                  style: const TextStyle(color: Colors.red),         //
                ),
                onTap: () {
                  // منع حذف آخر كارت
                  const minimumCategories = 3;            // 🔴 الحد الأدنى لعدد الفئات
if (categoriesList.length <= minimumCategories) {        // 🔴 عرض رسالة خطأ إذا حاول المستخدم حذف آخر كارت
                    Navigator.pop(context);            // إغلاق الـ BottomSheet
                    return;           // 🔴 إظهار رسالة SnackBar
                  }

                  setState(() {            // 🔴 حذف الفئة من القائمة
                    categoriesList.removeAt(index);       // 🔴 إذا كانت الفئة المحذوفة هي المحددة حاليًا، قم بتحديث التحديد
                  });
                  Navigator.pop(context);            // إغلاق الـ BottomSheet
                },
              ),

              /// إلغاء
              ListTile(          //
                leading: const Icon(Icons.close),       //
                title: Text(t.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 🔹 ارتفاع الكونتينر (صفّين فقط)
    final double containerHeight =            // حساب ارتفاع الكونتينر بناءً على عدد الصفوف المرئية
        (cardHeight * visibleRows) + 20;      // 20 هو البادينغ الداخلي للكونتينر

    /// 🔹 Responsive columns            
    final double screenWidth =        // الحصول على عرض الشاشة لتحديد عدد الأعمدة
        MediaQuery.of(context).size.width;         // 🔴 تحديد عدد الأعمدة بناءً على عرض الشاشة

    int columns;         // 🔴 عدد الأعمدة الافتراضي (يمكن تعديله حسب الحاجة)
    if (screenWidth < 100) {        // شاشات صغيرة جدًا
      columns = 2;           // شاشات صغيرة
    } else if (screenWidth < 200) {          // شاشات متوسطة
      columns = 3;         // شاشات كبيرة
    } else {           // شاشات كبيرة جدًا
      columns = 4;          // يمكنك تعديل هذه القيم حسب التصميم الذي تريده
    }

    const double outerPadding = 12;        // البادينغ الخارجي للكونتينر
    const double innerPadding = 16;           // البادينغ الداخلي بين الكروت
    const double spacingBetweenCards = 7;     // المسافة بين الكروت

    final double horizontalPadding =         // حساب البادينغ الأفقي الإجمالي
        outerPadding + innerPadding;         // 🔴 حساب عرض كل كارت بناءً على عدد الأعمدة والمسافات
    final double spacing =          // المسافة الإجمالية بين الكروت في صف واحد
        (columns - 1) * spacingBetweenCards;        // حساب عرض الكارت

    final double cardWidth =        // عرض كل كارت بناءً على عدد الأعمدة والمسافات
        (screenWidth - horizontalPadding - spacing) /         
            columns;      // 🔴 بناء الواجهة

    return Padding(          // البادينغ الخارجي
      padding: const EdgeInsets.symmetric(horizontal: 5),      // 5 هو البادينغ الخارجي من الجانبين
     
     
     
      child: Container(               // الكونتينر الرئيسي
        height: containerHeight,
        padding: const EdgeInsets.all(5),             // البادينغ الداخلي للكونتينر
       decoration: BoxDecoration(
        color: const Color(0xFF1B2A6B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
         color: const Color(0xFF243A8F),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
       ),

        /// 🔽 Scroll رأسي + Drag & Drop       
        child: SingleChildScrollView(      // تمكين التمرير الرأسي
          child: ReorderableWrap(         // تمكين إعادة الترتيب
            spacing: spacingBetweenCards,         // المسافة بين الكروت
            runSpacing: spacingBetweenCards,       // المسافة بين الصفوف
            needsLongPressDraggable: true,        // تمكين السحب بالضغط المطول

            /// إعادة ترتيب
            onReorder: (oldIndex, newIndex) {          // تحديث ترتيب القائمة عند إعادة الترتيب
              setState(() {             // 🔴 تحديث حالة القائمة
                final item =                 // حفظ العنصر الذي يتم نقله
                    categoriesList.removeAt(oldIndex);           // إزالة العنصر من موقعه القديم
                categoriesList.insert(newIndex, item);        // إدخال العنصر في الموقع الجديد
              });         // تحديث التحديد إذا لزم الأمر
            },           //

            children: List.generate(       // إنشاء الكروت بناءً على القائمة
              categoriesList.length,         // 🔴 بناء كل كارت باستخدام CategoryCard
              (index) {          // الحصول على الفئة الحالية
                final category = categoriesList[index];        // 🔴 بناء كل كارت باستخدام CategoryCard

                return SizedBox(             // تحديد حجم كل كارت
                  width: cardWidth,          // عرض الكارت المحسوب
                  height: cardHeight,      // ارتفاع ثابت لكل كارت
                  child: CategoryCard(        // بناء الكارت
                    key: ValueKey(               // 🔴 مفتاح فريد لكل كارت بناءً على الفئة والمؤشر
                        '${category.id}_$index'),           // 🔴 مفتاح فريد يجمع بين معرف الفئة والمؤشر لضمان التفرد حتى مع وجود فئات مكررة
                    categoryId: category.id,        // معرف الفئة
                    title: category.title,            // مفتاح العنوان للترجمة
                    selected:                 // هل هذا الكارت هو المحدد حاليًا
                        widget.selectedIndex == index,     // تمييز الكارت المحدد
                    onTap: () =>                   
                        widget.onSelect(index),         // تحديث التحديد عند النقر
                    onLongPress: () =>        
                        _showDeleteSheet(context, index),        // إظهار الـ BottomSheet عند الضغط المطول
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
