import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../credit_card/domain/credit_card_profile.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/account.dart';
import '../accounts/add_credit_card/add_credit_card_screen.dart';
import '../accounts/liabilities/credit_card_account_details_screen.dart';
import '../../services/account_service.dart';
import '../../services/balance_service.dart';
import '../../theme/responsive_metrics.dart';
import '../../widgets/shared/credit_card_visual.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  final _accountService = AccountService();
  final _balanceService = BalanceService();
  List<_CreditCardData> _cards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    final profiles = Hive.box<CreditCardProfile>('credit_card_profiles').values;
    final accounts = _accountService
        .getAllActiveAccounts()
        .where((account) => account.type == 'creditCard')
        .toList();

    final loaded = <_CreditCardData>[];
    for (final account in accounts) {
      CreditCardProfile? profile;
      for (final candidate in profiles) {
        if (candidate.accountId == account.id) {
          profile = candidate;
          break;
        }
      }
      if (profile == null) continue;

      final balance = _balanceService.getBalance(account.id);
      final used = math.max(0, -balance).toDouble();
      final limit = profile.creditLimit.toDouble();
      final daysUntilDue = _daysUntilDue(profile.paymentDueDay);

      loaded.add(
        _CreditCardData(
          accountId: account.id,
          name: account.name,
          bank: account.provider ?? '',
          lastFour: account.accountNumber ?? '',
          limit: limit,
          used: used,
          dueThisMonth: 0,
          daysUntilDue: daysUntilDue,
          color: const Color(0xFFFF3D81),
          currency: account.currency,
          cardVisual: profile.cardVisual,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _cards = loaded;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = ResponsiveMetrics.of(context);

    final installmentOverview = _InstallmentOverview.fromHive(
      accountIds: _cards.map((card) => card.accountId).toSet(),
    );

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
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loading && _cards.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No credit cards yet.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                _SummaryCard(
                  metrics: metrics,
                  overview: installmentOverview,
                ),
                SizedBox(height: metrics.h(14)),
                _FilterBar(
                  metrics: metrics,
                  cards: _cards,
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

  Future<void> _onAddCard() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCreditCardScreen()),
    );
    if (created == true) _loadCards();
  }

  void _openCard(_CreditCardData card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreditCardAccountDetailsScreen(accountId: card.accountId),
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
    required this.overview,
  });

  final ResponsiveMetrics metrics;
  final _InstallmentOverview overview;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFFF3D81);
    final cardColor = const Color(0xFF071B2A);
    final borderColor = accent.withValues(alpha: .45);

    return Container(
      padding: EdgeInsets.fromLTRB(
        metrics.spacing(14),
        metrics.h(14),
        metrics.spacing(14),
        metrics.h(13),
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(metrics.size(18)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: metrics.size(42),
                height: metrics.size(42),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(metrics.size(12)),
                  border: Border.all(
                    color: accent.withValues(alpha: .35),
                  ),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: accent,
                  size: metrics.size(22),
                ),
              ),
              SizedBox(width: metrics.spacing(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit Cards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: metrics.text(16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: metrics.h(2)),
                    Text(
                      'Installment overview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: metrics.text(9.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (overview.currencyLabel != null)
                Text(
                  overview.currencyLabel!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .70),
                    fontSize: metrics.text(9.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          SizedBox(height: metrics.h(13)),
          Row(
            children: [
              Expanded(
                child: _MainInstallmentMetric(
                  metrics: metrics,
                  title: 'This Month',
                  subtitle: 'Installments',
                  value: overview.currentTotal,
                  currency: overview.currencyLabel,
                  color: const Color(0xFFFFB21A),
                ),
              ),
              SizedBox(width: metrics.spacing(8)),
              Expanded(
                child: _MainInstallmentMetric(
                  metrics: metrics,
                  title: 'Total',
                  subtitle: 'Installments',
                  value: overview.remainingTotal,
                  currency: overview.currencyLabel,
                  color: const Color(0xFF39E6B0),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.h(14)),
          Row(
            children: [
              Text(
                'Installment trend',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .70),
                  fontSize: metrics.text(9.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '3 previous • current • 3 upcoming',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .42),
                  fontSize: metrics.text(8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.h(8)),
          SizedBox(
            height: metrics.h(122),
            child: _InstallmentBarChart(
              metrics: metrics,
              periods: overview.periods,
              currency: overview.currencyLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainInstallmentMetric extends StatelessWidget {
  const _MainInstallmentMetric({
    required this.metrics,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.currency,
    required this.color,
  });

  final ResponsiveMetrics metrics;
  final String title;
  final String subtitle;
  final double value;
  final String? currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        metrics.spacing(11),
        metrics.h(9),
        metrics.spacing(11),
        metrics.h(10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF051522),
        borderRadius: BorderRadius.circular(metrics.size(12)),
        border: Border.all(
          color: Colors.white.withValues(alpha: .055),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .60),
              fontSize: metrics.text(9),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .42),
              fontSize: metrics.text(8),
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
                  _money(value),
                  style: TextStyle(
                    color: color,
                    fontSize: metrics.text(18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (currency != null) ...[
                  SizedBox(width: metrics.spacing(3)),
                  Text(
                    currency!,
                    style: TextStyle(
                      color: color.withValues(alpha: .78),
                      fontSize: metrics.text(8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentBarChart extends StatelessWidget {
  const _InstallmentBarChart({
    required this.metrics,
    required this.periods,
    required this.currency,
  });

  final ResponsiveMetrics metrics;
  final List<_InstallmentPeriod> periods;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final maxValue = periods.fold<double>(
      0,
      (max, period) => math.max(max, period.amount),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final period in periods)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.spacing(2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (period.amount > 0)
                    Text(
                      _compactMoney(period.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: period.isCurrent
                            ? const Color(0xFFFFB21A)
                            : Colors.white.withValues(alpha: .48),
                        fontSize: metrics.text(6.5),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    SizedBox(height: metrics.h(9)),
                  SizedBox(height: metrics.h(3)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxValue == 0
                            ? .05
                            : math.max(.05, period.amount / maxValue),
                        widthFactor: .52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(metrics.size(4)),
                            ),
                            color: period.isCurrent
                                ? const Color(0xFFFFB21A)
                                : const Color(0xFF3A6B87),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: metrics.h(5)),
                  Text(
                    period.label,
                    style: TextStyle(
                      color: period.isCurrent
                          ? Colors.white
                          : Colors.white.withValues(alpha: .48),
                      fontSize: metrics.text(7.5),
                      fontWeight: period.isCurrent
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InstallmentOverview {
  const _InstallmentOverview({
    required this.currentTotal,
    required this.remainingTotal,
    required this.periods,
    required this.currencyLabel,
  });

  final double currentTotal;
  final double remainingTotal;
  final List<_InstallmentPeriod> periods;
  final String? currencyLabel;

  factory _InstallmentOverview.fromHive({
    required Set<String> accountIds,
  }) {
    if (!Hive.isBoxOpen('financing_installments') ||
        !Hive.isBoxOpen('financing_contracts')) {
      return _empty();
    }

    final installments = Hive.box<FinancingInstallment>('financing_installments');
    final contracts = Hive.box<FinancingContract>('financing_contracts');
    final now = DateTime.now();
    final currentStart = DateTime(now.year, now.month);

    final periodStarts = List.generate(
      7,
      (index) => DateTime(now.year, now.month - 3 + index),
    );

    final totals = <DateTime, double>{
      for (final start in periodStarts) start: 0,
    };
    double remaining = 0;
    final currencies = <String>{};

    for (final installment in installments.values) {
      final contract = contracts.get(installment.contractId);
      if (contract == null ||
          !accountIds.contains(contract.liabilityAccountId)) {
        continue;
      }

      final status = installment.status.trim().toLowerCase();
      final amount = installment.amount.toDouble();
      if (amount <= 0) continue;

      final due = DateTime(
        installment.dueDate.year,
        installment.dueDate.month,
      );
      DateTime? bucket;
      for (final start in periodStarts) {
        if (start.year == due.year && start.month == due.month) {
          bucket = start;
          break;
        }
      }
      if (bucket != null) {
        totals[bucket] = (totals[bucket] ?? 0) + amount;
      }

      // Any non-settled installment is still an outstanding contractual
      // installment, including overdue installments.
      if (status != 'settled' &&
          status != 'cancelled' &&
          status != 'canceled' &&
          status != 'terminated') {
        remaining += amount;
      }

      // FinancingInstallment does not carry currency. Currency is therefore
      // resolved at the credit-card/account layer. Keep the summary neutral
      // when the portfolio contains multiple currencies.
    }

    final labels = <String>['-3', '-2', '-1', 'Now', '+1', '+2', '+3'];
    final periods = List.generate(
      7,
      (index) => _InstallmentPeriod(
        label: labels[index],
        amount: totals[periodStarts[index]] ?? 0,
        isCurrent: index == 3,
      ),
    );

    final currentTotal = totals[currentStart] ?? 0;
    final currencyLabel = _singlePortfolioCurrency(accountIds);

    return _InstallmentOverview(
      currentTotal: currentTotal,
      remainingTotal: remaining,
      periods: periods,
      currencyLabel: currencyLabel,
    );
  }

  static _InstallmentOverview _empty() {
    return _InstallmentOverview(
      currentTotal: 0,
      remainingTotal: 0,
      periods: const [
        _InstallmentPeriod(label: '-3', amount: 0),
        _InstallmentPeriod(label: '-2', amount: 0),
        _InstallmentPeriod(label: '-1', amount: 0),
        _InstallmentPeriod(label: 'Now', amount: 0, isCurrent: true),
        _InstallmentPeriod(label: '+1', amount: 0),
        _InstallmentPeriod(label: '+2', amount: 0),
        _InstallmentPeriod(label: '+3', amount: 0),
      ],
      currencyLabel: null,
    );
  }

  static String? _singlePortfolioCurrency(Set<String> accountIds) {
    if (accountIds.isEmpty) return null;
    final accounts = Hive.box<Account>('accounts').values;
    final currencies = <String>{};
    for (final account in accounts) {
      if (accountIds.contains(account.id)) {
        final currency = (account.currency as String?)?.trim();
        if (currency != null && currency.isNotEmpty) currencies.add(currency);
      }
    }
    return currencies.length == 1 ? currencies.first : null;
  }
}

class _InstallmentPeriod {
  const _InstallmentPeriod({
    required this.label,
    required this.amount,
    this.isCurrent = false,
  });

  final String label;
  final double amount;
  final bool isCurrent;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.metrics,
    required this.cards,
  });

  final ResponsiveMetrics metrics;
  final List<_CreditCardData> cards;

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
            label: 'All (${cards.length})',
            selected: true,
          ),
          _FilterChip(
            metrics: metrics,
            label: 'Overdue (${cards.where((c) => c.daysUntilDue < 0).length})',
          ),
          _FilterChip(
            metrics: metrics,
            label: 'Due Soon (${cards.where((c) => c.daysUntilDue >= 0 && c.daysUntilDue <= 7).length})',
          ),
          _FilterChip(
            metrics: metrics,
            label: 'Upcoming (${cards.where((c) => c.daysUntilDue > 7).length})',
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
    final available = math.max(0, card.limit - card.used).toDouble();
    final usage = card.limit == 0
        ? 0.0
        : (card.used / card.limit).clamp(0.0, 1.0);

    final status = _statusFor(card.daysUntilDue);
    final statusColor = _statusColor(status);
    final currency = card.currency.isEmpty ? 'EGP' : card.currency;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(metrics.size(14)),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            metrics.spacing(12),
            metrics.h(10),
            metrics.spacing(10),
            metrics.h(10),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF071B2A),
            borderRadius: BorderRadius.circular(metrics.size(14)),
            border: Border.all(
              color: card.color.withValues(alpha: .45),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(metrics.size(7)),
                    child: CreditCardVisual(
                      key: ValueKey('${card.accountId}_${card.cardVisual}'),
                      visual: card.cardVisual,
                      width: metrics.size(82),
                      height: metrics.size(48),
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: metrics.spacing(9)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: metrics.h(1)),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: metrics.h(2)),
                          Text(
                            '•••• ${card.lastFour}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFFAFC8E5),
                              fontSize: metrics.text(10.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.spacing(8),
                      vertical: metrics.h(5),
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(metrics.size(8)),
                      border: Border.all(
                        color: statusColor.withValues(alpha: .55),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: metrics.text(9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.spacing(5)),
                  Padding(
                    padding: EdgeInsets.only(top: metrics.h(4)),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                      size: metrics.size(23),
                    ),
                  ),
                ],
              ),
              SizedBox(height: metrics.h(9)),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: .08),
              ),
              SizedBox(height: metrics.h(8)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _InstallmentMetric(
                      metrics: metrics,
                      currency: currency,
                      amount: card.dueThisMonth,
                      daysUntilDue: card.daysUntilDue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: metrics.h(55),
                    margin: EdgeInsets.symmetric(
                      horizontal: metrics.spacing(10),
                    ),
                    color: Colors.white.withValues(alpha: .10),
                  ),
                  Expanded(
                    flex: 6,
                    child: _UsageMetric(
                      metrics: metrics,
                      used: card.used,
                      limit: card.limit,
                      available: available,
                      usage: usage,
                      currency: currency,
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

class _InstallmentMetric extends StatelessWidget {
  const _InstallmentMetric({
    required this.metrics,
    required this.currency,
    required this.amount,
    required this.daysUntilDue,
  });

  final ResponsiveMetrics metrics;
  final String currency;
  final double amount;
  final int daysUntilDue;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_statusFor(daysUntilDue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month Installment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .60),
            fontSize: metrics.text(8.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: metrics.h(2)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(amount),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: metrics.text(20),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: metrics.spacing(3)),
              Text(
                currency,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: metrics.text(9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: metrics.h(1)),
        Text(
          _dueText(daysUntilDue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: statusColor,
            fontSize: metrics.text(10.5),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _UsageMetric extends StatelessWidget {
  const _UsageMetric({
    required this.metrics,
    required this.used,
    required this.limit,
    required this.available,
    required this.usage,
    required this.currency,
  });

  final ResponsiveMetrics metrics;
  final double used;
  final double limit;
  final double available;
  final double usage;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final percent = (usage * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Used',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .60),
                fontSize: metrics.text(9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '${_money(used)} / ${_money(limit)} $currency',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: metrics.text(10),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.h(7)),
        ClipRRect(
          borderRadius: BorderRadius.circular(metrics.size(5)),
          child: LinearProgressIndicator(
            minHeight: metrics.h(7),
            value: usage,
            backgroundColor: const Color(0xFF12334A),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFFF4F7D),
            ),
          ),
        ),
        SizedBox(height: metrics.h(4)),
        Row(
          children: [
            Text(
              '$percent% used',
              style: TextStyle(
                color: const Color(0xFFFF4F7D),
                fontSize: metrics.text(9.5),
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '${_money(available)} $currency available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: const Color(0xFFAFC8E5),
                  fontSize: metrics.text(9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
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
    required this.accountId,
    required this.name,
    required this.bank,
    required this.lastFour,
    required this.limit,
    required this.used,
    required this.dueThisMonth,
    required this.daysUntilDue,
    required this.color,
    required this.currency,
    required this.cardVisual,
  });

  final String accountId;
  final String name;
  final String bank;
  final String lastFour;
  final double limit;
  final double used;
  final double dueThisMonth;
  final int daysUntilDue;
  final Color color;
  final String currency;
  final String cardVisual;

  String get bankInitials {
    final value = bank.trim();
    if (value.isEmpty) return 'CC';
    final words = value.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (words.length == 1) return words.first.length <= 4 ? words.first.toUpperCase() : words.first.substring(0, 4).toUpperCase();
    return words.take(3).map((e) => e[0]).join().toUpperCase();
  }
}

int _daysUntilDue(int? paymentDueDay) {
  if (paymentDueDay == null) return 999;
  final now = DateTime.now();
  var due = DateTime(now.year, now.month, paymentDueDay);
  if (!due.isAfter(now)) {
    due = DateTime(now.year, now.month + 1, paymentDueDay);
  }
  return due.difference(now).inDays;
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

String _compactMoney(double value) {
  final absolute = value.abs();
  if (absolute >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (absolute >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return value.round().toString();
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