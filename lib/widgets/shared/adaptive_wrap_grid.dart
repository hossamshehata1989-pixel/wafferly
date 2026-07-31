import 'package:flutter/material.dart';

class AdaptiveWrapGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int, double) itemBuilder;
  final double spacing;
  final double runSpacing;
  final int? columns;

  /// أقل عرض للعنصر
  final double minItemWidth;

  const AdaptiveWrapGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.runSpacing = 12,
    this.minItemWidth = 88,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        int itemsPerRow;

        if (columns != null) {
          itemsPerRow = columns!;
        } else {
          itemsPerRow = ((availableWidth + spacing) / (minItemWidth + spacing))
              .floor();

          if (itemsPerRow < 1) itemsPerRow = 1;
          if (itemsPerRow > itemCount) {
            itemsPerRow = itemCount;
          }
        }

        final itemWidth =
            (availableWidth - ((itemsPerRow - 1) * spacing)) / itemsPerRow;

        //=====================================
        debugPrint(
          'availableWidth=$availableWidth '
          'itemsPerRow=$itemsPerRow '
          'itemWidth=$itemWidth',
        );
        //======================================
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: List.generate(
            itemCount,
            (index) => SizedBox(
              width: itemWidth,
              child: itemBuilder(context, index, itemWidth),
            ),
          ),
        );
      },
    );
  }
}
