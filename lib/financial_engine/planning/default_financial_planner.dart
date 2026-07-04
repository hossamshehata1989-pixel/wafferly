import '../interpretation/financial_action_type.dart';
import '../interpretation/normalized_intent.dart';
import 'chart_of_accounts.dart';
import 'entry_line.dart';
import 'financial_execution_plan.dart';
import 'financial_planner.dart';
import 'journal_entry_mutation.dart';
import 'goal_activity_mutation.dart';
import 'release_allocation_mutation.dart';
import '../../models/goal_activity.dart';

final class DefaultFinancialPlanner implements FinancialPlanner {
  final ChartOfAccounts _chartOfAccounts;

  const DefaultFinancialPlanner({required ChartOfAccounts chartOfAccounts})
    : _chartOfAccounts = chartOfAccounts;

  @override
  Future<FinancialExecutionPlan> build(NormalizedIntent intent) async {
    switch (intent.action) {
      case FinancialActionType.expense:
        return _planExpense(intent);

      case FinancialActionType.income:
        return _planIncome(intent);

      case FinancialActionType.transfer:
        return _planTransfer(intent);

      case FinancialActionType.goalTransfer:
        return _planGoalTransfer(intent);

      default:
        throw UnimplementedError(
          'Planner not implemented for ${intent.action}',
        );
    }
  }

  FinancialExecutionPlan _planExpense(NormalizedIntent intent) {
    final categoryId =
        intent.categoryId ?? (throw StateError('Category is required'));

    final expenseAccountId =
        _chartOfAccounts.accountForCategory(categoryId) ??
        (throw StateError('No account mapping found for category $categoryId'));

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Expense',
          lines: [
            EntryLine(accountId: expenseAccountId, debit: intent.amount),
            EntryLine(accountId: intent.sourceAccountId, credit: intent.amount),
          ],
        ),
      ],
    );
  }

  FinancialExecutionPlan _planIncome(NormalizedIntent intent) {
    final categoryId =
        intent.categoryId ?? (throw StateError('Category is required'));

    final incomeAccountId =
        _chartOfAccounts.accountForCategory(categoryId) ??
        (throw StateError('No account mapping found for category $categoryId'));

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Income',
          lines: [
            EntryLine(accountId: intent.sourceAccountId, debit: intent.amount),
            EntryLine(accountId: incomeAccountId, credit: intent.amount),
          ],
        ),
      ],
    );
  }

  FinancialExecutionPlan _planTransfer(NormalizedIntent intent) {
    final destinationAccountId =
        intent.destinationAccountId ??
        (throw StateError('Destination account is required'));

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Transfer',
          lines: [
            EntryLine(accountId: destinationAccountId, debit: intent.amount),
            EntryLine(accountId: intent.sourceAccountId, credit: intent.amount),
          ],
        ),
      ],
    );
  }

  FinancialExecutionPlan _planGoalTransfer(NormalizedIntent intent) {
    final destinationAccountId =
        intent.destinationAccountId ??
        (throw StateError('Savings account is required'));

    final goalId =
        intent.categoryId ?? (throw StateError('Goal id is required'));

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [
        // 1. Accounting
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Goal Transfer',
          lines: [
            EntryLine(accountId: destinationAccountId, debit: intent.amount),
            EntryLine(accountId: intent.sourceAccountId, credit: intent.amount),
          ],
        ),

        // 2. Release reserved allocation
        ReleaseAllocationMutation(
          goalId: goalId,
          accountId: intent.sourceAccountId,
          amount: intent.amount,
        ),

        // 3. Immutable activity
        GoalActivityMutation(
          goalId: goalId,
          sourceAccountId: intent.sourceAccountId,
          destinationAccountId: destinationAccountId,
          amount: intent.amount,
          activityType: GoalActivityType.transferToSaving,
        ),
      ],
    );
  }
}
