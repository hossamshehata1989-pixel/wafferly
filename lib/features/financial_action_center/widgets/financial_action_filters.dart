import 'package:flutter/material.dart';

import 'financial_action_filter_card.dart';

class FinancialActionFilters extends StatelessWidget {
  const FinancialActionFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85, // ✅ تقليل الارتفاع
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          FinancialActionFilterCard(
            title: "All",
            icon: Icons.dashboard_outlined,
            count: 12,
            color: const Color(0xFF8B5CF6),
            selected: true,
            onTap: () {},
          ),
          FinancialActionFilterCard(
            title: "Commit",
            icon: Icons.account_balance_outlined,
            count: 6,
            color: const Color(0xFF9C275F),
            selected: false,
            onTap: () {},
          ),
          FinancialActionFilterCard(
            title: "Expense",
            icon: Icons.shopping_cart_outlined,
            count: 2,
            color: const Color(0xFFFF5A5F),
            selected: false,
            onTap: () {},
          ),
          FinancialActionFilterCard(
            title: "Income",
            icon: Icons.account_balance_wallet_outlined,
            count: 1,
            color: const Color(0xFF30D158),
            selected: false,
            onTap: () {},
          ),
          FinancialActionFilterCard(
            title: "Transfer",
            icon: Icons.swap_horiz,
            count: 2,
            color: const Color(0xFFFF2D8D),
            selected: false,
            onTap: () {},
          ),
          FinancialActionFilterCard(
            title: "Goals",
            icon: Icons.flag_outlined,
            count: 3,
            color: const Color(0xFF3A7BFF),
            selected: false,
            onTap: () {},
          ),
          FinancialActionFilterCard(
            title: "Invest",
            icon: Icons.trending_up,
            count: 1,
            color: const Color(0xFFFFB800),
            selected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
