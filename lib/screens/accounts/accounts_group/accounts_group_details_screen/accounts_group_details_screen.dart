// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../models/account.dart';
import '../../../../models/transaction.dart';
import '../../../../core/planning/infrastructure/persistence/hive_allocation_record.dart';
import '../../../../core/planning/services/available_balance_projection_service.dart';
import '../../../../theme/responsive_metrics.dart';
import 'accounts_group_details_logic.dart';

class AccountsGroupDetailsScreen extends StatefulWidget {
  const AccountsGroupDetailsScreen({super.key});

  @override
  State<AccountsGroupDetailsScreen> createState() =>
      _AccountsGroupDetailsScreenState();
}

class _AccountsGroupDetailsScreenState
    extends State<AccountsGroupDetailsScreen> {
  String _selectedCurrency = 'EGP';
  int _selectedPeriodMonths = 6;
  bool _showBalances = true;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020D16),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                m: m,
                showBalances: _showBalances,
                onToggleBalanceVisibility: () {
                  setState(() => _showBalances = !_showBalances);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _BalanceOverview(
                m: m,
                selectedCurrency: _selectedCurrency,
                selectedPeriodMonths: _selectedPeriodMonths,
                showBalances: _showBalances,
                onCurrencyChanged: (value) {
                  setState(() => _selectedCurrency = value);
                },
                onPeriodChanged: (value) {
                  setState(() => _selectedPeriodMonths = value);
                },
              ),
            ),
            SliverToBoxAdapter(child: _AccountsHeader(m: m)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                m.spacing(20),
                0,
                m.spacing(20),
                m.spacing(24),
              ),
              sliver: _AccountsList(
                m: m,
                selectedCurrency: _selectedCurrency,
                showBalances: _showBalances,
              ),
            ),
            SliverToBoxAdapter(child: _AddAccountButton(m: m)),
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
  const _Header({
    required this.m,
    required this.showBalances,
    required this.onToggleBalanceVisibility,
  });

  final ResponsiveMetrics m;
  final bool showBalances;
  final VoidCallback onToggleBalanceVisibility;

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
          SizedBox(width: m.spacing(8)),
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
                SizedBox(height: m.h(1)),
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
                SizedBox(height: m.h(2)),
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
          SizedBox(width: m.spacing(8)),
          _NotificationButton(m: m, size: m.size(controlSize)),
          SizedBox(width: m.spacing(7)),
          _BalanceVisibilityButton(
            m: m,
            size: m.size(controlSize),
            visible: showBalances,
            onTap: onToggleBalanceVisibility,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BALANCE OVERVIEW
// ================================================================

class _BalanceOverview extends StatelessWidget {
  const _BalanceOverview({
    required this.m,
    required this.selectedCurrency,
    required this.selectedPeriodMonths,
    required this.showBalances,
    required this.onCurrencyChanged,
    required this.onPeriodChanged,
  });

  final ResponsiveMetrics m;
  final String selectedCurrency;
  final int selectedPeriodMonths;
  final bool showBalances;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final accountsBox = Hive.box<Account>('accounts');
    final transactionsBox = Hive.box<Transaction>('transactions');
    final planningAllocationsBox = Hive.box<HiveAllocationRecord>(
      'planning_allocations',
    );

    return ValueListenableBuilder<Box<Account>>(
      valueListenable: accountsBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: transactionsBox.listenable(),
          builder: (context, _, __) {
            return ValueListenableBuilder<Box<HiveAllocationRecord>>(
              valueListenable: planningAllocationsBox.listenable(),
              builder: (context, _, __) {
                final projectionService = context
                    .read<AvailableBalanceProjectionService>();

                return FutureBuilder<GroupFinancialData>(
                  future: AccountsGroupDetailsLogic.buildFinancialData(
                    currency: selectedCurrency,
                    periodMonths: selectedPeriodMonths,
                    projectionService: projectionService,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 260,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final data = snapshot.data!;

                    return Container(
                      margin: EdgeInsets.fromLTRB(
                        m.spacing(18),
                        m.h(4),
                        m.spacing(18),
                        m.spacing(12),
                      ),
                      padding: EdgeInsets.all(m.spacing(14)),
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
                            color: const Color(
                              0xFF00DDB0,
                            ).withValues(alpha: 0.08),
                            blurRadius: m.size(28),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BalanceHeader(
                            m: m,
                            totalBalance: data.totalBalance,
                            selectedCurrency: selectedCurrency,
                            selectedPeriodMonths: selectedPeriodMonths,
                            currencies: data.availableCurrencies,
                            showBalance: showBalances,
                            totalBreakdown: data.totalBreakdown,
                            onCurrencyChanged: onCurrencyChanged,
                            onPeriodChanged: onPeriodChanged,
                          ),
                          SizedBox(height: m.h(7)),
                          _CurrencyComposition(
                            m: m,
                            items: data.totalBreakdown,
                            showBalance: showBalances,
                          ),
                          SizedBox(height: m.h(7)),
                          SizedBox(
                            height: m.isCompactHeight ? m.h(146) : m.h(164),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _BalanceChart(
                                    values: data.chartValues,
                                    labels: data.chartLabels,
                                    dates: data.chartDates,
                                    latestValue: data.latestBalance,
                                    latestDate: data.latestDate,
                                    currency: selectedCurrency,
                                    showBalance: showBalances,
                                    periodMonths: selectedPeriodMonths,
                                  ),
                                ),
                                SizedBox(width: m.spacing(10)),
                                Expanded(
                                  flex: 4,
                                  child: _MetricsColumn(
                                    m: m,
                                    available: data.available,
                                    reserved: data.reserved,
                                    availableBreakdown: data.availableBreakdown,
                                    reservedBreakdown: data.reservedBreakdown,
                                    displayCurrency: selectedCurrency,
                                    showBalances: showBalances,
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}

// ================================================================
// BALANCE HEADER
// ================================================================

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.m,
    required this.totalBalance,
    required this.selectedCurrency,
    required this.selectedPeriodMonths,
    required this.currencies,
    required this.showBalance,
    required this.totalBreakdown,
    required this.onCurrencyChanged,
    required this.onPeriodChanged,
  });

  final ResponsiveMetrics m;
  final double totalBalance;
  final String selectedCurrency;
  final int selectedPeriodMonths;
  final List<String> currencies;
  final bool showBalance;
  final List<CurrencyAmount> totalBreakdown;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.spacing(2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: const Color(0xFF39E4C1),
                        fontSize: m.isCompactHeight ? m.text(13) : m.text(14),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: m.h(2)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            showBalance ? formatMoney(totalBalance) : '••••',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: m.isCompactHeight
                                  ? m.text(27)
                                  : m.text(31),
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                        SizedBox(width: m.spacing(4)),
                        Text(
                          showBalance ? selectedCurrency : '•••',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: m.isCompactHeight
                                ? m.text(12)
                                : m.text(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: m.spacing(8)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CompactFilter(
                    label: selectedCurrency,
                    icon: Icons.currency_exchange_rounded,
                    m: m,
                    onTap: () => _showCurrencyPicker(context),
                  ),
                  SizedBox(width: m.spacing(5)),
                  _CompactFilter(
                    label: '$selectedPeriodMonths Months',
                    icon: Icons.calendar_month_rounded,
                    m: m,
                    onTap: () => _showPeriodPicker(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF071823),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: m.h(12)),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  m.spacing(20),
                  m.h(4),
                  m.spacing(20),
                  m.h(8),
                ),
                child: const Text(
                  'Display currency',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final currency in currencies)
                ListTile(
                  title: Text(
                    currency,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: currency == selectedCurrency
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF35E0B5),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onCurrencyChanged(currency);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPeriodPicker(BuildContext context) {
    const periods = [3, 6, 12];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF071823),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: m.h(12)),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  m.spacing(20),
                  m.h(4),
                  m.spacing(20),
                  m.h(8),
                ),
                child: const Text(
                  'Period',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final months in periods)
                ListTile(
                  title: Text(
                    '$months Months',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: months == selectedPeriodMonths
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF35E0B5),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onPeriodChanged(months);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyComposition extends StatelessWidget {
  const _CurrencyComposition({
    required this.m,
    required this.items,
    required this.showBalance,
  });

  final ResponsiveMetrics m;
  final List<CurrencyAmount> items;
  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: m.spacing(8), vertical: m.h(5)),
      decoration: BoxDecoration(
        color: const Color(0xFF061923).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(m.radius.md),
        border: Border.all(
          color: const Color(0xFF35E0B5).withValues(alpha: 0.12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.spacing(6)),
                  child: Text(
                    '·',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: m.text(10),
                    ),
                  ),
                ),
              Text(
                showBalance
                    ? '${formatMoney(items[i].originalAmount)} ${items[i].currency}'
                    : '•••• ${items[i].currency}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: m.text(8.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactFilter extends StatelessWidget {
  const _CompactFilter({
    required this.label,
    required this.icon,
    required this.m,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final ResponsiveMetrics m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(m.radius.lg),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: m.spacing(8),
            vertical: m.h(6),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1C28),
            borderRadius: BorderRadius.circular(m.radius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: m.size(13)),
              SizedBox(width: m.spacing(4)),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: m.text(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: m.spacing(2)),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
                size: m.size(14),
              ),
            ],
          ),
        ),
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
    required this.availableBreakdown,
    required this.reservedBreakdown,
    required this.displayCurrency,
    required this.showBalances,
  });

  final ResponsiveMetrics m;
  final double available;
  final double reserved;
  final List<CurrencyAmount> availableBreakdown;
  final List<CurrencyAmount> reservedBreakdown;
  final String displayCurrency;
  final bool showBalances;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _BalanceMetric(
            title: 'Available',
            description: 'Available to spend',
            amount: showBalances ? formatMoney(available) : '••••',
            breakdown: availableBreakdown,
            color: const Color(0xFFFFA928),
            displayCurrency: displayCurrency,
            m: m,
          ),
        ),
        SizedBox(height: m.spacing(7)),
        Expanded(
          child: _BalanceMetric(
            title: 'Reserved',
            description: 'Your reserved money',
            amount: showBalances ? formatMoney(reserved) : '••••',
            breakdown: reservedBreakdown,
            color: const Color(0xFF35E0B5),
            displayCurrency: displayCurrency,
            m: m,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// PERIOD & FILTER
// ================================================================

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
        m.spacing(22),
        0,
        m.spacing(22),
        m.spacing(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Accounts',
              style: TextStyle(
                color: Colors.white,
                fontSize: m.text(17),
                fontWeight: FontWeight.w800,
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
  const _AccountsList({
    required this.m,
    required this.selectedCurrency,
    required this.showBalances,
  });

  final ResponsiveMetrics m;
  final String selectedCurrency;
  final bool showBalances;

  @override
  Widget build(BuildContext context) {
    final accountsBox = Hive.box<Account>('accounts');
    final transactionsBox = Hive.box<Transaction>('transactions');
    final planningAllocationsBox = Hive.box<HiveAllocationRecord>(
      'planning_allocations',
    );

    return ValueListenableBuilder<Box<Account>>(
      valueListenable: accountsBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: transactionsBox.listenable(),
          builder: (context, _, __) {
            return ValueListenableBuilder<Box<HiveAllocationRecord>>(
              valueListenable: planningAllocationsBox.listenable(),
              builder: (context, _, __) {
                final projectionService = context
                    .read<AvailableBalanceProjectionService>();

                return FutureBuilder<List<AccountData>>(
                  future: AccountsGroupDetailsLogic.buildAccountList(
                    projectionService: projectionService,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final accounts = snapshot.data!;

                    if (m.isDesktop) {
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: m.spacing(12),
                          mainAxisSpacing: m.spacing(12),
                          childAspectRatio: 1.2,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _AccountCard(
                            data: accounts[index],
                            m: m,
                            showBalances: showBalances,
                          ),
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
                          (context, index) => _AccountCard(
                            data: accounts[index],
                            m: m,
                            showBalances: showBalances,
                          ),
                          childCount: accounts.length,
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AccountCard(
                          data: accounts[index],
                          m: m,
                          showBalances: showBalances,
                        ),
                        childCount: accounts.length,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(20),
        m.spacing(2),
        m.spacing(20),
        m.spacing(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to AddAccountScreen.
          },
          borderRadius: BorderRadius.circular(m.radius.lg),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: m.spacing(11)),
            decoration: BoxDecoration(
              color: const Color(0xFF35E0B5).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(m.radius.lg),
              border: Border.all(
                color: const Color(0xFF35E0B5).withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: const Color(0xFF35E0B5),
                  size: m.size(19),
                ),
                SizedBox(width: m.spacing(6)),
                Text(
                  'Add account',
                  style: TextStyle(
                    color: const Color(0xFF35E0B5),
                    fontSize: m.text(13),
                    fontWeight: FontWeight.w700,
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

// ================================================================
// UI COMPONENTS
// ================================================================

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.data,
    required this.m,
    required this.showBalances,
  });

  final AccountData data;
  final ResponsiveMetrics m;
  final bool showBalances;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: m.spacing(5)),
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
              m.spacing(10),
              m.spacing(8),
              m.spacing(9),
              m.spacing(8),
            ),
            child: Row(
              children: [
                Container(
                  width: m.size(50),
                  height: m.size(50),
                  decoration: BoxDecoration(
                    color: data.iconBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.iconColor.withValues(alpha: 0.12),
                    ),
                  ),
                  padding: EdgeInsets.all(m.size(8)),
                  child: SvgPicture.asset(
                    data.iconAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_balance_wallet_rounded,
                      color: data.iconColor,
                      size: m.size(24),
                    ),
                  ),
                ),
                SizedBox(width: m.spacing(8)),
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
                          fontSize: m.text(16),
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
                          fontSize: m.text(10),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (data.badge != null) ...[
                        SizedBox(height: m.h(4)),
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
                              fontSize: m.text(9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: m.spacing(7)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: m.text(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: m.h(2)),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: showBalances ? data.balance : '••••',
                            style: TextStyle(
                              color: data.isLiability
                                  ? const Color(0xFFFF5572)
                                  : Colors.white,
                              fontSize: m.text(16),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: showBalances
                                ? ' ${data.balanceSuffix}'
                                : ' •••',
                            style: TextStyle(
                              color: data.isLiability
                                  ? const Color(0xFFFF5572)
                                  : Colors.white,
                              fontSize: m.text(11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: m.h(3)),
                    Text(
                      showBalances
                          ? (data.showAvailable
                                ? 'Available ${data.available}'
                                : data.available)
                          : 'Available ••••',
                      style: TextStyle(
                        color: data.isLiability
                            ? const Color(0xFFFF5572)
                            : const Color(0xFFFFA928),
                        fontSize: m.text(10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!data.isLiability) ...[
                      SizedBox(height: m.h(2)),
                      Text(
                        showBalances ? data.reserved : 'Reserved ••••',
                        style: TextStyle(
                          color: const Color(0xFF35E0B5),
                          fontSize: m.text(9.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(width: m.spacing(7)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.58),
                  size: m.size(18),
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
    required this.description,
    required this.amount,
    required this.breakdown,
    required this.color,
    required this.displayCurrency,
    required this.m,
  });

  final String title;
  final String description;
  final String amount;
  final List<CurrencyAmount> breakdown;
  final Color color;
  final String displayCurrency;
  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    final visibleBreakdown = breakdown
        .where((item) => item.originalAmount.abs() > 0.0001)
        .take(3)
        .toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: m.spacing(7),
        vertical: m.spacing(6),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(m.radius.md),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: m.text(10),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (title == 'Reserved') ...[
                SizedBox(width: m.spacing(3)),
                Icon(Icons.lock_rounded, color: color, size: m.size(11)),
              ],
            ],
          ),
          SizedBox(height: m.h(1)),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: m.text(7.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: m.h(1)),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: amount,
                  style: TextStyle(
                    color: color,
                    fontSize: m.text(14),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $displayCurrency',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(8.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (visibleBreakdown.isNotEmpty) ...[
            SizedBox(height: m.h(2)),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: m.spacing(4),
              runSpacing: m.h(1),
              children: [
                for (final item in visibleBreakdown)
                  Text(
                    '${formatMoney(item.originalAmount)} ${item.currency}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: m.text(7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceVisibilityButton extends StatelessWidget {
  const _BalanceVisibilityButton({
    required this.m,
    required this.size,
    required this.visible,
    required this.onTap,
  });

  final ResponsiveMetrics m;
  final double size;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A26),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white,
            size: size * 0.48,
          ),
        ),
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
// INTERACTIVE BALANCE CHART
// ================================================================

class _BalanceChart extends StatefulWidget {
  const _BalanceChart({
    required this.values,
    required this.labels,
    required this.dates,
    required this.latestValue,
    required this.latestDate,
    required this.currency,
    required this.showBalance,
    required this.periodMonths,
  });

  final List<double> values;
  final List<String> labels;
  final List<DateTime> dates;
  final double latestValue;
  final DateTime latestDate;
  final String currency;
  final bool showBalance;
  final int periodMonths;

  @override
  State<_BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<_BalanceChart> {
  int _selectedIndex = -1;

  int _indexFromLocalX(double x, double width) {
    if (widget.values.length <= 1) return 0;

    final chartWidth = width - 48;
    if (chartWidth <= 0) return 0;

    final normalized = (x / chartWidth).clamp(0.0, 1.0);
    return (normalized * (widget.values.length - 1))
        .round()
        .clamp(0, widget.values.length - 1)
        .toInt();
  }

  void _selectAt(Offset position, double width) {
    if (widget.values.isEmpty) return;

    final index = _indexFromLocalX(position.dx, width);
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final values = widget.values;
    final selectedIndex = _selectedIndex < 0
        ? (values.isEmpty ? -1 : values.length - 1)
        : _selectedIndex;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF061923).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      padding: EdgeInsets.fromLTRB(m.spacing(7), m.h(4), m.spacing(4), m.h(3)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minValue = values.isEmpty
              ? 0.0
              : values.reduce((a, b) => a < b ? a : b);
          final maxValue = values.isEmpty
              ? 1.0
              : values.reduce((a, b) => a > b ? a : b);

          final chartWidth = constraints.maxWidth - 48;
          final selectedX = values.isEmpty
              ? 0.0
              : (values.length == 1
                    ? 0.0
                    : chartWidth * selectedIndex / (values.length - 1));

          final selectedValue = values.isEmpty
              ? widget.latestValue
              : values[selectedIndex];
          final selectedDate = widget.dates.isEmpty
              ? widget.latestDate
              : widget.dates[selectedIndex];

          const tooltipWidth = 96.0;
          const tooltipHeight = 48.0;

          // Keep the tooltip away from the selected curve point. Prefer
          // above the point, then below it, and finally the opposite side.
          final selectedNormalizedY =
              values.isEmpty || (maxValue - minValue).abs() < 1
              ? 0.5
              : 1 -
                    ((selectedValue - minValue) / (maxValue - minValue)).clamp(
                      0.0,
                      1.0,
                    );

          final chartHeight = constraints.maxHeight - 24;
          final selectedY = chartHeight * selectedNormalizedY;

          double tooltipLeft = selectedX - tooltipWidth / 2;
          if (selectedX < tooltipWidth * 0.85) {
            tooltipLeft = selectedX + 10;
          } else if (selectedX > chartWidth - tooltipWidth * 0.85) {
            tooltipLeft = selectedX - tooltipWidth - 10;
          }
          tooltipLeft = tooltipLeft
              .clamp(
                2.0,
                (constraints.maxWidth - tooltipWidth - 2).clamp(
                  2.0,
                  double.infinity,
                ),
              )
              .toDouble();

          final pointGap = m.h(16);
          final topCandidate = selectedY - tooltipHeight - pointGap;
          final bottomCandidate = selectedY + pointGap;

          // Prefer a position that does not cover the selected point.
          final maxTop = constraints.maxHeight - tooltipHeight - 2;
          double tooltipTop;
          if (topCandidate >= 2) {
            tooltipTop = topCandidate;
          } else if (bottomCandidate <= maxTop) {
            tooltipTop = bottomCandidate;
          } else {
            tooltipTop = selectedY < constraints.maxHeight / 2 ? maxTop : 2;
          }
          tooltipTop = tooltipTop.clamp(2.0, maxTop).toDouble();

          final visibleLabels = _visibleChartLabels(widget.labels);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                _selectAt(details.localPosition, constraints.maxWidth),
            onHorizontalDragUpdate: (details) =>
                _selectAt(details.localPosition, constraints.maxWidth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BalanceChartPainter(
                      values: values,
                      minValue: minValue,
                      maxValue: maxValue,
                      selectedIndex: selectedIndex,
                    ),
                  ),
                ),

                // Tooltip moves to a clear side of the selected point.
                Positioned(
                  left: tooltipLeft,
                  top: tooltipTop,
                  child: IgnorePointer(
                    child: Container(
                      width: tooltipWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: m.spacing(6),
                        vertical: m.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF062D35),
                        borderRadius: BorderRadius.circular(m.radius.md),
                        border: Border.all(
                          color: const Color(
                            0xFF14DDB1,
                          ).withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.showBalance
                                ? '${formatMoney(selectedValue)} ${widget.currency}'
                                : '•••• ${widget.currency}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF35E0B5),
                              fontSize: m.text(10),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: m.h(1)),
                          Text(
                            '${monthLabel(selectedDate.month)} ${selectedDate.day}',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: m.text(8.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 0,
                  top: m.h(2),
                  bottom: m.h(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _chartScaleLabels(minValue, maxValue, m),
                  ),
                ),

                Positioned(
                  left: m.spacing(4),
                  right: m.spacing(28),
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final label in visibleLabels) _ChartLabel(label),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _visibleChartLabels(List<String> labels) {
    if (labels.isEmpty) return const [];

    final step = switch (widget.periodMonths) {
      12 => 3,
      6 => 2,
      _ => 2,
    };

    final visible = <String>[];
    for (int i = 0; i < labels.length; i += step) {
      visible.add(labels[i]);
    }

    // Keep the last month visible when it was skipped by the step.
    if (visible.last != labels.last) {
      visible.add(labels.last);
    }

    return visible;
  }

  List<Widget> _chartScaleLabels(
    double minValue,
    double maxValue,
    ResponsiveMetrics m,
  ) {
    final range = (maxValue - minValue).abs();
    final safeRange = range < 1 ? 1.0 : range;

    return List.generate(4, (index) {
      final value = maxValue - (safeRange * index / 3);
      return _ChartLabel(_formatCompact(value));
    });
  }
}

String _formatCompact(double value) {
  final absolute = value.abs();

  if (absolute >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (absolute >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact.abs() >= 10 ? 0 : 1)}k';
  }

  return value.round().toString();
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
    required this.selectedIndex,
  });

  final List<double> values;
  final double minValue;
  final double maxValue;
  final int selectedIndex;

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

    final safeSelectedIndex = selectedIndex.clamp(0, points.length - 1);
    final selectedPoint = points[safeSelectedIndex];

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
        oldDelegate.maxValue != maxValue ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
