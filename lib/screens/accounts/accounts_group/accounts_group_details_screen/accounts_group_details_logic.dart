// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_logic.dart

import 'package:flutter/material.dart';

import '../../../../models/account.dart';
import '../../../../models/enums/account_enums.dart';
import '../../../../services/account_service.dart';
import '../../../../services/balance_service.dart';
import '../../../../core/planning/services/available_balance_projection_service.dart';
import '../../../../theme/account_asset_resolver.dart';
import '../../../../models/enums/section_type.dart';

enum OverviewPeriod {
  thisWeek,
  thisMonth,
  threeMonths,
  sixMonths,
  twelveMonths,
  allTime;

  String get label => switch (this) {
    OverviewPeriod.thisWeek => 'This week',
    OverviewPeriod.thisMonth => 'This month',
    OverviewPeriod.threeMonths => '3 Months',
    OverviewPeriod.sixMonths => '6 Months',
    OverviewPeriod.twelveMonths => '12 Months',
    OverviewPeriod.allTime => 'Since start',
  };

  IconData get icon => switch (this) {
    OverviewPeriod.thisWeek => Icons.view_week_rounded,
    OverviewPeriod.thisMonth => Icons.calendar_month_rounded,
    OverviewPeriod.threeMonths => Icons.calendar_view_month_rounded,
    OverviewPeriod.sixMonths => Icons.calendar_view_month_rounded,
    OverviewPeriod.twelveMonths => Icons.date_range_rounded,
    OverviewPeriod.allTime => Icons.history_rounded,
  };
}

enum AccountTypeFilter {
  all,
  cash,
  wallet,
  bank,
  card,
  investment,
  other;

  String get label => switch (this) {
    AccountTypeFilter.all => 'All',
    AccountTypeFilter.cash => 'Cash',
    AccountTypeFilter.wallet => 'Wallets',
    AccountTypeFilter.bank => 'Banks',
    AccountTypeFilter.card => 'Cards',
    AccountTypeFilter.investment => 'Investments',
    AccountTypeFilter.other => 'Other',
  };

  IconData get icon => switch (this) {
    AccountTypeFilter.all => Icons.account_balance_wallet_rounded,
    AccountTypeFilter.cash => Icons.payments_rounded,
    AccountTypeFilter.wallet => Icons.account_balance_wallet_rounded,
    AccountTypeFilter.bank => Icons.account_balance_rounded,
    AccountTypeFilter.card => Icons.credit_card_rounded,
    AccountTypeFilter.investment => Icons.bar_chart_rounded,
    AccountTypeFilter.other => Icons.category_rounded,
  };

  Color get color => switch (this) {
    AccountTypeFilter.all => const Color(0xFF35E0B5),
    AccountTypeFilter.cash => const Color(0xFF4AA8FF),
    AccountTypeFilter.wallet => const Color(0xFFB17CFF),
    AccountTypeFilter.bank => const Color(0xFF35E0B5),
    AccountTypeFilter.card => const Color(0xFFFF5572),
    AccountTypeFilter.investment => const Color(0xFFFFA928),
    AccountTypeFilter.other => Colors.white70,
  };
}

/// Financial/data logic used by AccountsGroupDetailsScreen.
///
/// This file owns the financial calculations and model-to-display mapping.
/// The screen remains responsible only for rendering and UI interaction.
///
/// IMPORTANT:
/// - Balance remains sourced from BalanceService.
/// - Reserved / Available are read from the Planning read-side projection.
/// - The legacy AllocationService is intentionally not used here.
class AccountsGroupDetailsLogic {
  const AccountsGroupDetailsLogic._();

  static Future<GroupFinancialData> buildFinancialData({
    required String currency,
    required OverviewPeriod period,
    required AvailableBalanceProjectionService projectionService,
  }) {
    return GroupFinancialData.fromCurrentAccounts(
      AccountService().getAllActiveAccounts(),
      BalanceService(),
      projectionService,
      currency: currency,
      period: period,
    );
  }

  static Future<List<AccountData>> buildAccountList({
    required AvailableBalanceProjectionService projectionService,
    AccountTypeFilter filter = AccountTypeFilter.all,
  }) async {
    final balanceService = BalanceService();

    final accounts = AccountService()
        .getAllActiveAccounts()
        .where((account) => account.group == AccountGroup.liquidity)
        .where((account) => _matchesAccountType(account, filter))
        .toList();

    return Future.wait(
      accounts.map(
        (account) =>
            buildAccountData(account, balanceService, projectionService),
      ),
    );
  }

  static bool _matchesAccountType(Account account, AccountTypeFilter filter) {
    if (filter == AccountTypeFilter.all) return true;
    return _accountTypeFor(account) == filter;
  }

  static AccountTypeFilter _accountTypeFor(Account account) {
    final type = account.type.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );

    if (type == 'cash' || type.contains('cash')) {
      return AccountTypeFilter.cash;
    }
    if (type == 'wallet' || type.contains('wallet')) {
      return AccountTypeFilter.wallet;
    }
    if (type == 'bank' || type.contains('bank')) {
      return AccountTypeFilter.bank;
    }
    if (type.contains('card') || type.contains('credit')) {
      return AccountTypeFilter.card;
    }
    if (type.contains('investment') ||
        type.contains('stock') ||
        type.contains('gold') ||
        type.contains('certificate')) {
      return AccountTypeFilter.investment;
    }

    return AccountTypeFilter.other;
  }

  static Future<AccountData> buildAccountData(
    Account account,
    BalanceService balanceService,
    AvailableBalanceProjectionService projectionService,
  ) async {
    final balance = balanceService.getBalance(account.id);

    final projection = await projectionService.project(
      accountId: account.id,
      balance: balance,
    );

    final reserved = projection.reserved;
    final available = projection.available;
    final isLiability = account.nature.name == 'liability';
    final iconColor = _colorForAccountType(account.type, isLiability);

    return AccountData(
      iconAsset: _resolveAccountIcon(account),
      iconColor: iconColor,
      iconBackground: iconColor.withValues(alpha: 0.18),
      name: account.name,
      subtitle: _prettyAccountType(account.type),
      balance: formatMoney(balance),
      balanceSuffix: account.currency,
      available: isLiability
          ? 'Outstanding ${formatMoney(balance.abs())} ${account.currency}'
          : 'Available ${formatMoney(available)} ${account.currency}',
      reserved: isLiability
          ? '—'
          : 'Reserved ${formatMoney(reserved)} ${account.currency}',
      showAvailable: false,
      isLiability: isLiability,
    );
  }

  static String _prettyAccountType(String type) {
    final spaced = type.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return spaced.isEmpty
        ? type
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String _resolveAccountIcon(Account account) {
    final savedIcon = account.icon;
    if (savedIcon != null && savedIcon.isNotEmpty) {
      return savedIcon;
    }

    final icons = AccountAssetResolver.iconsForType(
      SectionType.liquidity,
      account.type,
    );

    if (icons.isNotEmpty) {
      return icons.first;
    }

    return AccountAssetResolver.defaultIcon(SectionType.liquidity);
  }

  static Color _colorForAccountType(String type, bool isLiability) {
    if (isLiability) return const Color(0xFFFF5572);

    switch (type) {
      case 'bank':
        return const Color(0xFF35E0B5);
      case 'wallet':
        return const Color(0xFFB17CFF);
      case 'investment':
      case 'stocks':
      case 'gold':
      case 'certificates':
        return const Color(0xFFFFA928);
      case 'cash':
        return const Color(0xFF4AA8FF);
      default:
        return const Color(0xFF35E0B5);
    }
  }
}

class CurrencyAmount {
  const CurrencyAmount({
    required this.currency,
    required this.originalAmount,
    required this.convertedAmount,
  });

  final String currency;
  final double originalAmount;
  final double convertedAmount;
}

/// Display-only FX resolver for the overview.
///
/// The financial truth remains the account balance in its native currency.
/// These rates remain isolated here until the real FX resolver / stored
/// exchange-rate snapshot source is wired into the read model.
class _OverviewFx {
  static const Map<String, double> _egpRates = {
    'EGP': 1.0,
    'USD': 50.0,
    'SAR': 12.0,
    'EUR': 55.0,
    'GBP': 64.0,
  };

  static double toDisplay({
    required double amount,
    required String fromCurrency,
    required String displayCurrency,
  }) {
    final from = _egpRates[fromCurrency.toUpperCase()];
    final to = _egpRates[displayCurrency.toUpperCase()];

    // Unknown currencies are kept in native units rather than inventing a
    // conversion rate. The official FX resolver can replace this later.
    if (from == null || to == null || to == 0) return amount;
    return amount * from / to;
  }
}

class GroupFinancialData {
  const GroupFinancialData({
    required this.totalBalance,
    required this.available,
    required this.reserved,
    required this.chartValues,
    required this.chartLabels,
    required this.chartDates,
    required this.latestBalance,
    required this.latestDate,
    required this.availableCurrencies,
    required this.totalBreakdown,
    required this.availableBreakdown,
    required this.reservedBreakdown,
    required this.accountTypeBreakdown,
  });

  final double totalBalance;
  final double available;
  final double reserved;
  final List<double> chartValues;
  final List<String> chartLabels;
  final List<DateTime> chartDates;
  final double latestBalance;
  final DateTime latestDate;
  final List<String> availableCurrencies;
  final List<CurrencyAmount> totalBreakdown;
  final List<CurrencyAmount> availableBreakdown;
  final List<CurrencyAmount> reservedBreakdown;
  final List<AccountTypeAmount> accountTypeBreakdown;

  static Future<GroupFinancialData> fromCurrentAccounts(
    List<Account> accounts,
    BalanceService balanceService,
    AvailableBalanceProjectionService projectionService, {
    required String currency,
    required OverviewPeriod period,
  }) async {
    final activeLiquidityAccounts = accounts
        .where((account) => !account.isArchived)
        .where((account) => account.group == AccountGroup.liquidity)
        .toList();

    // Liquidity overview represents money that can actually be spent.
    // Investments and liability accounts remain visible in the Accounts list,
    // but do not inflate Total Balance / Available / Reserved here.
    final overviewAccounts = activeLiquidityAccounts
        .where((account) => account.nature.name != 'liability')
        .where(
          (account) =>
              AccountsGroupDetailsLogic._accountTypeFor(account) !=
              AccountTypeFilter.investment,
        )
        .toList();

    final currencies =
        overviewAccounts
            .map((account) => account.currency.toUpperCase())
            .where((currency) => currency.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final totalsByCurrency = <String, double>{};
    final reservedByCurrency = <String, double>{};
    final typeTotals = <AccountTypeFilter, double>{
      for (final type in AccountTypeFilter.values)
        if (type != AccountTypeFilter.all) type: 0,
    };

    final projections = await Future.wait(
      overviewAccounts.map((account) async {
        final balance = balanceService.getBalance(account.id);

        final projection = await projectionService.project(
          accountId: account.id,
          balance: balance,
        );

        return (
          account: account,
          balance: balance,
          reserved: projection.reserved,
        );
      }),
    );

    for (final item in projections) {
      final accountCurrency = item.account.currency.toUpperCase();

      final reserved = item.reserved.clamp(0.0, item.balance).toDouble();
      final available = (item.balance - reserved)
          .clamp(0.0, double.infinity)
          .toDouble();

      totalsByCurrency[accountCurrency] =
          (totalsByCurrency[accountCurrency] ?? 0) + item.balance;

      reservedByCurrency[accountCurrency] =
          (reservedByCurrency[accountCurrency] ?? 0) + reserved;

      final accountType = AccountsGroupDetailsLogic._accountTypeFor(
        item.account,
      );

      if (accountType == AccountTypeFilter.cash ||
          accountType == AccountTypeFilter.wallet ||
          accountType == AccountTypeFilter.card ||
          accountType == AccountTypeFilter.bank) {
        typeTotals[accountType] = (typeTotals[accountType] ?? 0) + available;
      }
    }

    final totalBreakdown = <CurrencyAmount>[];
    final availableBreakdown = <CurrencyAmount>[];
    final reservedBreakdown = <CurrencyAmount>[];

    for (final entry in totalsByCurrency.entries) {
      final nativeTotal = entry.value;
      final nativeReserved = (reservedByCurrency[entry.key] ?? 0)
          .clamp(0.0, nativeTotal)
          .toDouble();
      final nativeAvailable = nativeTotal - nativeReserved;

      totalBreakdown.add(
        CurrencyAmount(
          currency: entry.key,
          originalAmount: nativeTotal,
          convertedAmount: _OverviewFx.toDisplay(
            amount: nativeTotal,
            fromCurrency: entry.key,
            displayCurrency: currency,
          ),
        ),
      );

      availableBreakdown.add(
        CurrencyAmount(
          currency: entry.key,
          originalAmount: nativeAvailable,
          convertedAmount: _OverviewFx.toDisplay(
            amount: nativeAvailable,
            fromCurrency: entry.key,
            displayCurrency: currency,
          ),
        ),
      );

      reservedBreakdown.add(
        CurrencyAmount(
          currency: entry.key,
          originalAmount: nativeReserved,
          convertedAmount: _OverviewFx.toDisplay(
            amount: nativeReserved,
            fromCurrency: entry.key,
            displayCurrency: currency,
          ),
        ),
      );
    }

    totalBreakdown.sort((a, b) => a.currency.compareTo(b.currency));
    availableBreakdown.sort((a, b) => a.currency.compareTo(b.currency));
    reservedBreakdown.sort((a, b) => a.currency.compareTo(b.currency));

    double totalBalance = 0;
    double reserved = 0;

    for (final item in totalBreakdown) {
      totalBalance += item.convertedAmount;
    }

    for (final item in reservedBreakdown) {
      reserved += item.convertedAmount;
    }

    reserved = reserved.clamp(0.0, totalBalance).toDouble();
    final available = (totalBalance - reserved)
        .clamp(0.0, double.infinity)
        .toDouble();

    // Keep the chart exactly as a balance history. Reserved money is a
    // planning projection and must not alter historical account balances.
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];
    final dates = <DateTime>[];

    DateTime startOfDay(DateTime value) =>
        DateTime(value.year, value.month, value.day);

    void addSnapshot(DateTime snapshotDate) {
      double snapshotBalance = 0;
      for (final account in overviewAccounts) {
        final nativeBalance = balanceService.getBalanceAtDate(
          account.id,
          snapshotDate,
        );

        snapshotBalance += _OverviewFx.toDisplay(
          amount: nativeBalance,
          fromCurrency: account.currency,
          displayCurrency: currency,
        );
      }

      values.add(snapshotBalance);
      dates.add(snapshotDate);
      labels.add(monthLabel(snapshotDate.month));
    }

    switch (period) {
      case OverviewPeriod.thisWeek:
        final start = startOfDay(now).subtract(const Duration(days: 6));
        for (int i = 0; i < 7; i++) {
          final date = start.add(Duration(days: i));
          addSnapshot(date);
          labels[labels.length - 1] = _weekdayLabel(date.weekday);
        }
        break;

      case OverviewPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final days = now.difference(start).inDays;
        for (int i = 0; i <= days; i++) {
          addSnapshot(start.add(Duration(days: i)));
        }
        break;

      case OverviewPeriod.threeMonths:
      case OverviewPeriod.sixMonths:
      case OverviewPeriod.twelveMonths:
      case OverviewPeriod.allTime:
        final monthCount = switch (period) {
          OverviewPeriod.threeMonths => 3,
          OverviewPeriod.sixMonths => 6,
          OverviewPeriod.twelveMonths => 12,
          OverviewPeriod.allTime => _allTimeMonthCount(overviewAccounts, now),
          OverviewPeriod.thisWeek => 1,
          OverviewPeriod.thisMonth => 1,
        };

        for (int offset = monthCount - 1; offset >= 0; offset--) {
          final monthStart = DateTime(now.year, now.month - offset, 1);
          final snapshotDate = offset == 0
              ? now
              : DateTime(monthStart.year, monthStart.month + 1, 0);
          addSnapshot(snapshotDate);
        }
        break;
    }

    const displayTypes = [
      AccountTypeFilter.cash,
      AccountTypeFilter.wallet,
      AccountTypeFilter.card,
      AccountTypeFilter.bank,
    ];

    final accountTypeBreakdown = [
      for (final type in displayTypes)
        AccountTypeAmount(
          type: type,
          amount: typeTotals[type] ?? 0,
          isLiability: false,
        ),
    ];

    return GroupFinancialData(
      totalBalance: totalBalance,
      available: available,
      reserved: reserved,
      chartValues: values,
      chartLabels: labels,
      chartDates: dates,
      latestBalance: values.isEmpty ? totalBalance : values.last,
      latestDate: now,
      availableCurrencies: currencies.isEmpty ? [currency] : currencies,
      totalBreakdown: totalBreakdown,
      availableBreakdown: availableBreakdown,
      reservedBreakdown: reservedBreakdown,
      accountTypeBreakdown: accountTypeBreakdown,
    );
  }
}

int _allTimeMonthCount(List<Account> accounts, DateTime now) {
  if (accounts.isEmpty) return 1;

  final earliest = accounts
      .map((account) => account.createdAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  final earliestMonth = DateTime(earliest.year, earliest.month);
  final currentMonth = DateTime(now.year, now.month);

  return (currentMonth.year - earliestMonth.year) * 12 +
      currentMonth.month -
      earliestMonth.month +
      1;
}

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[weekday - 1];
}

String monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return labels[month - 1];
}

String formatMoney(double value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return '$sign$buffer';
}

class AccountTypeAmount {
  const AccountTypeAmount({
    required this.type,
    required this.amount,
    required this.isLiability,
  });

  final AccountTypeFilter type;
  final double amount;
  final bool isLiability;

  String get label => type.label;
  IconData get icon => type.icon;
  Color get color => isLiability ? const Color(0xFFFF5572) : type.color;
}

class AccountData {
  final String iconAsset;
  final Color iconColor;
  final Color iconBackground;
  final String name;
  final String subtitle;
  final String balance;
  final String balanceSuffix;
  final String available;
  final String reserved;
  final bool showAvailable;
  final String? badge;
  final bool isLiability;

  const AccountData({
    required this.iconAsset,
    required this.iconColor,
    required this.iconBackground,
    required this.name,
    required this.subtitle,
    required this.balance,
    required this.balanceSuffix,
    required this.available,
    required this.reserved,
    required this.showAvailable,
    this.badge,
    this.isLiability = false,
  });
}
