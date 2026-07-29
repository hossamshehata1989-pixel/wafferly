import 'package:flutter/material.dart';
import '../../../theme/responsive_metrics.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/financial_group_visual.dart';

class FinancialGroupCard extends StatelessWidget {
  const FinancialGroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.visual,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final FinancialGroupVisual visual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ResponsiveMetrics.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(12),
        vertical: metrics.spacing(4),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF171A22),
          borderRadius: BorderRadius.circular(metrics.size(14)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: metrics.size(8),
              offset: Offset(0, metrics.size(3)),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(metrics.size(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(metrics.size(14)),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(metrics.spacing(14)),
              child: Row(
                children: [
                  Container(
                    width: metrics.size(55),
                    height: metrics.size(55),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .05),
                      ),
                      color: visual.color.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(metrics.size(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(metrics.size(5)),
                      child: SvgPicture.asset(
                        visual.icon,
                        width: metrics.size(22),
                        height: metrics.size(22),
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.spacing(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: metrics.text(14),
                          ),
                        ),
                        SizedBox(height: metrics.spacing(2)),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontSize: metrics.text(11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: metrics.spacing(8)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: metrics.text(14),
                        ),
                      ),
                      SizedBox(height: metrics.spacing(4)),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                        size: metrics.size(18),
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
