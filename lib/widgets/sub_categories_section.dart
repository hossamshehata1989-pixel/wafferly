import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; // 👈 إضافة

class SubCategoriesSection extends StatelessWidget {
  final int mainCategoryIndex;

  const SubCategoriesSection({
    super.key,
    required this.mainCategoryIndex,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // 👈 اختصار

    final Map<int, List<String>> subData = {
      0: ["Fuel", "Uber", "Bus", "Maintenance"],
      1: ["Groceries", "Restaurant", "Snacks"],
      2: ["Electricity", "Water", "Internet"],
      3: ["Cinema", "Games", "Trips"],
    };

    final subs = subData[mainCategoryIndex] ??
        ["Sub 1", "Sub 2", "Sub 3", "Sub 4"];

    final bool twoRows = subs.length > 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Text(
              t.subCategories, // 👈 مترجمة بدل "Sub Categories"
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          Container(
            height: twoRows ? 300 : 160,
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.black.withOpacity(0.15),
                width: 1,
              ),
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
                itemCount: subs.length + 1,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoRows ? 2 : 1,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 100,
                ),
                itemBuilder: (context, index) {
                  if (index == subs.length) {
                    return const AddSubCategoryCard();
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Icon(Icons.more_vert,
                                size: 18, color: Colors.grey.shade600),
                          ),
                          Text(
                            subs[index],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          const Icon(Icons.directions_car,
                              size: 26, color: Colors.blue),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: const Size(0, 30),
                                backgroundColor: Colors.blue.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                t.input, // 👈 مترجمة بدل "Input"
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                        ],
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

class AddSubCategoryCard extends StatelessWidget {
  const AddSubCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(Icons.add, size: 36, color: Colors.blue),
      ),
    );
  }
}
