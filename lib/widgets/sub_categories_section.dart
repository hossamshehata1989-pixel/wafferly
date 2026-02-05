import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../data/categories_data.dart';
import '../utils/category_icons.dart';
import 'add_expense_bottom_sheet.dart';
import '../utils/translation_helper.dart';
import '../utils/category_icons.dart';



class SubCategoriesSection extends StatelessWidget {
  final int mainCategoryIndex;

  const SubCategoriesSection({
    super.key,
    required this.mainCategoryIndex,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final subs = categories[mainCategoryIndex].subCategories;
    final bool twoRows = subs.length > 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Text(
              t.subCategories,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: twoRows ? 260 : 150,
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(10),
              thickness: 4,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: subs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoRows ? 2 : 1,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 110,
                ),
                itemBuilder: (context, index) {
                  final sub = subs[index];

                  return GestureDetector(
                    onTap: () {
                      showAddExpenseSheet(context, t.tr(sub.titleKey));
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                             t.tr(sub.titleKey),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),

                            Icon(
                              getSubCategoryIcon(),
                              size: 26,
                              color: Colors.blue,
                            ),
                            Text(
                              t.dailyTransport,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
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
