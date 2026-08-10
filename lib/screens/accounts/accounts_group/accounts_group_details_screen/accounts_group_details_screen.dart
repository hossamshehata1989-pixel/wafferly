// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_screen.dart

import 'package:flutter/material.dart';
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
          colors: [Color(0xFF062D36), Color(0xFF081722), Color(0xFF07131D)],
        ),
        border: Border.all(color: const Color(0xFF0B4D57), width: 1),
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
                      _BalanceHeader(m: m),
                      _PeriodAndFilter(m: m),
                      const _BalanceChart(),
                    ],
                  ),
                ),
                Expanded(
                  flex: m.isDesktop ? 3 : 2,
                  child: _MetricsColumn(m: m),
                ),
              ],
            )
          : Column(
              children: [
                _BalanceHeader(m: m),
                _PeriodAndFilter(m: m),
                const _BalanceChart(),
                _MetricsRow(m: m),
              ],
            ),
    );
  }
}

// ================================================================
// BALANCE HEADER
// ================================================================

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.m});

  final ResponsiveMetrics m;

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
                  '1,500',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.isCompactHeight ? m.text(38) : m.text(50),
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                SizedBox(height: m.h(4)),
                Text(
                  'EGP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.isCompactHeight ? m.text(18) : m.text(22),
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
// METRICS
// ================================================================

class _MetricsColumn extends StatelessWidget {
  const _MetricsColumn({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(10),
        m.spacing(20),
        m.spacing(18),
        m.spacing(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  title: 'Available',
                  amount: '2,750',
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFF3EE8B8),
                  m: m,
                ),
              ),
              SizedBox(width: m.spacing(12)),
              Expanded(
                child: _BalanceMetric(
                  title: 'Reserved',
                  amount: '1,500',
                  icon: Icons.arrow_forward_rounded,
                  color: const Color(0xFFFFA928),
                  m: m,
                ),
              ),
            ],
          ),
          SizedBox(height: m.spacing(16)),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.m});

  final ResponsiveMetrics m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(18),
        0,
        m.spacing(18),
        m.spacing(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  title: 'Available',
                  amount: '2,750',
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFF3EE8B8),
                  m: m,
                ),
              ),
              SizedBox(width: m.spacing(12)),
              Expanded(
                child: _BalanceMetric(
                  title: 'Reserved',
                  amount: '1,500',
                  icon: Icons.arrow_forward_rounded,
                  color: const Color(0xFFFFA928),
                  m: m,
                ),
              ),
            ],
          ),
          SizedBox(height: m.spacing(16)),
        ],
      ),
    );
  }
}

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
    final accounts = [
      _AccountData(
        icon: Icons.account_balance_rounded,
        iconColor: const Color(0xFF35E0B5),
        iconBackground: const Color(0xFF0C5149),
        name: '2000',
        subtitle: 'Bank Account',
        badge: 'Default',
        balance: '1,500',
        balanceSuffix: 'EGP',
        available: '2,750 EGP',
        showAvailable: true,
        isLiability: false,
      ),
      _AccountData(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFFB17CFF),
        iconBackground: const Color(0xFF342354),
        name: 'Cash Wallet',
        subtitle: 'Wallet',
        balance: '250',
        balanceSuffix: 'EGP',
        available: '250 EGP',
        showAvailable: true,
        isLiability: false,
      ),
      _AccountData(
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFFFFA928),
        iconBackground: const Color(0xFF4A3212),
        name: 'Investments',
        subtitle: 'Investment Account',
        balance: '12,750',
        balanceSuffix: 'EGP',
        available: '12,750 EGP',
        showAvailable: true,
        isLiability: false,
      ),
      _AccountData(
        icon: Icons.credit_card_rounded,
        iconColor: const Color(0xFFFF5572),
        iconBackground: const Color(0xFF4D1724),
        name: 'Credit Card',
        subtitle: 'Liability Account',
        balance: '-3,200',
        balanceSuffix: 'EGP',
        available: 'Outstanding 3,200 EGP',
        showAvailable: false,
        isLiability: true,
      ),
    ];

    if (m.isDesktop) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: m.spacing(12),
          mainAxisSpacing: m.spacing(12),
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AccountCard(data: accounts[index], m: m),
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
          (context, index) => _AccountCard(data: accounts[index], m: m),
          childCount: accounts.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _AccountCard(data: accounts[index], m: m),
        childCount: accounts.length,
      ),
    );
  }
}

// ================================================================
// DATA CLASSES
// ================================================================

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
            'All Accounts',
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
  const _BalanceChart();

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return SizedBox(
      width: double.infinity,
      height: m.isCompactHeight ? m.h(190) : m.h(225),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BalanceChartPainter()),
              ),
              Positioned(
                right: 0,
                top: m.h(18),
                bottom: m.h(26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _ChartLabel('2.0k'),
                    _ChartLabel('1.5k'),
                    _ChartLabel('1.0k'),
                    _ChartLabel('500'),
                    _ChartLabel('0'),
                  ],
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1,500 EGP',
                        style: TextStyle(
                          color: Color(0xFF35E0B5),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Aug 10',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
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
                  children: const [
                    _ChartLabel('Mar'),
                    _ChartLabel('Apr'),
                    _ChartLabel('May'),
                    _ChartLabel('Jun'),
                    _ChartLabel('Jul'),
                    _ChartLabel('Aug'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - 48;
    final chartHeight = size.height - 32;

    final points = <Offset>[
      Offset(0, chartHeight * 0.79),
      Offset(chartWidth * 0.18, chartHeight * 0.55),
      Offset(chartWidth * 0.39, chartHeight * 0.43),
      Offset(chartWidth * 0.58, chartHeight * 0.60),
      Offset(chartWidth * 0.76, chartHeight * 0.38),
      Offset(chartWidth * 0.96, chartHeight * 0.14),
    ];

    // Grid line
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(chartWidth, chartHeight),
      gridPaint,
    );

    // Curve
    final path = Path();

    path.moveTo(points.first.dx, points.first.dy);

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

    // Fill
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

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF35E0B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final glowPaint = Paint()
        ..color = const Color(0xFF35E0B5).withValues(alpha: 0.16);

      canvas.drawCircle(point, 8, glowPaint);

      final pointPaint = Paint()..color = const Color(0xFF35E0B5);

      canvas.drawCircle(point, 3.5, pointPaint);
    }

    // Selected final point
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

    // Vertical guide
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
