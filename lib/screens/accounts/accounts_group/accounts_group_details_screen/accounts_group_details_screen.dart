// lib/screens/accounts/accounts_group/accounts_group_details_screen/accounts_group_details_screen.dart

import 'package:flutter/material.dart';

class AccountsGroupDetailsScreen extends StatelessWidget {
  const AccountsGroupDetailsScreen({super.key});

  // ============================================================
  // UX ONLY
  // Static preview data — NO business logic.
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020D16),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),

            SliverToBoxAdapter(child: _buildBalanceOverview()),

            SliverToBoxAdapter(child: _buildQuickActions()),

            SliverToBoxAdapter(child: _buildAccountsHeader()),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _AccountCard(
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
                  ),
                  _AccountCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFFB17CFF),
                    iconBackground: const Color(0xFF342354),
                    name: 'Cash Wallet',
                    subtitle: 'Wallet',
                    balance: '250',
                    balanceSuffix: 'EGP',
                    available: '250 EGP',
                    showAvailable: true,
                  ),
                  _AccountCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFFFFA928),
                    iconBackground: const Color(0xFF4A3212),
                    name: 'Investments',
                    subtitle: 'Investment Account',
                    balance: '12,750',
                    balanceSuffix: 'EGP',
                    available: '12,750 EGP',
                    showAvailable: true,
                  ),
                  _AccountCard(
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleButton(icon: Icons.menu_rounded, size: 52),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'Good morning,',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Hossam 👋',
                  style: TextStyle(
                    fontSize: 31,
                    height: 1.1,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here’s your financial overview',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _NotificationButton(),
        ],
      ),
    );
  }

  // ============================================================
  // BALANCE OVERVIEW
  // ============================================================

  Widget _buildBalanceOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF062D36), Color(0xFF081722), Color(0xFF07131D)],
        ),
        border: Border.all(color: const Color(0xFF0B4D57), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00DDB0).withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 18, 0),
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
                      const SizedBox(height: 5),
                      const Text(
                        '1,500',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 55,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'EGP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _BalanceVisibilityButton(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_PeriodSelector()],
            ),
          ),

          const SizedBox(height: 2),

          // Account filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _AccountFilter(),
            ),
          ),

          const SizedBox(height: 4),

          // Static chart
          const SizedBox(
            height: 190,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: _BalanceChart(),
            ),
          ),

          // Available / Reserved
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF071923).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BalanceMetric(
                    title: 'Available',
                    amount: '2,750',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF3EE8B8),
                  ),
                ),
                Container(
                  width: 1,
                  height: 62,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _BalanceMetric(
                    title: 'Reserved',
                    amount: '1,500',
                    icon: Icons.arrow_forward_rounded,
                    color: const Color(0xFFFFA928),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Income / Expenses / Savings
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: const Color(0xFF35E0B5),
                    title: 'Income',
                    value: '+3,250 EGP',
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    icon: Icons.arrow_downward_rounded,
                    iconColor: const Color(0xFFFF4D68),
                    title: 'Expenses',
                    value: '-1,750 EGP',
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF4AA8FF),
                    title: 'Net Savings',
                    value: '+1,500 EGP',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.add_rounded,
              color: const Color(0xFF32E1B5),
              title: 'Add Account',
              subtitle: 'New account',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFB17CFF),
              title: 'Recurring',
              subtitle: 'Scheduled',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.pie_chart_outline_rounded,
              color: const Color(0xFFFFA928),
              title: 'Insights',
              subtitle: 'See analytics',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.swap_horiz_rounded,
              color: const Color(0xFF42A8FF),
              title: 'Transfer',
              subtitle: 'Between accounts',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCOUNTS HEADER
  // ============================================================

  Widget _buildAccountsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 14),
      child: Row(
        children: [
          const Text(
            'Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Text(
            '4 accounts',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACCOUNT CARD
// ================================================================

class _AccountCard extends StatelessWidget {
  const _AccountCard({
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071823),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: iconColor.withValues(alpha: 0.16), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 29),
                ),

                const SizedBox(width: 15),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00DDB0,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Color(0xFF35E0B5),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: balance,
                            style: TextStyle(
                              color: isLiability
                                  ? const Color(0xFFFF5572)
                                  : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' $balanceSuffix',
                            style: TextStyle(
                              color: isLiability
                                  ? const Color(0xFFFF5572)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showAvailable ? 'Available $available' : available,
                      style: TextStyle(
                        color: isLiability
                            ? const Color(0xFFFF5572)
                            : const Color(0xFF35E0B5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.58),
                  size: 26,
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
// BALANCE METRIC
// ================================================================

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: amount,
                        style: TextStyle(
                          color: color,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' EGP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MINI METRIC
// ================================================================

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// QUICK ACTION
// ================================================================

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: const Color(0xFF071722),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.045)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.43),
                    fontSize: 9.5,
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
// PERIOD SELECTOR
// ================================================================

class _PeriodSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '6 Months',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 7),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACCOUNT FILTER
// ================================================================

class _AccountFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0A202A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1D5360)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_rounded,
            color: Color(0xFF35E0B5),
            size: 17,
          ),
          SizedBox(width: 8),
          Text(
            'All Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 7),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: 17,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BALANCE VISIBILITY
// ================================================================

class _BalanceVisibilityButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Icon(
        Icons.visibility_outlined,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

// ================================================================
// CIRCLE BUTTON
// ================================================================

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.size});

  final IconData icon;
  final double size;

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
      child: Icon(icon, color: Colors.white, size: 25),
    );
  }
}

// ================================================================
// NOTIFICATION BUTTON
// ================================================================

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A26),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        Positioned(
          right: 2,
          top: 1,
          child: Container(
            width: 11,
            height: 11,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BalanceChartPainter()),
            ),

            // Y axis
            Positioned(
              right: 0,
              top: 18,
              bottom: 26,
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

            // Tooltip
            Positioned(
              right: 34,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF062D35),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFF14DDB1).withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E1B3).withValues(alpha: 0.08),
                      blurRadius: 15,
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

            // X axis
            Positioned(
              left: 8,
              right: 42,
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
    );
  }
}

class _ChartLabel extends StatelessWidget {
  const _ChartLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 10,
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
