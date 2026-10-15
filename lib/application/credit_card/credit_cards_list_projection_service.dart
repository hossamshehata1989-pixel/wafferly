import 'package:hive_flutter/hive_flutter.dart';

import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile.dart';
import '../../models/account.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../services/account_service.dart';
import '../../services/balance_service.dart';

/// Read model used by the Credit Cards management screen.
///
/// Hive access and projection calculations stay outside the widget. This is a
/// read-only projection; it does not create or modify financial records.
final class CreditCardsListProjectionService {
  CreditCardsListProjectionService({
    AccountService? accountService,
    BalanceService? balanceService,
    Box<CreditCardProfile>? profilesBox,
    Box<FinancingInstallment>? installmentsBox,
    Box<FinancingContract>? contractsBox,
    DateTime Function()? now,
  })  : _accountService = accountService ?? AccountService(),
        _balanceService = balanceService ?? BalanceService(),
        _profilesBox = profilesBox,
        _installmentsBox = installmentsBox,
        _contractsBox = contractsBox,
        _now = now ?? DateTime.now;

  final AccountService _accountService;
  final BalanceService _balanceService;
  final Box<CreditCardProfile>? _profilesBox;
  final Box<FinancingInstallment>? _installmentsBox;
  final Box<FinancingContract>? _contractsBox;
  final DateTime Function() _now;

  CreditCardsListProjection project() {
    final now = _now();
    final accounts = _accountService
        .getAllActiveAccounts()
        .where((account) => account.type == 'creditCard')
        .toList(growable: false);

    final profilesBox =
        _profilesBox ?? Hive.box<CreditCardProfile>('credit_card_profiles');
    final profileByAccountId = <String, CreditCardProfile>{
      for (final profile in profilesBox.values) profile.accountId: profile,
    };

    final cards = <CreditCardListItemProjection>[];
    for (final account in accounts) {
      final profile = profileByAccountId[account.id];
      if (profile == null) continue;

      final balance = _balanceService.getBalance(account.id);
      final used = Money.fromDouble(balance < 0 ? -balance : 0.0);
      final limit = profile.creditLimit;
      final available = limit > used ? limit - used : Money.zero;
      final limitAmount = limit.toDouble();
      final usedAmount = used.toDouble();
      final utilization = limitAmount <= 0
          ? 0.0
          : (usedAmount / limitAmount).clamp(0.0, 1.0).toDouble();
      cards.add(
        CreditCardListItemProjection(
          accountId: account.id,
          name: account.name,
          bank: account.provider ?? '',
          lastFour: account.accountNumber ?? '',
          creditLimit: limit,
          used: used,
          availableCredit: available,
          utilization: utilization,
          daysUntilDue: _daysUntilDue(profile.paymentDueDay, now),
          currency: account.currency,
          cardVisual: profile.cardVisual,
        ),
      );
    }

    final accountIds = cards.map((card) => card.accountId).toSet();
    final currencyByAccountId = <String, String>{
      for (final account in accounts)
        if (accountIds.contains(account.id)) account.id: account.currency.trim(),
    };

    final installmentsBox = _installmentsBox ?? _openInstallmentsBoxOrNull();
    final contractsBox = _contractsBox ?? _openContractsBoxOrNull();
    final overview = projectInstallmentOverviewFromData(
      accountIds: accountIds,
      currencyByAccountId: currencyByAccountId,
      installments: installmentsBox?.values ?? const <FinancingInstallment>[],
      contracts: contractsBox?.values ?? const <FinancingContract>[],
      now: now,
    );

    return CreditCardsListProjection(
      cards: List.unmodifiable(cards),
      installmentOverview: overview,
    );
  }

  Box<FinancingInstallment>? _openInstallmentsBoxOrNull() {
    if (!Hive.isBoxOpen('financing_installments')) return null;
    return Hive.box<FinancingInstallment>('financing_installments');
  }

  Box<FinancingContract>? _openContractsBoxOrNull() {
    if (!Hive.isBoxOpen('financing_contracts')) return null;
    return Hive.box<FinancingContract>('financing_contracts');
  }

  static CreditCardInstallmentOverviewProjection
      projectInstallmentOverviewFromData({
    required Set<String> accountIds,
    required Map<String, String> currencyByAccountId,
    required Iterable<FinancingInstallment> installments,
    required Iterable<FinancingContract> contracts,
    required DateTime now,
  }) {
    final emptyPeriods = _emptyPeriods();
    if (accountIds.isEmpty) {
      return CreditCardInstallmentOverviewProjection.empty(emptyPeriods);
    }

    final contractById = <String, FinancingContract>{
      for (final contract in contracts)
        if (accountIds.contains(contract.liabilityAccountId) &&
            !_isCancelled(contract.lifecycleState))
          contract.contractId: contract,
    };

    final periodStarts = List<DateTime>.generate(
      7,
      (index) => DateTime(now.year, now.month - 3 + index),
      growable: false,
    );
    final labels = const <String>['-3', '-2', '-1', 'Now', '+1', '+2', '+3'];
    final totals = <DateTime, Money>{
      for (final start in periodStarts) start: Money.zero,
    };
    var remaining = Money.zero;
    final currenciesWithAmounts = <String>{};

    for (final installment in installments) {
      final contract = contractById[installment.contractId];
      if (contract == null) continue;

      final currency = currencyByAccountId[contract.liabilityAccountId]?.trim();
      final amount = installment.amount;
      if (currency == null || currency.isEmpty || !amount.isPositive) continue;

      final due = DateTime(installment.dueDate.year, installment.dueDate.month);
      var includedInTrend = false;
      for (final start in periodStarts) {
        if (start.year == due.year && start.month == due.month) {
          totals[start] = totals[start]! + amount;
          includedInTrend = true;
          break;
        }
      }

      final status = installment.status.trim().toLowerCase();
      final isOutstanding = status != 'settled' &&
          status != 'cancelled' &&
          status != 'canceled' &&
          status != 'terminated';
      if (isOutstanding) {
        remaining = remaining + amount;
      }
      if (includedInTrend || isOutstanding) {
        currenciesWithAmounts.add(currency);
      }
    }

    final hasMixedCurrencies = currenciesWithAmounts.length > 1;
    if (hasMixedCurrencies) {
      return CreditCardInstallmentOverviewProjection(
        currentTotal: Money.zero,
        remainingTotal: Money.zero,
        periods: List.unmodifiable(
          _periodsFromTotals(
            periodStarts,
            labels,
            const <DateTime, Money>{},
          ),
        ),
        currencyLabel: null,
        hasMixedCurrencies: true,
      );
    }

    final currentStart = DateTime(now.year, now.month);
    final currencyLabel = currenciesWithAmounts.isEmpty
        ? null
        : currenciesWithAmounts.single;
    return CreditCardInstallmentOverviewProjection(
      currentTotal: totals[currentStart] ?? Money.zero,
      remainingTotal: remaining,
      periods: List.unmodifiable(
        _periodsFromTotals(periodStarts, labels, totals),
      ),
      currencyLabel: currencyLabel,
      hasMixedCurrencies: false,
    );
  }

  static List<CreditCardInstallmentPeriodProjection> _periodsFromTotals(
    List<DateTime> periodStarts,
    List<String> labels,
    Map<DateTime, Money> totals,
  ) {
    return List<CreditCardInstallmentPeriodProjection>.generate(
      periodStarts.length,
      (index) => CreditCardInstallmentPeriodProjection(
        label: labels[index],
        amount: totals[periodStarts[index]] ?? Money.zero,
        isCurrent: index == 3,
      ),
      growable: false,
    );
  }

  static List<CreditCardInstallmentPeriodProjection> _emptyPeriods() =>
      <CreditCardInstallmentPeriodProjection>[
        CreditCardInstallmentPeriodProjection(label: '-3', amount: Money.zero),
        CreditCardInstallmentPeriodProjection(label: '-2', amount: Money.zero),
        CreditCardInstallmentPeriodProjection(label: '-1', amount: Money.zero),
        CreditCardInstallmentPeriodProjection(
          label: 'Now', amount: Money.zero, isCurrent: true,
        ),
        CreditCardInstallmentPeriodProjection(label: '+1', amount: Money.zero),
        CreditCardInstallmentPeriodProjection(label: '+2', amount: Money.zero),
        CreditCardInstallmentPeriodProjection(label: '+3', amount: Money.zero),
      ];

  static bool _isCancelled(String state) {
    final normalized = state.trim().toLowerCase();
    return normalized == 'cancelled' || normalized == 'canceled';
  }

  static int _daysUntilDue(int? paymentDueDay, DateTime now) {
    if (paymentDueDay == null) return 999;
    var due = DateTime(now.year, now.month, paymentDueDay);
    if (!due.isAfter(now)) {
      due = DateTime(now.year, now.month + 1, paymentDueDay);
    }
    return due.difference(now).inDays;
  }
}

final class CreditCardsListProjection {
  CreditCardsListProjection({
    required List<CreditCardListItemProjection> cards,
    required this.installmentOverview,
  }) : cards = List.unmodifiable(cards);

  final List<CreditCardListItemProjection> cards;
  final CreditCardInstallmentOverviewProjection installmentOverview;
}

final class CreditCardListItemProjection {
  const CreditCardListItemProjection({
    required this.accountId,
    required this.name,
    required this.bank,
    required this.lastFour,
    required this.creditLimit,
    required this.used,
    required this.availableCredit,
    required this.utilization,
    required this.daysUntilDue,
    required this.currency,
    required this.cardVisual,
  });

  final String accountId;
  final String name;
  final String bank;
  final String lastFour;
  final Money creditLimit;
  final Money used;
  final Money availableCredit;
  final double utilization;
  final int daysUntilDue;
  final String currency;
  final String cardVisual;
}

final class CreditCardInstallmentOverviewProjection {
  CreditCardInstallmentOverviewProjection({
    required this.currentTotal,
    required this.remainingTotal,
    required List<CreditCardInstallmentPeriodProjection> periods,
    required this.currencyLabel,
    required this.hasMixedCurrencies,
  }) : periods = List.unmodifiable(periods);

  final Money currentTotal;
  final Money remainingTotal;
  final List<CreditCardInstallmentPeriodProjection> periods;
  final String? currencyLabel;
  final bool hasMixedCurrencies;

  factory CreditCardInstallmentOverviewProjection.empty(
    List<CreditCardInstallmentPeriodProjection> periods,
  ) => CreditCardInstallmentOverviewProjection(
        currentTotal: Money.zero,
        remainingTotal: Money.zero,
        periods: periods,
        currencyLabel: null,
        hasMixedCurrencies: false,
      );
}

final class CreditCardInstallmentPeriodProjection {
  const CreditCardInstallmentPeriodProjection({
    required this.label,
    required this.amount,
    this.isCurrent = false,
  });

  final String label;
  final Money amount;
  final bool isCurrent;
}
