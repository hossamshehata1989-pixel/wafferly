import 'package:flutter/material.dart';

import '../../../theme/responsive_metrics.dart';

class GroupHeaderCard extends StatelessWidget {
  const GroupHeaderCard({
    super.key,
    required this.title,
    required this.balanceText,
    required this.subtitle,
    required this.sparkline,
  });

  final String title;
  final String balanceText;
  final String subtitle;
  final Widget sparkline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ResponsiveMetrics.of(context);

    return Padding(
      padding: EdgeInsets.all(metrics.spacing(12)),
      child: Container(
        padding: EdgeInsets.all(metrics.spacing(16)),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(metrics.size(18)),
          border: Border.all(color: theme.dividerColor.withOpacity(.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: metrics.spacing(8)),

                  Text(
                    balanceText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: metrics.spacing(6)),

                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

            SizedBox(width: metrics.spacing(16)),

            SizedBox(
              width: metrics.size(110),
              height: metrics.size(60),
              child: sparkline,
            ),
          ],
        ),
      ),
    );
  }
}
