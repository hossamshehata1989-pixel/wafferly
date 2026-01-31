import 'package:flutter/material.dart';
import 'category_card.dart';

class MainCategoriesSection extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const MainCategoriesSection({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final categories = List.generate(9, (i) => "Category ${i + 1}");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 340,
        padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          // ✨ بوردر أخف بصريًا
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
          child: GridView.builder(
            physics: const BouncingScrollPhysics(), // سكرول أنعم
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              mainAxisExtent: 150,
            ),
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return const AddMainCategoryCard();
              }
              return CategoryCard(
                title: categories[index],
                selected: selectedIndex == index,
                onTap: () => onSelect(index),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AddMainCategoryCard extends StatelessWidget {
  const AddMainCategoryCard({super.key});

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
        child: Icon(Icons.add, size: 38, color: Colors.blue),
      ),
    );
  }
}
