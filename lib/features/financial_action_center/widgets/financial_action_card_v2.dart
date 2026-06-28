import 'package:flutter/material.dart';

import '../models/financial_action_display.dart';
import '../mappers/financial_action_style_mapper.dart';

class FinancialActionCardV2 extends StatelessWidget {
  final FinancialActionDisplay display;
  final VoidCallback onExecute;

  const FinancialActionCardV2({
    super.key,
    required this.display,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    const styleMapper = FinancialActionStyleMapper();
    final style = styleMapper.fromKind(display.kind);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 80),
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ), // ✅ تقليل margin
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E202A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT COLOR STRIPE
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: style.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ), // ✅ تقليل padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ICON (أصغر)
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: style.iconBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(display.icon, color: style.primary, size: 16),
                  ),

                  const SizedBox(width: 8),

                  // INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                display.subtitle,
                                style: TextStyle(
                                  color: style.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: style.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDueDate(display.dueDate),
                                style: TextStyle(
                                  color: style.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          display.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                display.sourceAccountName ?? '-',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            if (display.destinationAccountName != null) ...[
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 8,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.flag_outlined,
                                size: 11,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  display.destinationAccountName!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // AMOUNT + BUTTONS (أصغر)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        display.amountText,
                        style: TextStyle(
                          color: style.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.13)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 30,
                            child: FilledButton(
                              onPressed: onExecute,
                              style: FilledButton.styleFrom(
                                backgroundColor: style.buttonBackground,
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(display.buttonText),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return 'Due';
  }
}
