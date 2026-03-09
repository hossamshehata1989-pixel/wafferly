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

// 🔤 Auto text resize
import 'package:auto_size_text/auto_size_text.dart';

class SubCategoriesSection extends StatelessWidget {
  final int mainCategoryIndex;

  const SubCategoriesSection({
    super.key,
    required this.mainCategoryIndex,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final category = mainCategories[mainCategoryIndex];
    final subs = category.subCategories;

    final bool twoRows = subs.length > 9;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),
            child: Text(
              t.subCategories,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          /// 🔹 Container
          Container(
            height: twoRows ? 160 : 75,
            padding: const EdgeInsets.only(
              top: 1,
              bottom: 1,
              right: 1,
            ),
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
                  offset: const Offset(0, 8),
                ),
              ],
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
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 3,
                  childAspectRatio: 1,
                ),

                itemBuilder: (context, index) {
                  final sub = subs[index];

                  return GestureDetector(
                    onTap: () {
                      showAddExpenseSheet(
                        context,
                        sub.title(t),
                      );
                    },

                    child: Card(
                      elevation: 6,
                      color: const Color(0xFF243A8F),
                      shadowColor: Colors.black.withOpacity(.35),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Color(0xFF3A7BFF),
                          width: 1,
                        ),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),

                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [

                            /// 🔷 Icon
                            SvgPicture.asset(
                              getCategoryIcon(sub.id),
                              width: 30,
                              height: 30,
                              placeholderBuilder: (context) =>
                                  const Icon(
                                Icons.image_not_supported,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// 🔷 Text (Auto resize)
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
                                  color: Colors.white,
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