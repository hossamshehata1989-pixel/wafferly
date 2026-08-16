// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_logic.dart

import 'package:flutter/material.dart';

import '../../../../models/account.dart';
import '../../../../models/enums/account_enums.dart';
import '../../../../services/account_service.dart';
import '../../../../services/balance_service.dart';
import '../../../../core/planning/services/available_balance_projection_service.dart';
import '../../../../theme/account_asset_resolver.dart';
import '../../../../models/enums/section_type.dart';

// ============================================================================
// OVERVIEW PERIOD
// ============================================================================

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

// ============================================================================
// ACCOUNT TYPE FILTER
// ============================================================================

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

// ============================================================================
// MAIN LOGIC
// ============================================================================

/// Financial/data logic used by AccountsGroupDetailsScreen.
///
/// This file owns:
/// - Financial calculations.
/// - Currency filtering.
/// - Balance history.
/// - Planning projection mapping.
/// - Model-to-display mapping.
///
/// The screen remains responsible only for rendering and UI interaction.
///
/// IMPORTANT:
/// - Balance remains sourced from BalanceService.
/// - Reserved / Available are read from the Planning read-side projection.
/// - The legacy AllocationService is intentionally not used here.
/// - No FX conversion is performed here.
/// - Different currencies are NEVER added together.
/// - A single numeric Total/Available/Reserved is only meaningful when a
///   single currency is selected.
class AccountsGroupDetailsLogic {
  const AccountsGroupDetailsLogic._();

  // ==========================================================================
  // FINANCIAL OVERVIEW
  // ==========================================================================

  static Future<GroupFinancialData> buildFinancialData({
    required String? currencyFilter,
    required OverviewPeriod period,
    required AvailableBalanceProjectionService projectionService,
  }) {
    return GroupFinancialData.fromCurrentAccounts(
      AccountService().getAllActiveAccounts(),
      BalanceService(),
      projectionService,
      currencyFilter: currencyFilter,
      period: period,
    );
  }

  // ==========================================================================
  // ACCOUNT LIST
  // ==========================================================================

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

  // ==========================================================================
  // ACCOUNT TYPE RESOLUTION
  // ==========================================================================

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

  // ==========================================================================
  // SINGLE ACCOUNT DATA
  // ==========================================================================

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
      accountId: account.id,
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

  // ==========================================================================
  // ACCOUNT DISPLAY HELPERS
  // ==========================================================================

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
    if (isLiability) {
      return const Color(0xFFFF5572);
    }

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

// ============================================================================
// CURRENCY AMOUNT
// ============================================================================

/// Amount belonging to one native currency.
///
/// `originalAmount` is kept for compatibility with the existing UI.
///
/// `convertedAmount` is also kept for compatibility, but this logic layer
/// deliberately performs NO currency conversion. Therefore both values are
/// currently identical.
///
/// Real FX conversion should be introduced later through the dedicated
/// Financial/FX read model rather than through this overview logic.
class CurrencyAmount {
  const CurrencyAmount({
    required this.currency,
    required this.originalAmount,
    required this.convertedAmount,
  });

  final String currency;

  /// Native amount in [currency].
  final double originalAmount;

  /// Compatibility field.
  ///
  /// No FX conversion is performed here.
  /// This is currently equal to [originalAmount].
  final double convertedAmount;
}

// ============================================================================
// GROUP FINANCIAL DATA
// ============================================================================

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
    required this.effectiveCurrency,
    required this.totalBreakdown,
    required this.availableBreakdown,
    required this.reservedBreakdown,
    required this.accountTypeBreakdown,
  });

  /// Single-currency total.
  ///
  /// When All currencies is selected and all eligible accounts use exactly
  /// one native currency, that currency is used as the effective currency.
  /// When multiple native currencies exist, this remains 0 because different
  /// currencies must never be added together.
  final double totalBalance;

  /// Single-currency available amount.
  ///
  /// When All currencies contains exactly one native currency, this is
  /// calculated normally. With multiple native currencies, this is 0.
  final double available;

  /// Single-currency reserved amount.
  ///
  /// When All currencies contains exactly one native currency, this is
  /// calculated normally. With multiple native currencies, this is 0.
  final double reserved;

  /// Historical balance chart.
  ///
  /// Populated whenever the overview has one effective native currency.
  /// This includes All currencies when all eligible accounts use one currency.
  /// It remains empty when multiple currencies are present.
  final List<double> chartValues;

  final List<String> chartLabels;

  final List<DateTime> chartDates;

  final double latestBalance;

  final DateTime latestDate;

  /// All available native currencies in the overview.
  final List<String> availableCurrencies;

  /// The currency that is safe to use for single-currency headline metrics.
  ///
  /// When a specific currency is selected, this is that currency.
  /// When All is selected, this is populated only if exactly one native
  /// currency exists across the eligible overview accounts.
  final String? effectiveCurrency;

  /// Native balance breakdown by currency.
  final List<CurrencyAmount> totalBreakdown;

  /// Native available amount breakdown by currency.
  final List<CurrencyAmount> availableBreakdown;

  /// Native reserved amount breakdown by currency.
  final List<CurrencyAmount> reservedBreakdown;

  /// Account-type breakdown.
  ///
  /// Populated whenever the overview has one effective native currency.
  final List<AccountTypeAmount> accountTypeBreakdown;

  // ==========================================================================
  // BUILD FROM CURRENT ACCOUNTS
  // ==========================================================================

  static Future<GroupFinancialData> fromCurrentAccounts(
    List<Account> accounts,
    BalanceService balanceService,
    AvailableBalanceProjectionService projectionService, {
    required String? currencyFilter,
    required OverviewPeriod period,
  }) async {
    // ------------------------------------------------------------------------
    // STEP 1 — Active liquidity accounts
    // ------------------------------------------------------------------------

    final activeLiquidityAccounts = accounts
        .where((account) => !account.isArchived)
        .where((account) => account.group == AccountGroup.liquidity)
        .toList();

    // ------------------------------------------------------------------------
    // STEP 2 — Define which accounts participate in Liquidity Overview
    // ------------------------------------------------------------------------
    //
    // Liquidity overview represents money that can actually be spent.
    //
    // Investments and liability accounts remain visible in the Accounts list,
    // but do not inflate Total Balance / Available / Reserved here.
    // ------------------------------------------------------------------------

    final eligibleOverviewAccounts = activeLiquidityAccounts
        .where((account) => account.nature.name != 'liability')
        .where(
          (account) =>
              AccountsGroupDetailsLogic._accountTypeFor(account) !=
              AccountTypeFilter.investment,
        )
        .toList();

    // ------------------------------------------------------------------------
    // STEP 3 — Available currencies
    // ------------------------------------------------------------------------
    //
    // IMPORTANT:
    // This list is independent from the currently selected currency.
    //
    // Example:
    //
    // EGP + USD + SAR accounts
    //
    // availableCurrencies:
    // [EGP, SAR, USD]
    // ------------------------------------------------------------------------

    final availableCurrencies =
        eligibleOverviewAccounts
            .map((account) => account.currency.toUpperCase())
            .where((currency) => currency.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // ------------------------------------------------------------------------
    // STEP 4 — Apply currency filter
    // ------------------------------------------------------------------------

    final normalizedCurrencyFilter = currencyFilter?.trim().toUpperCase();

    final overviewAccounts = normalizedCurrencyFilter == null
        ? eligibleOverviewAccounts
        : eligibleOverviewAccounts
              .where(
                (account) =>
                    account.currency.toUpperCase() == normalizedCurrencyFilter,
              )
              .toList();

    // ------------------------------------------------------------------------
    // STEP 5 — Determine whether we have a single currency context
    // ------------------------------------------------------------------------
    //
    // A specific currency filter is always a single-currency context.
    //
    // "All" is ALSO a single-currency context when all eligible accounts
    // happen to use exactly one native currency (for example, EGP only).
    //
    // We still refuse to create a single numeric total when multiple native
    // currencies exist, because that would mix monetary units without FX.
    // ------------------------------------------------------------------------

    final effectiveCurrency =
        normalizedCurrencyFilter ??
        (availableCurrencies.length == 1 ? availableCurrencies.first : null);

    final hasSingleCurrency = effectiveCurrency != null;

    // ------------------------------------------------------------------------
    // STEP 6 — Read account balances + planning projections
    // ------------------------------------------------------------------------

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

    // ------------------------------------------------------------------------
    // STEP 7 — Aggregate by native currency
    // ------------------------------------------------------------------------

    final totalsByCurrency = <String, double>{};

    final reservedByCurrency = <String, double>{};

    final typeTotals = <AccountTypeFilter, double>{
      for (final type in AccountTypeFilter.values)
        if (type != AccountTypeFilter.all) type: 0,
    };

    for (final item in projections) {
      final accountCurrency = item.account.currency.trim().toUpperCase();

      if (accountCurrency.isEmpty) {
        continue;
      }

      // ----------------------------------------------------------------------
      // Reserved cannot exceed current balance.
      // ----------------------------------------------------------------------

      final reserved = item.reserved.clamp(0.0, item.balance).toDouble();

      // ----------------------------------------------------------------------
      // Available cannot become negative.
      // ----------------------------------------------------------------------

      final available = (item.balance - reserved)
          .clamp(0.0, double.infinity)
          .toDouble();

      // ----------------------------------------------------------------------
      // Native totals
      // ----------------------------------------------------------------------

      totalsByCurrency[accountCurrency] =
          (totalsByCurrency[accountCurrency] ?? 0) + item.balance;

      reservedByCurrency[accountCurrency] =
          (reservedByCurrency[accountCurrency] ?? 0) + reserved;

      // ----------------------------------------------------------------------
      // Account type breakdown
      //
      // This is only meaningful when a single currency is selected.
      // However, because overviewAccounts itself is filtered when a currency
      // is selected, the aggregation here remains currency-safe.
      // ----------------------------------------------------------------------

      if (hasSingleCurrency) {
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
    }

    // ------------------------------------------------------------------------
    // STEP 8 — Build native currency breakdowns
    // ------------------------------------------------------------------------

    final totalBreakdown = <CurrencyAmount>[];

    final availableBreakdown = <CurrencyAmount>[];

    final reservedBreakdown = <CurrencyAmount>[];

    final sortedCurrencies = totalsByCurrency.keys.toList()..sort();

    for (final currency in sortedCurrencies) {
      final nativeTotal = totalsByCurrency[currency] ?? 0;

      final nativeReserved = (reservedByCurrency[currency] ?? 0)
          .clamp(0.0, nativeTotal)
          .toDouble();

      final nativeAvailable = (nativeTotal - nativeReserved)
          .clamp(0.0, double.infinity)
          .toDouble();

      // ----------------------------------------------------------------------
      // IMPORTANT:
      // No FX conversion.
      //
      // originalAmount == convertedAmount
      // ----------------------------------------------------------------------

      totalBreakdown.add(
        CurrencyAmount(
          currency: currency,
          originalAmount: nativeTotal,
          convertedAmount: nativeTotal,
        ),
      );

      availableBreakdown.add(
        CurrencyAmount(
          currency: currency,
          originalAmount: nativeAvailable,
          convertedAmount: nativeAvailable,
        ),
      );

      reservedBreakdown.add(
        CurrencyAmount(
          currency: currency,
          originalAmount: nativeReserved,
          convertedAmount: nativeReserved,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // STEP 9 — Single-currency headline metrics
    // ------------------------------------------------------------------------
    //
    // If All currencies is selected:
    //
    // totalBalance = 0
    // available    = 0
    // reserved     = 0
    //
    // because:
    //
    // 100,000 EGP + 2,000 USD
    //
    // is NOT mathematically meaningful without an FX conversion context.
    // ------------------------------------------------------------------------

    double totalBalance = 0;

    double reserved = 0;

    double available = 0;

    if (effectiveCurrency != null) {
      totalBalance = totalsByCurrency[effectiveCurrency] ?? 0;

      reserved = (reservedByCurrency[effectiveCurrency] ?? 0)
          .clamp(0.0, totalBalance)
          .toDouble();

      available = (totalBalance - reserved)
          .clamp(0.0, double.infinity)
          .toDouble();
    }

    // ------------------------------------------------------------------------
    // STEP 10 — Historical balance chart
    // ------------------------------------------------------------------------
    //
    // The chart is enabled whenever there is one effective native currency.
    //
    // Therefore All + one currency is safe, while All + multiple currencies
    // remains disabled.
    //
    // Example:
    //
    // EGP: 100,000
    // USD: 2,000
    //
    // cannot become:
    //
    // 102,000
    //
    // without FX conversion.
    // ------------------------------------------------------------------------

    final now = DateTime.now();

    final values = <double>[];

    final labels = <String>[];

    final dates = <DateTime>[];

    if (hasSingleCurrency && overviewAccounts.isNotEmpty) {
      DateTime startOfDay(DateTime value) {
        return DateTime(value.year, value.month, value.day);
      }

      void addSnapshot(DateTime snapshotDate) {
        double snapshotBalance = 0;

        for (final account in overviewAccounts) {
          final nativeBalance = balanceService.getBalanceAtDate(
            account.id,
            snapshotDate,
          );

          // IMPORTANT:
          // This loop is only reached when effectiveCurrency is non-null.
          // Therefore all overview accounts have the same native currency
          // in this context, even when the UI filter is All.
          //
          // Therefore native balances can safely be added.
          snapshotBalance += nativeBalance;
        }

        values.add(snapshotBalance);

        dates.add(snapshotDate);

        labels.add(monthLabel(snapshotDate.month));
      }

      switch (period) {
        // --------------------------------------------------------------------
        // THIS WEEK
        // --------------------------------------------------------------------

        case OverviewPeriod.thisWeek:
          final start = startOfDay(now).subtract(const Duration(days: 6));

          for (int i = 0; i < 7; i++) {
            final date = start.add(Duration(days: i));

            addSnapshot(date);

            labels[labels.length - 1] = _weekdayLabel(date.weekday);
          }

          break;

        // --------------------------------------------------------------------
        // THIS MONTH
        // --------------------------------------------------------------------

        case OverviewPeriod.thisMonth:
          final start = DateTime(now.year, now.month, 1);

          final days = now.difference(start).inDays;

          for (int i = 0; i <= days; i++) {
            addSnapshot(start.add(Duration(days: i)));
          }

          break;

        // --------------------------------------------------------------------
        // MULTI-MONTH PERIODS
        // --------------------------------------------------------------------

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
    }

    // ------------------------------------------------------------------------
    // STEP 11 — Account type breakdown
    // ------------------------------------------------------------------------
    //
    // Expose it whenever the overview has one effective native currency.
    //
    // For All currencies with multiple native currencies, the amounts would
    // otherwise mix monetary units.
    // ------------------------------------------------------------------------

    const displayTypes = [
      AccountTypeFilter.cash,
      AccountTypeFilter.wallet,
      AccountTypeFilter.card,
      AccountTypeFilter.bank,
    ];

    final accountTypeBreakdown = hasSingleCurrency
        ? [
            for (final type in displayTypes)
              AccountTypeAmount(
                type: type,
                amount: typeTotals[type] ?? 0,
                isLiability: false,
              ),
          ]
        : const <AccountTypeAmount>[];

    // ------------------------------------------------------------------------
    // STEP 12 — Return read model
    // ------------------------------------------------------------------------

    return GroupFinancialData(
      totalBalance: totalBalance,
      available: available,
      reserved: reserved,
      chartValues: values,
      chartLabels: labels,
      chartDates: dates,
      latestBalance: values.isEmpty ? totalBalance : values.last,
      latestDate: now,
      availableCurrencies: availableCurrencies.isEmpty
          ? const []
          : availableCurrencies,
      effectiveCurrency: effectiveCurrency,
      totalBreakdown: totalBreakdown,
      availableBreakdown: availableBreakdown,
      reservedBreakdown: reservedBreakdown,
      accountTypeBreakdown: accountTypeBreakdown,
    );
  }
}

// ============================================================================
// ALL-TIME PERIOD
// ============================================================================

int _allTimeMonthCount(List<Account> accounts, DateTime now) {
  if (accounts.isEmpty) {
    return 1;
  }

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

// ============================================================================
// DATE LABELS
// ============================================================================

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

// ============================================================================
// MONEY FORMATTER
// ============================================================================

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

// ============================================================================
// ACCOUNT TYPE AMOUNT
// ============================================================================

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

// ============================================================================
// ACCOUNT DATA
// ============================================================================

class AccountData {
  final String accountId;
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
    required this.accountId,
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
