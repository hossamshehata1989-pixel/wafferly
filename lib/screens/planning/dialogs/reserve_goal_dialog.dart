// lib/screens/planning/dialogs/reserve_goal_dialog.dart

import 'package:flutter/material.dart';
import '../../../models/account.dart';
import '../../../services/account_service.dart';
import '../../../services/goal_allocation_service.dart';
import '../../../models/enums/account_enums.dart';
import '../../../models/goal_activity.dart';
import '../../../services/goal_activity_service.dart';
import '../../../services/goal_service.dart';
import '../../../services/goal_projection_service.dart';

Future<bool?> showReserveGoalDialog(
  BuildContext context, {
  required String goalId,
}) async {
  final accountService = AccountService();
  final allocationService = GoalAllocationService();

  final accounts = accountService
      .getAllActiveAccounts()
      .where((a) => a.group == AccountGroup.liquidity)
      .toList();

  if (accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a cash or bank account first')),
    );
    return false;
  }

  String? selectedAccountId = accounts.first.id;
  final amountController = TextEditingController();

  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Reserve Money'),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Source Account'),
                items: accounts.map((a) {
                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                }).toList(),
                onChanged: (value) {
                  setStateDialog(() {
                    selectedAccountId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            var amount = double.tryParse(amountController.text) ?? 0;

            final goalService = GoalService();
            final projectionService = GoalProjectionService();

            final goal = goalService.getById(goalId);

            if (goal == null) {
              return;
            }

            final allocated = await projectionService.getGoalAllocatedAmount(
              goalId,
            );

            final remaining = goal.targetAmount - allocated;

            if (amount <= 0) return;

            if (amount > remaining) {
              final reserveRemaining = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Goal Limit'),
                  content: Text(
                    'Only ${remaining.toStringAsFixed(0)} EGP remains to reach this goal.\n\nReserve the remaining amount instead?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Reserve ${remaining.toStringAsFixed(0)}'),
                    ),
                  ],
                ),
              );

              if (reserveRemaining != true) {
                return;
              }

              amount = remaining;
            }

            final success = await allocationService.createAllocation(
              accountId: selectedAccountId!,
              goalId: goalId,
              amount: amount,
            );

            if (success) {
              await GoalActivityService().addActivity(
                GoalActivity.create(
                  goalId: goalId,
                  type: 'reserve',
                  amount: amount,
                  sourceAccountId: selectedAccountId,
                ),
              );
            }

            Navigator.pop(context, success);
          },
          child: const Text('Reserve'),
        ),
      ],
    ),
  );
}
