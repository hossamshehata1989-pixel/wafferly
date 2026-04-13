// ==========================================
// 📦 CATEGORY PANEL (SCROLL LIST)
// ==========================================

import 'package:flutter/material.dart';
import '../logic/analysis_calculator.dart';
import '../../../utils/category_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wafferly/l10n/app_localizations.dart';
import '../../../utils/category_helper.dart';

class CategoryPanel extends StatelessWidget {
  final String title;
  final Map<String, double> data;

  const CategoryPanel({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final categories = getTopCategories(data);
    final t = AppLocalizations.of(context)!;  // ✅ هنا صح

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 TITLE
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),

          /// 🔥 HEADER (اسم + عملة)

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(t.category, style: const TextStyle(color: Colors.white54)),
    Text(t.currency, style: const TextStyle(color: Colors.white54)),
  ],
),

          const SizedBox(height: 10),

          /// 🔥 LIST (SCROLL)
          SizedBox(
            height: 140, // 🔥 يظهر 3 عناصر تقريبًا
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final e = categories[i];

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [

                      /// ICON
                      SvgPicture.asset(
                        getCategoryIcon(e.key),
                        width: 24,
                        height: 24,
                      ),

                      const SizedBox(width: 10),

                      /// NAME
                      Expanded(
                        child: Text(
                          getMainCategoryName(e.key, t),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection:
                              Directionality.of(context),
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                      ),

                      /// VALUE
                      Text(
                        e.value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}