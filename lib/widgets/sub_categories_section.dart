import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../data/categories_data.dart';
import '../utils/category_icons.dart';
import 'add_expense_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                      showAddExpenseSheet(
                        context,
                        _resolveSubTitle(t, sub.titleKey),
                      );
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// 🔷 اسم الفئة الفرعية
                            Text(
                              _resolveSubTitle(t, sub.titleKey),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),

                            /// 🔷 الأيقونة
                            SvgPicture.asset(
                              getCategoryIcon(sub.id),
                              width: 26,
                              height: 26,
                            ),

                            /// 🔷 وصف بسيط
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

  /// حل gen-l10n للـ dynamic sub keys
  String _resolveSubTitle(AppLocalizations t, String key) {
    switch (key) {
      case 'tuktuk': return t.tuktuk;
      case 'microbus': return t.microbus;
      case 'taxiUber': return t.taxiUber;
      case 'bus': return t.bus;
      case 'metro': return t.metro;
      case 'train': return t.train;

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
        return key; // fallback آمن
    }
  }
}
