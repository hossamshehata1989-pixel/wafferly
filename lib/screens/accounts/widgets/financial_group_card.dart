import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/financial_group_visual.dart';
import '../../../theme/responsive_metrics.dart';
import 'shared/financial_entity_card.dart';

/// Financial group tile used by Accounts.
/// Compact rendering is intentionally self-contained so the Accounts layout
/// can be refined without changing the shared FinancialEntityCard used by
/// other screens.
class FinancialGroupCard extends StatelessWidget {
  const FinancialGroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.visual,
    this.onTap,
    this.isCompact = false,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final FinancialGroupVisual visual;
  final VoidCallback? onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ResponsiveMetrics.of(context);

    if (isCompact) {
      final accent = visual.color;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: metrics.spacing(metrics.isCompactHeight ? 1.5 : 3)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accent.withOpacity(0.17),
                const Color(0xFF111A2B),
                const Color(0xFF141D30),
              ],
              stops: const [0, 0.42, 1],
            ),
            borderRadius: BorderRadius.circular(metrics.size(17)),
            border: Border.all(color: accent.withOpacity(0.24), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: metrics.size(10),
                offset: Offset(0, metrics.size(3)),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(metrics.size(17)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(metrics.size(17)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.spacing(10),
                  vertical: metrics.spacing(metrics.isCompactHeight ? 2.5 : 5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: metrics.size(metrics.isCompactHeight ? 36 : 42),
                      height: metrics.size(metrics.isCompactHeight ? 36 : 42),
                      padding: EdgeInsets.all(metrics.size(5)),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(metrics.size(12)),
                        border: Border.all(color: accent.withOpacity(0.18)),
                      ),
                      child: SvgPicture.asset(
                        visual.icon,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: metrics.spacing(10)),
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: metrics.text(13),
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: metrics.spacing(3)),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFADB8CC),
                              fontSize: metrics.text(10.5),
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: metrics.spacing(5)),
                    Flexible(
                      flex: 4,
                      child: Text(
                        amountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: metrics.text(11.5),
                          height: 1.0,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white60,
                      size: metrics.size(19),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Preserve the established shared card style for any non-compact usage.
    return FinancialEntityCard(
      visual: visual.toEntityVisual(),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: metrics.size(55),
            height: metrics.size(55),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              color: visual.color.withOpacity(0.15),
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
              mainAxisAlignment: MainAxisAlignment.center,
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
          Flexible(
            child: Text(
              amountText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: metrics.text(14),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white54,
            size: metrics.size(18),
          ),
        ],
      ),
    );
  }
}
