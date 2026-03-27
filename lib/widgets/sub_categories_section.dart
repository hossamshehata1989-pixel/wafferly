import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../data/categories_data.dart';
import '../utils/category_icons.dart';
import 'add_expense_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SubCategoriesSection extends StatelessWidget {
  final int mainCategoryIndex;
  final ValueNotifier<SelectedCategory>? selectedCategory;
  
  // ارتفاع ثابت للكونتينر لصفين
  static const double containerHeightForTwoRows = 150;
  static const double containerHeightForOneRow = 70;

  const SubCategoriesSection({
    super.key,
    required this.mainCategoryIndex,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final category = mainCategories[mainCategoryIndex];
    final subs = category.subCategories;
    final bool twoRows = subs.length > 9;
    
    // تحديد الارتفاع بناءً على عدد الصفوف
    final containerHeight = twoRows ? containerHeightForTwoRows : containerHeightForOneRow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(
              t.subCategories, 
              style: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
          ),
          Container(
            height: containerHeight, // ✅ ارتفاع ثابت ومحدد
            padding: const EdgeInsets.only(top: 1, bottom: 1, right: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2A6B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF243A8F)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(.25), 
                blurRadius: 12, 
                offset: const Offset(0, 8)
              )],
            ),
            child: Scrollbar(
              radius: const Radius.circular(10),
              thickness: 4,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: subs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoRows ? 2 : 1,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 3,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  return GestureDetector(
                    onTap: () {
                      // تحديث الـ SelectedCategory أولاً
                      if (selectedCategory != null) {
                        selectedCategory!.value = SelectedCategory(
                          id: sub.id,
                          name: sub.title(t),
                        );
                      }
                      // تمرير الـ ValueNotifier
                      if (selectedCategory != null) {
                        showAddExpenseSheet(context, selectedCategory!);
                      }
                    },
                    child: Card(
                      elevation: 6,
                      color: const Color(0xFF243A8F),
                      shadowColor: Colors.black.withOpacity(.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF3A7BFF), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              getCategoryIcon(sub.id),
                              width: 25,
                              height: 25,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.category, size: 25, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: AutoSizeText(
                                sub.title(t),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 7,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 10, 
                                  color: Colors.white
                                ),
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