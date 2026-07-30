import 'package:flutter/material.dart';

import '../../../theme/responsive_metrics.dart';

class SparklinePlaceholder extends StatelessWidget {
  const SparklinePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ResponsiveMetrics.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(metrics.size(12)),
      ),
      child: Center(
        child: Icon(
          Icons.show_chart_rounded,
          color: theme.colorScheme.primary,
          size: metrics.size(28),
        ),
      ),
    );
  }
}
