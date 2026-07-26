import '../interpretation/financial_action_type.dart';
import '../interpretation/normalized_intent.dart';
import 'chart_of_accounts.dart';
import 'entry_line.dart';
import 'financial_execution_plan.dart';
import 'financial_planner.dart';
import '../mutations/journal_entry_mutation.dart';
import '../mutations/goal_activity_mutation.dart';
import '../mutations/release_allocation_mutation.dart';
import '../../models/goal_activity.dart';
import '../operations/create_allocation_mutation.dart';
import 'planning_context.dart';
import '../domain_guard/financial_constraint.dart';
import '../domain/financial_transaction_record.dart';
import '../mutations/create_transaction_mutation.dart';
import '../ports/transaction_lookup_port.dart';
import '../mutations/update_transaction_mutation.dart';
import '../mutations/deletion_transaction_mutation.dart';

final class DefaultFinancialPlanner implements FinancialPlanner {
  final ChartOfAccounts _chartOfAccounts;
  final TransactionLookupPort _transactionLookupPort;

  const DefaultFinancialPlanner({
    required ChartOfAccounts chartOfAccounts,
    required TransactionLookupPort transactionLookupPort,
  }) : _chartOfAccounts = chartOfAccounts,
       _transactionLookupPort = transactionLookupPort;

  @override
  Future<FinancialExecutionPlan> build(PlanningContext context) async {
    final intent = context.intent;
    switch (intent.action) {
      case FinancialActionType.expense:
        return _planExpense(context);

      case FinancialActionType.income:
        return _planIncome(context);

      case FinancialActionType.transfer:
        return _planTransfer(context);

      case FinancialActionType.goalTransfer:
        return _planGoalTransfer(context);

      case FinancialActionType.createGoalAllocation:
        return _planGoalAllocation(intent);

      case FinancialActionType.correction:
        return await _planCorrection(context);

      case FinancialActionType.deletion:
        return await _planDeletion(context);

      default:
        throw UnimplementedError(
          'Planner not implemented for ${intent.action}',
        );
    }
  }

  FinancialExecutionPlan _planExpense(PlanningContext context) {
    final intent = context.intent;

    final balanceConstraint = context
        .constraint<InsufficientBalanceConstraint>();
    final categoryId =
        intent.categoryId ?? (throw StateError('Category is required'));

    final expenseAccountId =
        _chartOfAccounts.accountForCategory(categoryId) ??
        (throw StateError('No account mapping found for category $categoryId'));
    final transactionRecord = FinancialTransactionRecord(
      transactionId: 'txn-${DateTime.now().microsecondsSinceEpoch}',
      type: 'expense',
      fromAccountId: intent.sourceAccountId,
      toAccountId: null,
      categoryId: categoryId,
      subCategoryId: null,
      amount: intent.amount,
      currencyCode: context.metadata.currencyCode,
      paymentMethod: context.metadata.paymentMethod,
      occurredAt: context.metadata.occurredAt,
      note: context.metadata.note,
      isExceptional: intent.isExceptional,
      source: 'manual',
      actorMemberId: intent.actorMemberId,
    );
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

        CreateTransactionMutation(record: transactionRecord),
      ],
    );
  }

  FinancialExecutionPlan _planIncome(PlanningContext context) {
    final intent = context.intent;
    final categoryId =
        intent.categoryId ?? (throw StateError('Category is required'));

    final incomeAccountId =
        _chartOfAccounts.accountForCategory(categoryId) ??
        (throw StateError('No account mapping found for category $categoryId'));

    final transactionRecord = FinancialTransactionRecord(
      transactionId: 'txn-${DateTime.now().microsecondsSinceEpoch}',
      type: 'income',
      fromAccountId: null,
      toAccountId: intent.sourceAccountId,
      categoryId: categoryId,
      subCategoryId: null,
      amount: intent.amount,
      currencyCode: context.metadata.currencyCode,
      paymentMethod: context.metadata.paymentMethod,
      occurredAt: context.metadata.occurredAt,
      note: context.metadata.note,
      isExceptional: intent.isExceptional,
      source: 'manual',
      actorMemberId: intent.actorMemberId,
    );

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

        CreateTransactionMutation(record: transactionRecord),
      ],
    );
  }

  FinancialExecutionPlan _planTransfer(PlanningContext context) {
    final intent = context.intent;
    final destinationAccountId =
        intent.destinationAccountId ??
        (throw StateError('Destination account is required'));

    final transactionRecord = FinancialTransactionRecord(
      transactionId: 'txn-${DateTime.now().microsecondsSinceEpoch}',
      type: 'transfer',
      fromAccountId: intent.sourceAccountId,
      toAccountId: destinationAccountId,
      categoryId: null,
      subCategoryId: null,
      amount: intent.amount,
      currencyCode: context.metadata.currencyCode,
      paymentMethod: context.metadata.paymentMethod,
      occurredAt: context.metadata.occurredAt,
      note: context.metadata.note,
      isExceptional: intent.isExceptional,
      source: 'manual',
      actorMemberId: intent.actorMemberId,
    );

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
        CreateTransactionMutation(record: transactionRecord),
      ],
    );
  }

  FinancialExecutionPlan _planGoalTransfer(PlanningContext context) {
    final intent = context.intent;
    final destinationAccountId =
        intent.destinationAccountId ??
        (throw StateError('Savings account is required'));

    final goalId = intent.goalId ?? (throw StateError('Goal id is required'));

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

  FinancialExecutionPlan _planGoalAllocation(NormalizedIntent intent) {
    final goalId = intent.goalId ?? (throw StateError('Goal id is required'));

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [
        CreateAllocationMutation(
          accountId: intent.sourceAccountId,
          goalId: goalId,
          amount: intent.amount,
        ),
      ],
    );
  }

  Future<FinancialExecutionPlan> _planCorrection(
    PlanningContext context,
  ) async {
    final correction = context.correction!;

    final before = await _transactionLookupPort.findById(
      correction.transactionId,
    );

    if (before == null) {
      throw StateError('Transaction not found: ${correction.transactionId}');
    }

    final after = correction.after;

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [UpdateTransactionMutation(before: before, after: after)],
    );
  }

  Future<FinancialExecutionPlan> _planDeletion(PlanningContext context) async {
    final deletion = context.deletion!;

    final before = await _transactionLookupPort.findById(
      deletion.transactionId,
    );

    if (before == null) {
      throw StateError('Transaction not found: ${deletion.transactionId}');
    }

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [DeleteTransactionMutation(record: before)],
    );
  }
}
