// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../models/account.dart';
import '../../../../models/enums/account_enums.dart';
import '../../../../models/transaction.dart';
import '../../../../models/allocation.dart';
import '../../../../services/account_service.dart';
import '../../../../services/balance_service.dart';
import '../../../../services/allocation_service.dart';
import '../../../../theme/responsive_metrics.dart';

class AccountsGroupDetailsScreen extends StatelessWidget {
  const AccountsGroupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020D16),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(m: m)),
            SliverToBoxAdapter(child: _BalanceOverview(m: m)),
            SliverToBoxAdapter(child: _AccountsHeader(m: m)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                m.spacing(20),
                0,
                m.spacing(20),
                m.spacing(24),
              ),
              sliver: _AccountsList(m: m),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// HEADER
// ================================================================

class _Header extends StatelessWidget {
  const _Header({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = m.isCompactHeight ? 20.0 : 24.0;
    final verticalPadding = m.isCompactHeight ? 10.0 : 13.0;
    final controlSize = m.isCompactHeight ? 42.0 : 46.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(horizontalPadding),
        m.spacing(verticalPadding),
        m.spacing(horizontalPadding),
        m.spacing(verticalPadding),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CircleButton(
            icon: Icons.menu_rounded,
            size: m.size(controlSize),
            m: m,
          ),
          SizedBox(width: m.spacing(12)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: TextStyle(
                    fontSize: m.isCompactHeight ? m.text(13) : m.text(15),
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: m.h(2)),
                Text(
                  'Hossam 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: m.isCompactHeight ? m.text(22) : m.text(27),
                    height: 1.05,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: m.h(4)),
                Text(
                  'Here’s your financial overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: m.isCompactHeight ? m.text(11) : m.text(13),
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: m.spacing(10)),
          _NotificationButton(m: m, size: m.size(controlSize)),
        ],
      ),
    );
  }
}

// ================================================================
// BALANCE OVERVIEW
// ================================================================

class _BalanceOverview extends StatelessWidget {
  const _BalanceOverview({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    final accountsBox = Hive.box<Account>('accounts');
    final transactionsBox = Hive.box<Transaction>('transactions');
    final allocationsBox = Hive.box<Allocation>(AllocationService.boxName);

    return ValueListenableBuilder<Box<Account>>(
      valueListenable: accountsBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: transactionsBox.listenable(),
          builder: (context, _, __) {
            return ValueListenableBuilder<Box<Allocation>>(
              valueListenable: allocationsBox.listenable(),
              builder: (context, _, __) {
                final data = _GroupFinancialData.fromCurrentAccounts(
                  AccountService().getAllActiveAccounts(),
                  BalanceService(),
                  AllocationService(),
                );

                return Container(
                  margin: EdgeInsets.fromLTRB(
                    m.spacing(20),
                    m.h(6),
                    m.spacing(20),
                    m.spacing(20),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(m.radius.xl),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF062D36),
                        Color(0xFF081722),
                        Color(0xFF07131D),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF0B4D57),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00DDB0).withValues(alpha: 0.08),
                        blurRadius: m.size(28),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: m.isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: m.isDesktop ? 2 : 3,
                              child: Column(
                                children: [
                                  _BalanceHeader(
                                    m: m,
                                    totalBalance: data.totalBalance,
                                  ),
                                  _PeriodAndFilter(m: m),
                                  _BalanceChart(
                                    values: data.chartValues,
                                    labels: data.chartLabels,
                                    latestValue: data.latestBalance,
                                    latestDate: data.latestDate,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: m.isDesktop ? 3 : 2,
                              child: _MetricsColumn(
                                m: m,
                                available: data.available,
                                reserved: data.reserved,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _BalanceHeader(
                              m: m,
                              totalBalance: data.totalBalance,
                            ),
                            _PeriodAndFilter(m: m),
                            _BalanceChart(
                              values: data.chartValues,
                              labels: data.chartLabels,
                              latestValue: data.latestBalance,
                              latestDate: data.latestDate,
                            ),
                            _MetricsRow(
                              m: m,
                              available: data.available,
                              reserved: data.reserved,
                            ),
                          ],
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupFinancialData {
  const _GroupFinancialData({
    required this.totalBalance,
    required this.available,
    required this.reserved,
    required this.chartValues,
    required this.chartLabels,
    required this.latestBalance,
    required this.latestDate,
  });

  final double totalBalance;
  final double available;
  final double reserved;
  final List<double> chartValues;
  final List<String> chartLabels;
  final double latestBalance;
  final DateTime latestDate;

  factory _GroupFinancialData.fromCurrentAccounts(
    List<Account> accounts,
    BalanceService balanceService,
    AllocationService allocationService,
  ) {
    // IMPORTANT: This screen is a LIQUIDITY dashboard.
    // Only accounts explicitly classified as AccountGroup.liquidity
    // participate in balance, chart, available, and reserved totals.
    final activeAccounts = accounts
        .where((account) => !account.isArchived)
        .where((account) => account.group == AccountGroup.liquidity)
        .where((account) => account.currency.toUpperCase() == 'EGP')
        .toList();

    double totalBalance = 0;
    for (final account in activeAccounts) {
      totalBalance += balanceService.getBalance(account.id);
    }

    // Reserved must be calculated from the SAME liquidity scope.
    // Do not use getTotalReservedMoney(), because that is global and can
    // include allocations belonging to non-liquidity accounts.
    double reserved = 0;
    for (final account in activeAccounts) {
      reserved += allocationService.getAllocatedAmountForAccount(account.id);
    }
    final available = totalBalance - reserved;

    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];

    for (int offset = 5; offset >= 0; offset--) {
      final monthDate = DateTime(now.year, now.month - offset + 1, 0);
      final snapshotDate = offset == 0 ? now : monthDate;

      double monthBalance = 0;
      for (final account in activeAccounts) {
        monthBalance += balanceService.getBalanceAtDate(
          account.id,
          snapshotDate,
        );
      }

      values.add(monthBalance);
      labels.add(_monthLabel(snapshotDate.month));
    }

    return _GroupFinancialData(
      totalBalance: totalBalance,
      available: available,
      reserved: reserved,
      chartValues: values,
      chartLabels: labels,
      latestBalance: values.isEmpty ? totalBalance : values.last,
      latestDate: now,
    );
  }

  static String _monthLabel(int month) {
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
}

// ================================================================
// BALANCE HEADER
// ================================================================

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.m, required this.totalBalance});

  final ResponsiveMetrics m;
  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(18),
        m.isCompactHeight ? m.spacing(14) : m.spacing(17),
        m.spacing(16),
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Color(0xFF39E4C1),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: m.h(5)),
                Text(
                  _formatMoney(totalBalance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.isCompactHeight ? m.text(38) : m.text(50),
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                SizedBox(height: m.h(4)),
                const Text(
                  'EGP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _BalanceVisibilityButton(m: m),
        ],
      ),
    );
  }
}

// ================================================================
// METRICS
// ================================================================

class _MetricsColumn extends StatelessWidget {
  const _MetricsColumn({
    required this.m,
    required this.available,
    required this.reserved,
  });

  final ResponsiveMetrics m;
  final double available;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(10),
        m.spacing(20),
        m.spacing(18),
        m.spacing(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceMetric(
              title: 'Available',
              amount: _formatMoney(available),
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFF3EE8B8),
              m: m,
            ),
          ),
          SizedBox(width: m.spacing(12)),
          Expanded(
            child: _BalanceMetric(
              title: 'Reserved',
              amount: _formatMoney(reserved),
              icon: Icons.arrow_forward_rounded,
              color: const Color(0xFFFFA928),
              m: m,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.m,
    required this.available,
    required this.reserved,
  });

  final ResponsiveMetrics m;
  final double available;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(18),
        0,
        m.spacing(18),
        m.spacing(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceMetric(
              title: 'Available',
              amount: _formatMoney(available),
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFF3EE8B8),
              m: m,
            ),
          ),
          SizedBox(width: m.spacing(12)),
          Expanded(
            child: _BalanceMetric(
              title: 'Reserved',
              amount: _formatMoney(reserved),
              icon: Icons.arrow_forward_rounded,
              color: const Color(0xFFFFA928),
              m: m,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
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

// ================================================================
// PERIOD & FILTER
// ================================================================

class _PeriodAndFilter extends StatelessWidget {
  const _PeriodAndFilter({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.spacing(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AccountFilter(m: m),
          _PeriodSelector(m: m),
        ],
      ),
    );
  }
}

// ================================================================
// ================================================================
// ACCOUNTS HEADER
// ================================================================

class _AccountsHeader extends StatelessWidget {
  const _AccountsHeader({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(26),
        0,
        m.spacing(26),
        m.spacing(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Accounts',
              style: TextStyle(
                color: Colors.white,
                fontSize: m.text(18),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              // هنربطه بـ AddAccountScreen بعدين
            },
            child: Container(
              width: m.size(36),
              height: m.size(36),
              decoration: BoxDecoration(
                color: const Color(0xFF35E0B5).withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF35E0B5).withValues(alpha: 0.22),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: const Color(0xFF35E0B5),
                size: m.size(21),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACCOUNTS LIST
// ================================================================

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    final accountsBox = Hive.box<Account>('accounts');
    final transactionsBox = Hive.box<Transaction>('transactions');
    final allocationsBox = Hive.box<Allocation>(AllocationService.boxName);

    return ValueListenableBuilder<Box<Account>>(
      valueListenable: accountsBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: transactionsBox.listenable(),
          builder: (context, _, __) {
            return ValueListenableBuilder<Box<Allocation>>(
              valueListenable: allocationsBox.listenable(),
              builder: (context, _, __) {
                final balanceService = BalanceService();
                final allocationService = AllocationService();

                final accounts = AccountService()
                    .getAllActiveAccounts()
                    .where((account) => account.group == AccountGroup.liquidity)
                    .where((account) => account.currency.toUpperCase() == 'EGP')
                    .map(
                      (account) => _accountDataFromModel(
                        account,
                        balanceService,
                        allocationService,
                      ),
                    )
                    .toList();

                if (m.isDesktop) {
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: m.spacing(12),
                      mainAxisSpacing: m.spacing(12),
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _AccountCard(data: accounts[index], m: m),
                      childCount: accounts.length,
                    ),
                  );
                }

                if (m.isTablet) {
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: m.spacing(12),
                      mainAxisSpacing: m.spacing(12),
                      childAspectRatio: 1.3,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _AccountCard(data: accounts[index], m: m),
                      childCount: accounts.length,
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _AccountCard(data: accounts[index], m: m),
                    childCount: accounts.length,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

_AccountData _accountDataFromModel(
  Account account,
  BalanceService balanceService,
  AllocationService allocationService,
) {
  final balance = balanceService.getBalance(account.id);
  final reserved = allocationService.getAllocatedAmountForAccount(account.id);
  final available = balance - reserved;
  final isLiability = account.nature.name == 'liability';

  return _AccountData(
    icon: _iconForAccountType(account.type, isLiability),
    iconColor: _colorForAccountType(account.type, isLiability),
    iconBackground: _colorForAccountType(
      account.type,
      isLiability,
    ).withValues(alpha: 0.18),
    name: account.name,
    subtitle: _prettyAccountType(account.type),
    balance: _formatMoney(balance),
    balanceSuffix: account.currency,
    available: isLiability
        ? 'Outstanding ${_formatMoney(balance.abs())} ${account.currency}'
        : 'Available ${_formatMoney(available)} ${account.currency}',
    showAvailable: false,
    isLiability: isLiability,
  );
}

String _prettyAccountType(String type) {
  final spaced = type.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  return spaced.isEmpty
      ? type
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

IconData _iconForAccountType(String type, bool isLiability) {
  if (isLiability) {
    if (type == 'creditCard') return Icons.credit_card_rounded;
    if (type == 'loan') return Icons.account_balance_rounded;
    if (type == 'installment') return Icons.calendar_month_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  switch (type) {
    case 'bank':
      return Icons.account_balance_rounded;
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    case 'investment':
    case 'stocks':
    case 'gold':
    case 'certificates':
      return Icons.bar_chart_rounded;
    case 'cash':
      return Icons.payments_rounded;
    default:
      return Icons.account_balance_wallet_rounded;
  }
}

Color _colorForAccountType(String type, bool isLiability) {
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

class _AccountData {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String name;
  final String subtitle;
  final String balance;
  final String balanceSuffix;
  final String available;
  final bool showAvailable;
  final String? badge;
  final bool isLiability;

  const _AccountData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.name,
    required this.subtitle,
    required this.balance,
    required this.balanceSuffix,
    required this.available,
    required this.showAvailable,
    this.badge,
    this.isLiability = false,
  });
}

// ================================================================
// UI COMPONENTS
// ================================================================

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.data, required this.m});

  final _AccountData data;
  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: m.spacing(10)),
      decoration: BoxDecoration(
        color: const Color(0xFF071823),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(
          color: data.iconColor.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(m.radius.lg),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              m.spacing(16),
              m.spacing(15),
              m.spacing(14),
              m.spacing(15),
            ),
            child: Row(
              children: [
                Container(
                  width: m.size(58),
                  height: m.size(58),
                  decoration: BoxDecoration(
                    color: data.iconBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.iconColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    data.icon,
                    color: data.iconColor,
                    size: m.size(29),
                  ),
                ),
                SizedBox(width: m.spacing(15)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: m.text(18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: m.h(3)),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: m.text(13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (data.badge != null) ...[
                        SizedBox(height: m.h(7)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: m.spacing(9),
                            vertical: m.h(3),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00DDB0,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(m.radius.sm),
                          ),
                          child: Text(
                            data.badge!,
                            style: TextStyle(
                              color: const Color(0xFF35E0B5),
                              fontSize: m.text(10),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: m.spacing(10)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: m.text(12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: m.h(2)),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: data.balance,
                            style: TextStyle(
                              color: data.isLiability
                                  ? const Color(0xFFFF5572)
                                  : Colors.white,
                              fontSize: m.text(20),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' ${data.balanceSuffix}',
                            style: TextStyle(
                              color: data.isLiability
                                  ? const Color(0xFFFF5572)
                                  : Colors.white,
                              fontSize: m.text(13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: m.h(4)),
                    Text(
                      data.showAvailable
                          ? 'Available ${data.available}'
                          : data.available,
                      style: TextStyle(
                        color: data.isLiability
                            ? const Color(0xFFFF5572)
                            : const Color(0xFF35E0B5),
                        fontSize: m.text(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: m.spacing(10)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.58),
                  size: m.size(26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.m,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        m.spacing(14),
        m.spacing(12),
        m.spacing(10),
        m.spacing(12),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(m.radius.md),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: m.text(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: m.h(2)),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: amount,
                        style: TextStyle(
                          color: color,
                          fontSize: m.text(20),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' EGP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: m.text(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: m.size(34),
            height: m.size(34),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: m.size(18)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.m,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    final height = m.isDesktop ? m.h(130) : m.h(118);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF071722),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.045)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(m.radius.lg),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: m.spacing(5),
              vertical: m.h(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: m.isDesktop ? m.size(56) : m.size(50),
                  height: m.isDesktop ? m.size(56) : m.size(50),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: m.isDesktop ? m.size(30) : m.size(28),
                  ),
                ),
                SizedBox(height: m.h(9)),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: m.h(3)),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.43),
                    fontSize: m.text(9.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: m.spacing(14),
        vertical: m.h(9),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C28),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '6 Months',
            style: TextStyle(
              color: Colors.white,
              fontSize: m.text(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: m.spacing(7)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: m.size(18),
          ),
        ],
      ),
    );
  }
}

class _AccountFilter extends StatelessWidget {
  const _AccountFilter({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: m.spacing(14),
        vertical: m.h(9),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A202A),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: const Color(0xFF1D5360)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_rounded,
            color: const Color(0xFF35E0B5),
            size: m.size(17),
          ),
          SizedBox(width: m.spacing(8)),
          Text(
            'Liquidity Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: m.text(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: m.spacing(7)),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: m.size(17),
          ),
        ],
      ),
    );
  }
}

class _BalanceVisibilityButton extends StatelessWidget {
  const _BalanceVisibilityButton({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: m.size(55),
      height: m.size(55),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Icon(
        Icons.visibility_outlined,
        color: Colors.white,
        size: m.size(25),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.size,
    required this.m,
  });

  final IconData icon;
  final double size;
  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A26),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.m, required this.size});

  final ResponsiveMetrics m;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A26),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: size * 0.50,
          ),
        ),
        Positioned(
          right: m.spacing(1),
          top: m.h(1),
          child: Container(
            width: m.size(9),
            height: m.size(9),
            decoration: BoxDecoration(
              color: const Color(0xFF35E0B5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF020D16), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// STATIC BALANCE CHART
// ================================================================

class _BalanceChart extends StatelessWidget {
  const _BalanceChart({
    required this.values,
    required this.labels,
    required this.latestValue,
    required this.latestDate,
  });

  final List<double> values;
  final List<String> labels;
  final double latestValue;
  final DateTime latestDate;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return SizedBox(
      width: double.infinity,
      height: m.isCompactHeight ? m.h(190) : m.h(225),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minValue = values.isEmpty
              ? 0.0
              : values.reduce((a, b) => a < b ? a : b);
          final maxValue = values.isEmpty
              ? 1.0
              : values.reduce((a, b) => a > b ? a : b);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BalanceChartPainter(
                    values: values,
                    minValue: minValue,
                    maxValue: maxValue,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: m.h(18),
                bottom: m.h(26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _chartScaleLabels(minValue, maxValue, m),
                ),
              ),
              Positioned(
                right: m.spacing(34),
                top: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.spacing(13),
                    vertical: m.h(9),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF062D35),
                    borderRadius: BorderRadius.circular(m.radius.md),
                    border: Border.all(
                      color: const Color(0xFF14DDB1).withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E1B3).withValues(alpha: 0.08),
                        blurRadius: m.size(15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatMoney(latestValue)} EGP',
                        style: const TextStyle(
                          color: Color(0xFF35E0B5),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_GroupFinancialData._monthLabel(latestDate.month)} ${latestDate.day}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: m.spacing(8),
                right: m.spacing(42),
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [for (final label in labels) _ChartLabel(label)],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _chartScaleLabels(
    double minValue,
    double maxValue,
    ResponsiveMetrics m,
  ) {
    final range = (maxValue - minValue).abs();
    final safeRange = range < 1 ? 1.0 : range;

    return List.generate(5, (index) {
      final value = maxValue - (safeRange * index / 4);
      return _ChartLabel(_formatCompact(value));
    });
  }
}

String _formatCompact(double value) {
  final absolute = value.abs();

  String formatted;
  if (absolute >= 1000000) {
    formatted = '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (absolute >= 1000) {
    formatted = '${(value / 1000).toStringAsFixed(1)}k';
  } else {
    formatted = value.round().toString();
  }

  return formatted;
}

class _ChartLabel extends StatelessWidget {
  const _ChartLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: m.text(10),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ================================================================
// CHART PAINTER
// ================================================================

class _BalanceChartPainter extends CustomPainter {
  const _BalanceChartPainter({
    required this.values,
    required this.minValue,
    required this.maxValue,
  });

  final List<double> values;
  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - 48;
    final chartHeight = size.height - 32;

    if (values.isEmpty || chartWidth <= 0 || chartHeight <= 0) return;

    final range = (maxValue - minValue).abs() < 1 ? 1.0 : (maxValue - minValue);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : chartWidth * i / (values.length - 1);
      final normalized = (values[i] - minValue) / range;
      final y = chartHeight * (1 - normalized.clamp(0.0, 1.0));
      points.add(Offset(x, y));
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(chartWidth, chartHeight),
      gridPaint,
    );

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) * 0.45,
        current.dy,
      );
      final controlPoint2 = Offset(
        next.dx - (next.dx - current.dx) * 0.45,
        next.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(chartWidth, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x5535E0B5), Color(0x1035E0B5), Color(0x0035E0B5)],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF35E0B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      final glowPaint = Paint()
        ..color = const Color(0xFF35E0B5).withValues(alpha: 0.16);
      canvas.drawCircle(point, 8, glowPaint);

      final pointPaint = Paint()..color = const Color(0xFF35E0B5);
      canvas.drawCircle(point, 3.5, pointPaint);
    }

    final selectedPoint = points.last;

    final selectedGlow = Paint()
      ..color = const Color(0xFF35E0B5).withValues(alpha: 0.18);
    canvas.drawCircle(selectedPoint, 13, selectedGlow);

    final selectedRing = Paint()
      ..color = const Color(0xFF35E0B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(selectedPoint, 6, selectedRing);

    final selectedDot = Paint()..color = const Color(0xFF35E0B5);
    canvas.drawCircle(selectedPoint, 3, selectedDot);

    final guidePaint = Paint()
      ..color = const Color(0xFF35E0B5).withValues(alpha: 0.22)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(selectedPoint.dx, selectedPoint.dy),
      Offset(selectedPoint.dx, chartHeight),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }
}
