import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/responsive_metrics.dart';

class NetWorthCard extends StatelessWidget {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final bool isTablet;
  final bool isLargeLayout;

  const NetWorthCard({
    super.key,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.isTablet,
    this.isLargeLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final metrics = ResponsiveMetrics.of(context);
    final formatter = NumberFormat('#,###');
    final isNegative = netWorth < 0;
    final compact = metrics.isCompactHeight;

    return Container(
      margin: EdgeInsets.fromLTRB(
        metrics.space.sm,
        metrics.spacing(3),
        metrics.space.sm,
        metrics.spacing(isLargeLayout ? 4 : 5),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNegative
              ? const [Color(0xFF8F233D), Color(0xFF511A63)]
              : const [Color(0xFF0759E8), Color(0xFF4724C9), Color(0xFF8616B8)],
        ),
        borderRadius: BorderRadius.circular(metrics.size(24)),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? const Color(0xFF8F233D) : const Color(0xFF5426DB))
                .withOpacity(0.22),
            blurRadius: metrics.size(18),
            offset: Offset(0, metrics.size(7)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(metrics.size(24)),
        child: Stack(
          children: [
            Positioned(
              right: -metrics.size(34),
              top: -metrics.size(52),
              child: Container(
                width: metrics.size(170),
                height: metrics.size(170),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.045),
                ),
              ),
            ),
            Positioned(
              right: metrics.size(70),
              bottom: -metrics.size(95),
              child: Container(
                width: metrics.size(210),
                height: metrics.size(150),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.035),
                ),
              ),
            ),
            Padding(
             padding: EdgeInsets.fromLTRB(
  metrics.size(isLargeLayout ? 35 : 18), // Left
  metrics.size(isLargeLayout ? 35 : (compact ? 16 : 30)), // Top
  metrics.size(isLargeLayout ? 35 : 18), // Right
  metrics.size(isLargeLayout ? 18 : (compact ? 12 : 22)), // Bottom
),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white.withOpacity(0.92),
                        size: metrics.size(20),
                      ),
                      SizedBox(width: metrics.spacing(7)),
                      Text(
                        t.netWorth,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: metrics.text(15),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.visibility_outlined,
                        color: Colors.white.withOpacity(0.85),
                        size: metrics.size(19),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: metrics.spacing(isLargeLayout ? (compact ? 5 : 8) : (compact ? 4 : 14)),
                  ),
                  Text(
                    '${formatter.format(netWorth.abs().toInt())} ${t.currency}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.text(
                        isTablet ? 31 : (isLargeLayout ? (compact ? 23 : 29) : (compact ? 32 : 40)),
                      ),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(
                    height: metrics.spacing(isLargeLayout ? (compact ? 10 : 13) : (compact ? 10 : 18)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _NetWorthDetail(
                          label: t.moneyYouHave,
                          amount: totalAssets,
                          currency: t.currency,
                          color: const Color(0xFF49E887),
                        ),
                      ),
                      SizedBox(width: metrics.spacing(9)),
                      Expanded(
                        child: _NetWorthDetail(
                          label: t.moneyYouOwe,
                          amount: totalLiabilities,
                          currency: t.currency,
                          color: const Color(0xFFFF786F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetWorthDetail extends StatelessWidget {
  const _NetWorthDetail({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final formatter = NumberFormat('#,###');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(10),
        vertical: metrics.spacing(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF080F29).withOpacity(0.34),
        borderRadius: BorderRadius.circular(metrics.size(14)),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: metrics.text(12),
              height: 1.35,
            ),
          ),
          SizedBox(height: metrics.spacing(3)),
          Text(
            '${formatter.format(amount.toInt())} $currency',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: metrics.text(13.5),
              fontWeight: FontWeight.w800,
              height: 1.20,
            ),
          ),
        ],
      ),
    );
  }
}
