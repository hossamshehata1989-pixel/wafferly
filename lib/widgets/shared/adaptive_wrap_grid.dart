import 'package:flutter/material.dart';

class AdaptiveWrapGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  final double spacing;
  final double runSpacing;

  /// أقل عرض للعنصر
  final double minItemWidth;

  const AdaptiveWrapGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.runSpacing = 12,
    this.minItemWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        int itemsPerRow =
            ((availableWidth + spacing) / (minItemWidth + spacing)).floor();

        if (itemsPerRow < 1) itemsPerRow = 1;
        if (itemsPerRow > itemCount) itemsPerRow = itemCount;

        final itemWidth =
            (availableWidth - ((itemsPerRow - 1) * spacing)) / itemsPerRow;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: List.generate(
            itemCount,
            (index) =>
                SizedBox(width: itemWidth, child: itemBuilder(context, index)),
          ),
        );
      },
    );
  }
}
