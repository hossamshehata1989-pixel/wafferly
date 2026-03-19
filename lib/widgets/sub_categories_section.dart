import 'package:flutter/material.dart';

/// 🌍 Localization
import '../l10n/app_localizations.dart';

/// 📊 Data
import '../data/categories_data.dart';

/// 🖼️ Icons
import '../utils/category_icons.dart';

/// 🖼️ SVG
import 'package:flutter_svg/flutter_svg.dart';

/// 🔤 Auto text resize
import 'package:auto_size_text/auto_size_text.dart';

/// 🎨 Colors
import '../theme/app_colors.dart';

/// BottomSheet model
import '../widgets/add_expense_bottom_sheet.dart';

class SubCategoriesSection extends StatelessWidget {

  final int mainCategoryIndex;

  /// notifier للفئة المختارة
  final ValueNotifier<SelectedCategory> selectedCategory;

  const SubCategoriesSection({
    super.key,
    required this.mainCategoryIndex,
    required this.selectedCategory,
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

          /// Title
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

          /// Container
          Container(

            height: twoRows ? 140 : 75,

            padding: const EdgeInsets.only(
              top: 1,
              bottom: 1,
              right: 1,
            ),

            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: AppColors.cardSecondary,
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

                      /// تغيير الفئة المختارة فقط
                      selectedCategory.value = SelectedCategory(
                        id: sub.id,
                        name: sub.title(t),
                      );

                      showAddExpenseSheet(
                        context,
                        selectedCategory,
                      );

                    },

                    child: Card(

                      elevation: 6,

                      color: AppColors.cardSecondary,

                      shadowColor:
                          Colors.black.withOpacity(.35),

                      shape: RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(10),

                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                      ),

                      child: Padding(

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),

                        child: Column(

                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            /// Icon
                            SvgPicture.asset(
                              getCategoryIcon(sub.id),
                              width: 30,
                              height: 30,

                              placeholderBuilder:
                                  (context) => const Icon(
                                Icons.image_not_supported,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// Text
                            Expanded(
                              child: AutoSizeText(
                                sub.title(t),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 7,
                                overflow:
                                    TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
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