import 'package:flutter/material.dart';

import '../../../models/scheduled_action_execution_context.dart';

import '../widgets/financial_action_card.dart';
import '../mappers/financial_action_display_mapper.dart';
import '../widgets/financial_action_footer.dart';

class FinancialActionPanel extends StatelessWidget {
  final VoidCallback onSkip;

  final List<ScheduledActionExecutionContext> actions;

  final void Function(ScheduledActionExecutionContext context) onExecute;

  const FinancialActionPanel({
    super.key,
    required this.actions,
    required this.onExecute,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    const mapper = FinancialActionDisplayMapper();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView.builder(
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final item = actions[index];
                  final display = mapper.fromContext(item);

                  return FinancialActionCard(
                    display: display,
                    onExecute: () => onExecute(item),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            FinancialActionFooter(onSkip: onSkip),
          ],
        ),
      ),
    );
  }
}
