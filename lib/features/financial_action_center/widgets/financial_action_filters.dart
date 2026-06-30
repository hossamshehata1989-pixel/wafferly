import 'package:flutter/material.dart';
import '../models/financial_action_filter.dart';
import 'financial_action_filter_card.dart';

class FinancialActionFilters extends StatelessWidget {
  final FinancialActionFilter selectedFilter;
  final ValueChanged<FinancialActionFilter> onFilterChanged;
  final Map<FinancialActionFilter, int> counts;

  const FinancialActionFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          FinancialActionFilterCard(
            title: "All",
            count: counts[FinancialActionFilter.all] ?? 0,
            color: const Color(0xFF8B5CF6),
            selected: selectedFilter == FinancialActionFilter.all,
            onTap: () => onFilterChanged(FinancialActionFilter.all),
          ),
          FinancialActionFilterCard(
            title: "Expense",
            count: counts[FinancialActionFilter.expenses] ?? 0,
            color: const Color(0xFFFF5A5F),
            selected: selectedFilter == FinancialActionFilter.expenses,
            onTap: () => onFilterChanged(FinancialActionFilter.expenses),
          ),
          FinancialActionFilterCard(
            title: "Income",
            count: counts[FinancialActionFilter.income] ?? 0,
            color: const Color(0xFF30D158),
            selected: selectedFilter == FinancialActionFilter.income,
            onTap: () => onFilterChanged(FinancialActionFilter.income),
          ),
          FinancialActionFilterCard(
            title: "Transfer",
            count: counts[FinancialActionFilter.transfers] ?? 0,
            color: const Color(0xFFFF2D8D),
            selected: selectedFilter == FinancialActionFilter.transfers,
            onTap: () => onFilterChanged(FinancialActionFilter.transfers),
          ),
          FinancialActionFilterCard(
            title: "Goals",
            count: counts[FinancialActionFilter.goals] ?? 0,
            color: const Color(0xFF3A7BFF),
            selected: selectedFilter == FinancialActionFilter.goals,
            onTap: () => onFilterChanged(FinancialActionFilter.goals),
          ),
          FinancialActionFilterCard(
            title: "Invest",
            count: counts[FinancialActionFilter.investments] ?? 0,
            color: const Color(0xFFFFB800),
            selected: selectedFilter == FinancialActionFilter.investments,
            onTap: () => onFilterChanged(FinancialActionFilter.investments),
          ),
        ],
      ),
    );
  }
}
