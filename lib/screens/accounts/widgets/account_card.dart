import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/financial_entity_visual.dart';
import '../../../theme/responsive_metrics.dart';
import 'shared/financial_entity_card.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.balanceText,
    required this.iconAsset,
    required this.visual,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final String balanceText;
  final String iconAsset;
  final FinancialEntityVisual visual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ResponsiveMetrics.of(context);

    return FinancialEntityCard(
      visual: visual,
      onTap: onTap,
      child: Row(
        children: [
          // Account Icon
          Container(
            width: metrics.size(55),
            height: metrics.size(55),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(.05)),
              color: visual.surfaceAccent.withOpacity(.15),
              borderRadius: BorderRadius.circular(metrics.size(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(metrics.size(5)),
              child: SvgPicture.asset(
                iconAsset,
                width: metrics.size(22),
                height: metrics.size(22),
              ),
            ),
          ),

          SizedBox(width: metrics.spacing(12)),

          // Account Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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

          // Balance + Chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balanceText,
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
    );
  }
}
