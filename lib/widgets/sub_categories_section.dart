import 'package:flutter/material.dart';

class SubCategoriesSection extends StatelessWidget {
  final int mainIndex;
  const SubCategoriesSection({super.key, required this.mainIndex});

  @override
  Widget build(BuildContext context) {
    final subs = List.generate(12, (i) => "Sub ${i + 1}");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sub Categories",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...subs.map((s) => SubCategoryCard(title: s)),
              const AddSubCategoryCard(),
            ],
          )
        ],
      ),
    );
  }
}

class SubCategoryCard extends StatelessWidget {
  final String title;
  const SubCategoryCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
          ),
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Icon(Icons.local_taxi, size: 30, color: Colors.blue),
          const SizedBox(height: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 2),
              textStyle: const TextStyle(fontSize: 9),
            ),
            onPressed: () {},
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}

class AddSubCategoryCard extends StatelessWidget {
  const AddSubCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add, color: Colors.blue, size: 32),
    );
  }
}
