import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/responsive_metrics.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  static const _cards = <_CreditCardData>[
    _CreditCardData(
      name: 'CIB Credit Card',
      lastFour: '4582',
      limit: 50000,
      used: 41200,
      dueThisMonth: 12400,
      daysUntilDue: -12,
      color: Color(0xFF00B9FF),
    ),
    _CreditCardData(
      name: 'HSBC Credit Card',
      lastFour: '3201',
      limit: 40000,
      used: 5600,
      dueThisMonth: 2800,
      daysUntilDue: 5,
      color: Color(0xFFFF8A00),
    ),
    _CreditCardData(
      name: 'QNB Credit Card',
      lastFour: '7714',
      limit: 30000,
      used: 1600,
      dueThisMonth: 0,
      daysUntilDue: 18,
      color: Color(0xFF4285FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = ResponsiveMetrics.of(context);

    final totalLimit = _cards.fold<double>(
      0,
      (sum, card) => sum + card.limit,
    );

    final totalUsed = _cards.fold<double>(
      0,
      (sum, card) => sum + card.used,
    );

    final totalAvailable = totalLimit - totalUsed;

    final totalDueThisMonth = _cards.fold<double>(
      0,
      (sum, card) => sum + card.dueThisMonth,
    );

    final usedRatio = totalLimit == 0
        ? 0.0
        : (totalUsed / totalLimit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        toolbarHeight: metrics.h(82),
        leading: BackButton(
          color: scheme.onSurface,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _HeaderIcon(
              metrics: metrics,
              color: const Color(0xFFFF2D6F),
              icon: Icons.credit_card_rounded,
            ),
            SizedBox(width: metrics.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit Cards',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: metrics.text(24),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: metrics.h(4)),
                  Text(
                    '${_cards.length} cards • Updated just now',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: metrics.text(11.5),
                    ),
                  ),
                ],
              ),
            ),
            _AddCardButton(
              metrics: metrics,
              onPressed: _onAddCard,
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = metrics.spacing(
              constraints.maxWidth < 420 ? 12 : 16,
            );

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontal,
                metrics.h(8),
                horizontal,
                metrics.h(24),
              ),
              children: [
                _SummaryCard(
                  metrics: metrics,
                  totalLimit: totalLimit,
                  totalUsed: totalUsed,
                  totalAvailable: totalAvailable,
                  totalDueThisMonth: totalDueThisMonth,
                  usedRatio: usedRatio,
                ),
                SizedBox(height: metrics.h(14)),
                _FilterBar(
                  metrics: metrics,
                ),
                SizedBox(height: metrics.h(14)),
                ..._cards.map(
                  (card) => Padding(
                    padding: EdgeInsets.only(
                      bottom: metrics.h(10),
                    ),
                    child: _CreditCardTile(
                      metrics: metrics,
                      card: card,
                      onTap: () => _openCard(card),
                    ),
                  ),
                ),
                SizedBox(height: metrics.h(4)),
                _AddCardTile(
                  metrics: metrics,
                  onTap: _onAddCard,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onAddCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Credit Card input screen will be connected here.',
        ),
      ),
    );
  }

  void _openCard(_CreditCardData card) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${card.name} details will open here.'),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.metrics,
    required this.color,
    required this.icon,
  });

  final ResponsiveMetrics metrics;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.size(50),
      height: metrics.size(50),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(
          metrics.size(14),
        ),
        border: Border.all(
          color: color.withValues(alpha: .45),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: metrics.size(26),
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  const _AddCardButton({
    required this.metrics,
    required this.onPressed,
  });

  final ResponsiveMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.add_rounded,
        size: metrics.size(21),
      ),
      label: Text(
        'Add Card',
        style: TextStyle(
          fontSize: metrics.text(12),
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF65B8FF),
        side: const BorderSide(
          color: Color(0xFF008CFF),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            metrics.size(12),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.spacing(12),
          vertical: metrics.h(11),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.metrics,
    required this.totalLimit,
    required this.totalUsed,
    required this.totalAvailable,
    required this.totalDueThisMonth,
    required this.usedRatio,
  });

  final ResponsiveMetrics metrics;
  final double totalLimit;
  final double totalUsed;
  final double totalAvailable;
  final double totalDueThisMonth;
  final double usedRatio;

  @override
  Widget build(BuildContext context) {
    final usedPercent = usedRatio * 100;
    final availablePercent = 100 - usedPercent;

    return Container(
      padding: EdgeInsets.all(metrics.spacing(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          metrics.size(18),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10115A),
            Color(0xFF071D30),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF4D32C8).withValues(alpha: .65),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  metrics: metrics,
                  title: 'Total Limit',
                  value: _money(totalLimit),
                  color: const Color(0xFFB98AFF),
                  icon: Icons.credit_card_rounded,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  metrics: metrics,
                  title: 'Used / Debt',
                  value: _money(totalUsed),
                  valueSuffix: '${usedPercent.round()}%',
                  color: const Color(0xFFFF4F7D),
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.h(14)),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  metrics: metrics,
                  title: 'Available',
                  value: _money(totalAvailable),
                  valueSuffix: '${availablePercent.round()}%',
                  color: const Color(0xFF39E6B0),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  metrics: metrics,
                  title: 'Due This Month',
                  value: _money(totalDueThisMonth),
                  color: const Color(0xFFFFB21A),
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.h(16)),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              metrics.size(8),
            ),
            child: SizedBox(
              height: metrics.h(10),
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, (usedRatio * 100).round()),
                    child: Container(
                      color: const Color(0xFFFF3E72),
                    ),
                  ),
                  Expanded(
                    flex: math.max(
                      1,
                      ((1 - usedRatio) * 100).round(),
                    ),
                    child: Container(
                      color: const Color(0xFF0B9DCE),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: metrics.h(7)),
          Row(
            children: [
              Text(
                '${usedPercent.round()}% used',
                style: TextStyle(
                  color: const Color(0xFFFF5B82),
                  fontSize: metrics.text(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${availablePercent.round()}% available',
                style: TextStyle(
                  color: const Color(0xFF35CFFF),
                  fontSize: metrics.text(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.metrics,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.valueSuffix,
  });

  final ResponsiveMetrics metrics;
  final String title;
  final String value;
  final String? valueSuffix;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: metrics.size(34),
          height: metrics.size(34),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(
              metrics.size(10),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: metrics.size(17),
          ),
        ),
        SizedBox(width: metrics.spacing(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .58),
                  fontSize: metrics.text(9.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: metrics.h(3)),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: metrics.spacing(4),
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: metrics.text(17),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'EGP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: metrics.text(9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (valueSuffix != null) ...[
                SizedBox(height: metrics.h(2)),
                Text(
                  valueSuffix!,
                  style: TextStyle(
                    color: color,
                    fontSize: metrics.text(9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.metrics,
  });

  final ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.h(43),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _FilterChip(
            metrics: metrics,
            label: 'All (3)',
            selected: true,
          ),
          _FilterChip(
            metrics: metrics,
            label: 'Overdue (1)',
          ),
          _FilterChip(
            metrics: metrics,
            label: 'Due Soon (1)',
          ),
          _FilterChip(
            metrics: metrics,
            label: 'Upcoming (1)',
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.metrics,
    required this.label,
    this.selected = false,
  });

  final ResponsiveMetrics metrics;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        right: metrics.spacing(8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(16),
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [
                  Color(0xFF5B28D8),
                  Color(0xFF32136D),
                ],
              )
            : null,
        color: selected
            ? null
            : const Color(0xFF071B2B),
        borderRadius: BorderRadius.circular(
          metrics.size(13),
        ),
        border: Border.all(
          color: selected
              ? const Color(0xFFB76CFF)
              : const Color(0xFF07517B),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : const Color(0xFFB8D2ED),
          fontSize: metrics.text(11),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CreditCardTile extends StatelessWidget {
  const _CreditCardTile({
    required this.metrics,
    required this.card,
    required this.onTap,
  });

  final ResponsiveMetrics metrics;
  final _CreditCardData card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = card.limit - card.used;
    final usage = card.limit == 0
        ? 0.0
        : (card.used / card.limit).clamp(0.0, 1.0);

    final status = _statusFor(card.daysUntilDue);
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          metrics.size(16),
        ),
        child: Container(
          padding: EdgeInsets.all(
            metrics.spacing(14),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF061827),
            borderRadius: BorderRadius.circular(
              metrics.size(16),
            ),
            border: Border.all(
              color: card.color.withValues(alpha: .35),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _BankIcon(
                    metrics: metrics,
                    color: card.color,
                    initials: card.bankInitials,
                  ),
                  SizedBox(width: metrics.spacing(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: metrics.text(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: metrics.h(3)),
                        Text(
                          '•••• ${card.lastFour}',
                          style: TextStyle(
                            color: const Color(0xFFAFC8E5),
                            fontSize: metrics.text(11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.spacing(9),
                      vertical: metrics.h(6),
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(
                        metrics.size(9),
                      ),
                      border: Border.all(
                        color: statusColor.withValues(alpha: .5),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: metrics.text(9.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.spacing(8)),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: metrics.size(24),
                  ),
                ],
              ),
              SizedBox(height: metrics.h(15)),
              Row(
                children: [
                  Expanded(
                    child: _CardMetric(
                      metrics: metrics,
                      title: 'Limit',
                      value: _money(card.limit),
                    ),
                  ),
                  _VerticalDivider(metrics: metrics),
                  Expanded(
                    child: _CardMetric(
                      metrics: metrics,
                      title: 'Used',
                      value: _money(card.used),
                      suffix: '${(usage * 100).round()}%',
                      valueColor: const Color(0xFFFF4F7D),
                    ),
                  ),
                  _VerticalDivider(metrics: metrics),
                  Expanded(
                    child: _CardMetric(
                      metrics: metrics,
                      title: 'Available',
                      value: _money(available),
                      suffix: '${((1 - usage) * 100).round()}%',
                      valueColor: const Color(0xFF39E6B0),
                    ),
                  ),
                  _VerticalDivider(metrics: metrics),
                  Expanded(
                    child: _CardMetric(
                      metrics: metrics,
                      title: 'Due This Month',
                      value: _money(card.dueThisMonth),
                      suffix: _dueText(card.daysUntilDue),
                      valueColor: statusColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: metrics.h(12)),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  metrics.size(5),
                ),
                child: LinearProgressIndicator(
                  minHeight: metrics.h(5),
                  value: usage,
                  backgroundColor: Colors.white.withValues(alpha: .06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    card.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
    required this.metrics,
    required this.title,
    required this.value,
    this.suffix,
    this.valueColor,
  });

  final ResponsiveMetrics metrics;
  final String title;
  final String value;
  final String? suffix;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: metrics.text(8.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: metrics.h(4)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: metrics.text(12.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: metrics.spacing(2)),
              Text(
                'EGP',
                style: TextStyle(
                  color: valueColor?.withValues(alpha: .75) ??
                      Colors.white70,
                  fontSize: metrics.text(7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (suffix != null) ...[
          SizedBox(height: metrics.h(2)),
          Text(
            suffix!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white70,
              fontSize: metrics.text(7.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({
    required this.metrics,
  });

  final ResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: metrics.h(38),
      margin: EdgeInsets.symmetric(
        horizontal: metrics.spacing(6),
      ),
      color: Colors.white.withValues(alpha: .10),
    );
  }
}

class _BankIcon extends StatelessWidget {
  const _BankIcon({
    required this.metrics,
    required this.color,
    required this.initials,
  });

  final ResponsiveMetrics metrics;
  final Color color;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.size(50),
      height: metrics.size(50),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: .28),
            color.withValues(alpha: .08),
          ],
        ),
        borderRadius: BorderRadius.circular(
          metrics.size(13),
        ),
        border: Border.all(
          color: color.withValues(alpha: .35),
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: metrics.text(12),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AddCardTile extends StatelessWidget {
  const _AddCardTile({
    required this.metrics,
    required this.onTap,
  });

  final ResponsiveMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          metrics.size(16),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.spacing(18),
            vertical: metrics.h(18),
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(
              metrics.size(16),
            ),
            border: Border.all(
              color: const Color(0xFF1170A6),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: metrics.size(50),
                height: metrics.size(50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A2440),
                  border: Border.all(
                    color: const Color(0xFF147BB7),
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: const Color(0xFF9AC9FF),
                  size: metrics.size(27),
                ),
              ),
              SizedBox(width: metrics.spacing(12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a Credit Card',
                    style: TextStyle(
                      color: const Color(0xFF9CC7FF),
                      fontSize: metrics.text(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: metrics.h(4)),
                  Text(
                    'Track another credit card',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                      fontSize: metrics.text(10.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditCardData {
  const _CreditCardData({
    required this.name,
    required this.lastFour,
    required this.limit,
    required this.used,
    required this.dueThisMonth,
    required this.daysUntilDue,
    required this.color,
  });

  final String name;
  final String lastFour;
  final double limit;
  final double used;
  final double dueThisMonth;
  final int daysUntilDue;
  final Color color;

  String get bankInitials {
    if (name.startsWith('CIB')) return 'CIB';
    if (name.startsWith('HSBC')) return 'HSBC';
    if (name.startsWith('QNB')) return 'QNB';
    return 'CC';
  }
}

String _statusFor(int days) {
  if (days < 0) return 'Overdue';
  if (days <= 7) return 'Due Soon';
  return 'Upcoming';
}

Color _statusColor(String status) {
  switch (status) {
    case 'Overdue':
      return const Color(0xFFFF426D);
    case 'Due Soon':
      return const Color(0xFFFFB21A);
    default:
      return const Color(0xFF4EA5FF);
  }
}

String _dueText(int days) {
  if (days < 0) {
    final value = days.abs();
    return '$value days overdue';
  }

  if (days == 0) {
    return 'Due today';
  }

  return 'Due in $days days';
}

String _money(double value) {
  final rounded = value.round();
  final text = rounded.toString();

  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }

  return buffer.toString();
}