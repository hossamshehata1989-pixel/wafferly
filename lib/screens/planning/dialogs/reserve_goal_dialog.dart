// lib/screens/planning/dialogs/reserve_goal_dialog.dart

import 'package:flutter/material.dart';
import '../../../models/enums/account_enums.dart';
import '../../../services/account_service.dart';
import '../../../services/goal_allocation_service.dart';
import '../../../services/goal_service.dart';
import '../../../services/goal_funding_projection_service.dart';
import '../../../services/goal_activity_service.dart';
import '../../../models/goal_activity.dart';

Future<bool?> showReserveGoalDialog(
  BuildContext context, {
  required String goalId,
}) async {
  final accountService = AccountService();
  final allocationService = GoalAllocationService();
  final goalService = GoalService();
  final projectionService = GoalFundingProjectionService();
  final activityService = GoalActivityService();

  final goal = goalService.getById(goalId);
  if (goal == null) {
    return false;
  }

  final projection = projectionService.getProjection(goalId);
  final currentProgress = projection.totalProgress;
  final remaining = (goal.targetAmount - currentProgress).clamp(
    0.0,
    double.infinity,
  );

  if (remaining <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This goal is fully funded.'),
        backgroundColor: Colors.green,
      ),
    );
    return false;
  }

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
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Reserve Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining to reach goal:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${remaining.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Source Account'),
                items: accounts.map((a) {
                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedAccountId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                var amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                if (amount > remaining) {
                  final confirm = await showDialog<bool>(
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
                          child: Text(
                            'Reserve ${remaining.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) {
                    return;
                  }
                  amount = remaining;
                }

                // 1. إنشاء Allocation (الحماية الأساسية)
                final success = await allocationService.createAllocation(
                  accountId: selectedAccountId!,
                  goalId: goalId,
                  amount: amount,
                );

                // 2. إنشاء GoalActivity من نوع reserve (فقط عند النجاح)
                if (success) {
                  final activity = GoalActivity.create(
                    goalId: goalId,
                    type: GoalActivityType.reserve,
                    amount: amount,
                    sourceAccountId: selectedAccountId,
                    destinationAccountId: null,
                    notes: 'Reserved for goal',
                  );
                  await activityService.addActivity(activity);
                }

                Navigator.pop(context, success);
              },
              child: const Text('Reserve'),
            ),
          ],
        );
      },
    ),
  );
}
