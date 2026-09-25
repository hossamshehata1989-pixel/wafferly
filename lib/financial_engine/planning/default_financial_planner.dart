import '../../core/money/money.dart';
import '../domain/financial_transaction_record.dart';
import '../domain/financial_correction_record.dart';
import '../interpretation/financial_action_type.dart';
import '../interpretation/normalized_intent.dart';
import '../mutations/create_transaction_mutation.dart';
import '../mutations/create_correction_mutation.dart';
import '../mutations/invalidate_transaction_mutation.dart';
import '../domain/financial_invalidation_record.dart';
import '../operations/create_allocation_mutation.dart';
import 'chart_of_accounts.dart';
import 'entry_line.dart';
import 'financial_execution_plan.dart';
import 'financial_planner.dart';
import '../mutations/goal_activity_mutation.dart';
import '../mutations/journal_entry_mutation.dart';
import 'planning_context.dart';
import '../mutations/release_allocation_mutation.dart';
import '../../models/goal_activity.dart';
import '../../constants/transaction_constants.dart';

final class DefaultFinancialPlanner implements FinancialPlanner {
  final ChartOfAccounts _chartOfAccounts;

  const DefaultFinancialPlanner({
    required ChartOfAccounts chartOfAccounts,
    dynamic transactionLookupPort,
  }) : _chartOfAccounts = chartOfAccounts;

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

      case FinancialActionType.commitmentPayment:
        return _planCommitmentPayment(context);

      case FinancialActionType.goalTransfer:
        return _planGoalTransfer(context);

      case FinancialActionType.goalSavingTransfer:
        return _planGoalSavingTransfer(context);

      case FinancialActionType.createGoalAllocation:
        return _planGoalAllocation(intent);

      case FinancialActionType.openingBalance:
        return _planOpeningBalance(context);

      case FinancialActionType.balanceReconciliation:
        return _planBalanceReconciliation(context);

      case FinancialActionType.correction:
        return _planCorrection(context);

      case FinancialActionType.deletion:
        return _planDeletion(context);

      default:
        throw UnimplementedError(
          'Planner not implemented for ${intent.action}',
        );
    }
  }

  FinancialExecutionPlan _planExpense(PlanningContext context) {
    final intent = context.intent;

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

    final FinancialTransactionRecord transactionRecord =
        FinancialTransactionRecord(
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
        CreateTransactionMutation(record: transactionRecord),
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

  FinancialExecutionPlan _planCommitmentPayment(PlanningContext context) {
    final intent = context.intent;

    final liabilityAccountId =
        intent.destinationAccountId ??
        (throw StateError('Liability account is required'));

    final transactionRecord = FinancialTransactionRecord(
      transactionId: 'txn-${DateTime.now().microsecondsSinceEpoch}',
      type: 'transfer',
      fromAccountId: intent.sourceAccountId,
      toAccountId: liabilityAccountId,
      categoryId: null,
      subCategoryId: null,
      amount: intent.amount,
      currencyCode: context.metadata.currencyCode,
      paymentMethod: context.metadata.paymentMethod,
      occurredAt: context.metadata.occurredAt,
      note: context.metadata.note,
      isExceptional: intent.isExceptional,
      source: TransactionSource.scheduled,
      actorMemberId: intent.actorMemberId,
      commitmentId: context.executionContext.commitmentId,
      scheduleRuleId: context.executionContext.scheduleRuleId,
      occurrenceId: context.executionContext.occurrenceId,
    );

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: context.executionContext.idempotencyKey,
      mutations: [
        CreateTransactionMutation(record: transactionRecord),
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Commitment Payment',
          lines: [
            EntryLine(accountId: liabilityAccountId, debit: intent.amount),
            EntryLine(accountId: intent.sourceAccountId, credit: intent.amount),
          ],
        ),
      ],
    );
  }

  FinancialExecutionPlan _planGoalTransfer(PlanningContext context) {
    final intent = context.intent;

    final destinationAccountId =
        intent.destinationAccountId ??
        (throw StateError('Savings account is required'));

    final goalId = intent.goalId ?? (throw StateError('Goal id is required'));

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
        // 1. Transaction / financial truth
        CreateTransactionMutation(record: transactionRecord),

        // 2. Accounting
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Goal Transfer',
          lines: [
            EntryLine(accountId: destinationAccountId, debit: intent.amount),
            EntryLine(accountId: intent.sourceAccountId, credit: intent.amount),
          ],
        ),

        // 3. Release the reservation through the Planning Engine
        ReleaseAllocationMutation(
          goalId: goalId,
          accountId: intent.sourceAccountId,
          amount: intent.amount,
        ),

        // 4. Immutable goal history
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

  FinancialExecutionPlan _planGoalSavingTransfer(PlanningContext context) {
    final intent = context.intent;

    final destinationAccountId =
        intent.destinationAccountId ??
        (throw StateError('Savings account is required'));

    final goalId = intent.goalId ?? (throw StateError('Goal id is required'));

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
      idempotencyKey: context.executionContext.idempotencyKey,
      mutations: [
        CreateTransactionMutation(record: transactionRecord),
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Goal Saving Transfer',
          lines: [
            EntryLine(accountId: destinationAccountId, debit: intent.amount),
            EntryLine(accountId: intent.sourceAccountId, credit: intent.amount),
          ],
        ),
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

  FinancialExecutionPlan _planOpeningBalance(PlanningContext context) {
    final intent = context.intent;

    const openingEquityAccountId =
        ChartOfAccounts.openingBalanceEquityAccountId;

    final accountId = intent.sourceAccountId;
    final amount = intent.amount;
    final accountReceivesDebit = !intent.isLiability;

    final transactionRecord = FinancialTransactionRecord(
      transactionId: 'txn-${DateTime.now().microsecondsSinceEpoch}',
      type: 'initial_balance',
      fromAccountId: accountReceivesDebit ? null : accountId,
      toAccountId: accountReceivesDebit ? accountId : null,
      categoryId: 'initial_balance',
      subCategoryId: null,
      amount: amount,
      currencyCode: context.metadata.currencyCode,
      paymentMethod: context.metadata.paymentMethod,
      occurredAt: context.metadata.occurredAt,
      note: context.metadata.note,
      isExceptional: false,
      source: 'account_creation',
      actorMemberId: null,
    );

    return FinancialExecutionPlan(
      planId: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      operationId: 'operation',
      idempotencyKey: 'temporary',
      mutations: [
        JournalEntryMutation(
          journalEntryId: 'journal-1',
          description: 'Opening Balance',
          lines: accountReceivesDebit
              ? [
                  EntryLine(accountId: accountId, debit: amount),
                  EntryLine(accountId: openingEquityAccountId, credit: amount),
                ]
              : [
                  EntryLine(accountId: openingEquityAccountId, debit: amount),
                  EntryLine(accountId: accountId, credit: amount),
                ],
        ),
        CreateTransactionMutation(record: transactionRecord),
      ],
    );
  }


  FinancialExecutionPlan _planBalanceReconciliation(PlanningContext context) {
    final reconciliation = context.balanceReconciliation ??
        (throw StateError('Balance reconciliation context is required'));

    final difference = reconciliation.difference;
    if (difference == Money.zero) {
      throw StateError('Balance reconciliation difference cannot be zero');
    }

    const equityAccountId =
        ChartOfAccounts.balanceReconciliationEquityAccountId;
    final amount = difference.abs();

    // `fromAccountId` is the credit side and `toAccountId` is the debit side
    // for this dedicated transaction type. This keeps the write model able to
    // describe the double-entry effect without pretending reconciliation is a
    // cash transfer.
    // `difference` is observed - system in the account's signed balance
    // representation. For liabilities, a negative difference means the
    // liability increased (e.g. -1000 -> -1300): the liability is credited
    // and reconciliation equity is debited. A positive difference means the
    // liability decreased: the liability is debited and equity is credited.
    final debitAccountId = reconciliation.isLiability
        ? (difference > Money.zero ? reconciliation.accountId : equityAccountId)
        : (difference > Money.zero ? reconciliation.accountId : equityAccountId);
    final creditAccountId = reconciliation.isLiability
        ? (difference > Money.zero ? equityAccountId : reconciliation.accountId)
        : (difference > Money.zero ? equityAccountId : reconciliation.accountId);

    final transactionId =
        'reconciliation-${context.executionContext.idempotencyKey}';

    final transactionRecord = FinancialTransactionRecord(
      transactionId: transactionId,
      type: TransactionType.balanceReconciliation,
      fromAccountId: creditAccountId,
      toAccountId: debitAccountId,
      categoryId: TransactionType.balanceReconciliation,
      subCategoryId: null,
      amount: amount,
      currencyCode: context.metadata.currencyCode,
      paymentMethod: context.metadata.paymentMethod,
      occurredAt: context.metadata.occurredAt,
      note: [
        'Balance reconciliation: ${reconciliation.reason.name}',
        if (context.metadata.note != null &&
            context.metadata.note!.trim().isNotEmpty)
          context.metadata.note!,
      ].join(' — '),
      isExceptional: false,
      source: TransactionSource.balanceReconciliation,
      actorMemberId: null,
    );

    return FinancialExecutionPlan(
      planId: 'plan-$transactionId',
      operationId: transactionId,
      idempotencyKey: context.executionContext.idempotencyKey,
      mutations: [
        JournalEntryMutation(
          journalEntryId: 'journal-$transactionId',
          description: 'Balance Reconciliation',
          lines: [
            EntryLine(accountId: debitAccountId, debit: amount),
            EntryLine(accountId: creditAccountId, credit: amount),
          ],
        ),
        CreateTransactionMutation(record: transactionRecord),
      ],
    );
  }

  FinancialExecutionPlan _planCorrection(PlanningContext context) {
    final correction = context.correction ??
        (throw StateError('Correction context is required'));

    final before = correction.before;
    final after = correction.after;

    if (before.transactionId != correction.transactionId) {
      throw StateError(
        'Correction before transaction id must match the original transaction id',
      );
    }

    if (before.type != after.type) {
      throw StateError(
        'Changing transaction type requires an explicit domain operation',
      );
    }

    switch (after.type) {
      case 'expense':
      case 'income':
      case 'transfer':
      case TransactionType.balanceReconciliation:
        break;
      default:
        throw StateError(
          'Correction is not supported for transaction type ${after.type}',
        );
    }

    final correctionId =
        'correction-${context.executionContext.idempotencyKey}';
    final correctedTransactionId = 'corrected-$correctionId';

    // The corrected truth is a NEW immutable transaction. The original
    // transaction id must never be reused for the corrected state.
    final correctedAfter = FinancialTransactionRecord(
      transactionId: correctedTransactionId,
      type: after.type,
      fromAccountId: after.fromAccountId,
      toAccountId: after.toAccountId,
      categoryId: after.categoryId,
      subCategoryId: after.subCategoryId,
      amount: after.amount,
      currencyCode: after.currencyCode,
      paymentMethod: after.paymentMethod,
      occurredAt: after.occurredAt,
      note: after.note,
      isExceptional: after.isExceptional,
      source: after.source,
      actorMemberId: after.actorMemberId,
      commitmentId: after.commitmentId,
      scheduleRuleId: after.scheduleRuleId,
      occurrenceId: after.occurrenceId,
    );

    final record = FinancialCorrectionRecord(
      correctionId: correctionId,
      originalTransactionId: correction.transactionId,
      before: before,
      after: correctedAfter,
    );

    return FinancialExecutionPlan(
      planId: 'plan-$correctionId',
      operationId: correctionId,
      idempotencyKey: context.executionContext.idempotencyKey,
      mutations: [
        CreateCorrectionMutation(record: record),
      ],
    );
  }

  FinancialExecutionPlan _planDeletion(PlanningContext context) {
    final deletion = context.deletion ??
        (throw StateError('Deletion context is required'));

    final invalidationId =
        'invalidation-${context.executionContext.idempotencyKey}';

    final record = FinancialInvalidationRecord(
      invalidationId: invalidationId,
      originalTransactionId: deletion.transactionId,
      before: deletion.before,
    );

    return FinancialExecutionPlan(
      planId: 'plan-$invalidationId',
      operationId: invalidationId,
      idempotencyKey: context.executionContext.idempotencyKey,
      mutations: [
        InvalidateTransactionMutation(record: record),
      ],
    );
  }
}
