import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_monthly_due_projection_calculator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';

class CreditCardUpcomingPaymentsScreen extends StatelessWidget {
  const CreditCardUpcomingPaymentsScreen({
    super.key,
    required this.cardName,
    required this.currency,
    required this.months,
  });

  final String cardName;
  final String currency;
  final List<CreditCardMonthDueProjection> months;

  String _money(num amount) => '${amount.toStringAsFixed(2)} $currency';

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.upcomingPayments,
              style: TextStyle(
                fontSize: m.typography.title,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              cardName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: m.typography.caption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          m.spacing(16),
          m.spacing(8),
          m.spacing(16),
          m.spacing(28),
        ),
        children: [
          if (months.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: m.space.md),
              child: Text(
                '${t.paymentMonth}: ${MaterialLocalizations.of(context).formatMonthYear(months.first.monthStart)} onward',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: m.typography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          for (final month in months) ...[
            _MonthPaymentCard(
              month: month,
              currency: currency,
              money: _money,
              estimatedLabel: t.estimated,
            ),
            SizedBox(height: m.space.sm),
          ],
          if (months.isEmpty)
            Container(
              padding: EdgeInsets.all(m.space.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(m.radius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                t.forecastNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: m.typography.body,
                  height: 1.4,
                ),
              ),
            ),
          SizedBox(height: m.space.md),
          Container(
            padding: EdgeInsets.all(m.space.md),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2432),
              borderRadius: BorderRadius.circular(m.radius.lg),
              border: Border.all(color: const Color(0xFF1B4658)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accent,
                  size: m.icon.medium,
                ),
                SizedBox(width: m.space.sm),
                Expanded(
                  child: Text(
                    t.forecastNote,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontSize: m.typography.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPaymentCard extends StatelessWidget {
  const _MonthPaymentCard({
    required this.month,
    required this.currency,
    required this.money,
    required this.estimatedLabel,
  });

  final CreditCardMonthDueProjection month;
  final String currency;
  final String Function(num amount) money;
  final String estimatedLabel;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final monthLabel = MaterialLocalizations.of(context).formatMonthYear(month.monthStart);

    return Container(
      padding: EdgeInsets.all(m.space.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: m.size(40),
                height: m.size(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1684).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(m.radius.md),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFFF1684),
                ),
              ),
              SizedBox(width: m.space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabel,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: m.typography.body,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: m.spacing(3)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: m.spacing(7),
                        vertical: m.spacing(2),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF49304B),
                        borderRadius: BorderRadius.circular(m.radius.sm),
                      ),
                      child: Text(
                        estimatedLabel,
                        style: TextStyle(
                          color: const Color(0xFFFF9BC5),
                          fontSize: m.text(9),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: m.space.sm),
              Text(
                money(month.total.toDouble()),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: m.typography.body,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: m.space.md),
          Divider(height: 1, color: Colors.white.withValues(alpha: .10)),
          SizedBox(height: m.space.md),
          Row(
            children: [
              Expanded(
                child: _AmountBreakdown(
                  label: 'Expenses',
                  amount: month.expenses.toDouble(),
                  money: money,
                  color: const Color(0xFFFF2D8C),
                ),
              ),
              SizedBox(width: m.space.sm),
              Expanded(
                child: _AmountBreakdown(
                  label: 'Installments',
                  amount: month.installments.toDouble(),
                  money: money,
                  color: const Color(0xFF40C8FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountBreakdown extends StatelessWidget {
  const _AmountBreakdown({
    required this.label,
    required this.amount,
    required this.money,
    required this.color,
  });

  final String label;
  final double amount;
  final String Function(num amount) money;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: m.size(7),
          height: m.size(7),
          margin: EdgeInsets.only(top: m.spacing(4)),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: m.space.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: m.typography.caption,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: m.spacing(2)),
              Text(
                money(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: m.text(11),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
