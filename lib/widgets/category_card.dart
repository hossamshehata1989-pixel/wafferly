import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; // 👈 إضافة

class CategoryCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // 👈 اختصار

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Card(
            elevation: selected ? 500 : 10,
            color: selected
                ? Colors.yellow.withOpacity(0.4)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected
                    ? Colors.blue
                    : Colors.black.withOpacity(0.15),
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Icon(Icons.more_vert,
                        size: 18, color: Colors.grey.shade600),
                  ),

                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.dailyTransport, // 👈 مترجمة
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.directions_car,
                          size: 20, color: Colors.red),
                    ],
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 30),
                            side:
                                BorderSide(color: Colors.blue.shade400),
                            foregroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            t.sub, // 👈 مترجمة
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 30),
                            backgroundColor: Colors.blue.shade400,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            t.input, // 👈 مترجمة
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
