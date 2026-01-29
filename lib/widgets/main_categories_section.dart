import 'package:flutter/material.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 260, // صفين فقط
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: categories.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            if (index == categories.length) {
              return const AddMainCategoryCard();
            }
            return MainCategoryCard(
              title: categories[index],
              selected: selectedIndex == index,
              onTap: () => onSelect(index),
            );
          },
        ),
      ),
    );
  }
}

class MainCategoryCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const MainCategoryCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform:
            selected ? (Matrix4.identity()..scale(0.97)) : Matrix4.identity(),
        child: Card(
          elevation: selected ? 8 : 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Icon(Icons.more_vert,
                        size: 18, color: Colors.grey[600]),
                  ),
                ),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Daily transport",
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.directions_car,
                        size: 22, color: Colors.blue),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          textStyle: const TextStyle(fontSize: 10),
                          minimumSize: const Size(0, 30),
                        ),
                        onPressed: () {},
                        child: const Text("Save"),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          textStyle: const TextStyle(fontSize: 10),
                          minimumSize: const Size(0, 30),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        child: const Text("Sub"),
                      ),
                    ),
                  ],
                )
              ],
            ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Center(
        child: Icon(Icons.add, size: 36, color: Colors.blue),
      ),
    );
  }
}
