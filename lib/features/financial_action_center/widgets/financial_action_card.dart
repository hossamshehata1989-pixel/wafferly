import 'package:flutter/material.dart';
import '../models/financial_action_display.dart';

class FinancialActionCard extends StatelessWidget {
  final FinancialActionDisplay display;
  final VoidCallback onExecute;

  const FinancialActionCard({
    super.key,
    required this.display,
    required this.onExecute,
  });

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1) return 'In $difference days';
    return 'Due';
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference == 0) return const Color(0xFFFFB020);
    if (difference == 1) return const Color(0xFF4FC3F7);
    if (difference == -1) return const Color(0xFFFF6B6B);
    if (difference > 1) return const Color(0xFF22C55E);
    return Colors.grey.shade400;
  }

  Color _getCategoryColor(String subtitle) {
    switch (subtitle) {
      case 'Expense':
        return const Color(0xFFFF6B6B);
      case 'Income':
        return const Color(0xFF22C55E);
      case 'Transfer':
        return const Color(0xFF4FC3F7);
      case 'Goal Contribution':
        return const Color(0xFFB388FF);
      case 'Loan Payment':
        return const Color(0xFFFF8A4C);
      case 'Budget Reset':
        return const Color(0xFF26C6DA);
      default:
        return Colors.grey.shade500;
    }
  }

  Color _getAmountColor(String subtitle) {
    switch (subtitle) {
      case 'Expense':
        return const Color(0xFFFF6B6B);
      case 'Income':
        return const Color(0xFF22C55E);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.shade300.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      elevation: 0,
      color: isDark ? const Color(0xFF1E202A) : Colors.white,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.grey.shade200.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== الصف الأول: الأيقونة + العنوان + المبلغ ==========
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      display.subtitle,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    display.icon,
                    color: _getCategoryColor(display.subtitle),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    display.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (display.subtitle.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        display.subtitle,
                      ).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      display.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(display.subtitle),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  display.amountText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _getAmountColor(display.subtitle),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ========== الصف الثاني: المصدر والوجهة ==========
            if (display.sourceAccountName != null ||
                display.destinationAccountName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.grey.shade100.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (display.sourceAccountName != null) ...[
                      Icon(
                        Icons.account_balance_outlined,
                        size: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text(
                          display.sourceAccountName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    if (display.sourceAccountName != null &&
                        display.destinationAccountName != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (display.destinationAccountName != null) ...[
                      Icon(
                        Icons.flag_outlined,
                        size: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text(
                          display.destinationAccountName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ========== الصف الثالث: التاريخ + الزر ==========
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getDueDateColor(display.dueDate).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getDueDateColor(
                        display.dueDate,
                      ).withOpacity(0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getDueDateColor(display.dueDate),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDueDate(display.dueDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getDueDateColor(display.dueDate),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                FilledButton(
                  onPressed: onExecute,
                  style: FilledButton.styleFrom(
                    fixedSize: const Size(64, 28),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(64, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: _getCategoryColor(display.subtitle),
                    elevation: 0,
                  ),
                  child: Text(display.buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
