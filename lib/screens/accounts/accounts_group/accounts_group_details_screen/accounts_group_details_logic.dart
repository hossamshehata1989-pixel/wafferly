// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_logic.dart

import 'package:flutter/material.dart';

import '../../../../models/account.dart';
import '../../../../models/enums/account_enums.dart';
import '../../../../models/transaction.dart';
import '../../../../models/allocation.dart';
import '../../../../services/account_service.dart';
import '../../../../services/balance_service.dart';
import '../../../../services/allocation_service.dart';
import '../../../../theme/account_asset_resolver.dart';
import '../../../../models/enums/section_type.dart';

/// Financial/data logic used by AccountsGroupDetailsScreen.
///
/// This file contains the financial calculations and model-to-display mapping.
/// The screen remains responsible only for rendering and UI interaction.
class AccountsGroupDetailsLogic {
  const AccountsGroupDetailsLogic._();

  static const String allocationBoxName = AllocationService.boxName;

  static GroupFinancialData buildFinancialData({
    required String currency,
    required int periodMonths,
  }) {
    return GroupFinancialData.fromCurrentAccounts(
      AccountService().getAllActiveAccounts(),
      BalanceService(),
      AllocationService(),
      currency: currency,
      periodMonths: periodMonths,
    );
  }

  static List<AccountData> buildAccountList() {
    final balanceService = BalanceService();
    final allocationService = AllocationService();

    return AccountService()
        .getAllActiveAccounts()
        .where((account) => account.group == AccountGroup.liquidity)
        .map(
          (account) => buildAccountData(
            account,
            balanceService,
            allocationService,
          ),
        )
        .toList();
  }

  static AccountData buildAccountData(
    Account account,
    BalanceService balanceService,
    AllocationService allocationService,
  ) {
    final balance = balanceService.getBalance(account.id);
    final reserved = allocationService.getAllocatedAmountForAccount(account.id);
    final available = balance - reserved;
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
/// These rates are intentionally isolated here so the UI can later consume
/// the real FX resolver / stored exchange-rate snapshots without changing
/// the screen architecture.
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

  factory GroupFinancialData.fromCurrentAccounts(
    List<Account> accounts,
    BalanceService balanceService,
    AllocationService allocationService, {
    required String currency,
    required int periodMonths,
  }) {
    final activeLiquidityAccounts = accounts
        .where((account) => !account.isArchived)
        .where((account) => account.group == AccountGroup.liquidity)
        .toList();

    final currencies = activeLiquidityAccounts
        .map((account) => account.currency.toUpperCase())
        .where((currency) => currency.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final totalsByCurrency = <String, double>{};
    final reservedByCurrency = <String, double>{};

    for (final account in activeLiquidityAccounts) {
      final accountCurrency = account.currency.toUpperCase();
      final balance = balanceService.getBalance(account.id);
      final reserved = allocationService
          .getAllocatedAmountForAccount(account.id)
          .clamp(0.0, balance)
          .toDouble();

      totalsByCurrency[accountCurrency] =
          (totalsByCurrency[accountCurrency] ?? 0) + balance;
      reservedByCurrency[accountCurrency] =
          (reservedByCurrency[accountCurrency] ?? 0) + reserved;
    }

    final totalBreakdown = <CurrencyAmount>[];
    final availableBreakdown = <CurrencyAmount>[];
    final reservedBreakdown = <CurrencyAmount>[];

    for (final entry in totalsByCurrency.entries) {
      final nativeTotal = entry.value;
      final nativeReserved = reservedByCurrency[entry.key] ?? 0;
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
    final available = totalBalance - reserved;

    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];
    final dates = <DateTime>[];
    final safePeriod = periodMonths.clamp(1, 24).toInt();

    for (int offset = safePeriod - 1; offset >= 0; offset--) {
      final monthDate = DateTime(now.year, now.month - offset + 1, 0);
      final snapshotDate = offset == 0 ? now : monthDate;

      double monthBalance = 0;
      for (final account in activeLiquidityAccounts) {
        final nativeBalance = balanceService.getBalanceAtDate(
          account.id,
          snapshotDate,
        );

        monthBalance += _OverviewFx.toDisplay(
          amount: nativeBalance,
          fromCurrency: account.currency,
          displayCurrency: currency,
        );
      }

      values.add(monthBalance);
      dates.add(snapshotDate);
      labels.add(monthLabel(snapshotDate.month));
    }

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
    );
  }
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
