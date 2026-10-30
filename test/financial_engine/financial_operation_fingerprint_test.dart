import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/balance_reconciliation_intent.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/reconciliation_reason.dart';
import 'package:wafferly/financial_engine/commands/correction/correction_intent.dart';
import 'package:wafferly/financial_engine/commands/correction/deletion_transaction_intent.dart';
import 'package:wafferly/financial_engine/commands/credit_card/credit_card_charge_intent.dart';
import 'package:wafferly/financial_engine/commands/expense/expense_intent.dart';
import 'package:wafferly/financial_engine/commands/income/income_intent.dart';
import 'package:wafferly/financial_engine/commands/opening_balance/opening_balance_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/commands/transfer/transfer_intent.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/idempotency/financial_operation_fingerprint.dart';
import 'package:wafferly/financial_engine/operations/balance_reconciliation_operation.dart';
import 'package:wafferly/financial_engine/operations/commitment_payment_operation.dart';
import 'package:wafferly/financial_engine/operations/correction_financial_operation.dart';
import 'package:wafferly/financial_engine/operations/create_goal_allocation_operation.dart';
import 'package:wafferly/financial_engine/operations/credit_card_charge_operation.dart';
import 'package:wafferly/financial_engine/operations/credit_card_payment_operation.dart';
import 'package:wafferly/financial_engine/operations/deletion_operation.dart';
import 'package:wafferly/financial_engine/operations/expense_operation.dart';
import 'package:wafferly/financial_engine/operations/financial_operation.dart';
import 'package:wafferly/financial_engine/operations/goal_saving_transfer_operation.dart';
import 'package:wafferly/financial_engine/operations/goal_transfer_operation.dart';
import 'package:wafferly/financial_engine/operations/income_operation.dart';
import 'package:wafferly/financial_engine/operations/opening_balance_operation.dart';
import 'package:wafferly/financial_engine/operations/transfer_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/models/transaction.dart';

void main() {
  final occurredAt = DateTime(2026, 10, 30, 12, 30);

  ExecutionContext context({
    String key = 'fingerprint-key',
    String? commitmentId,
    String? scheduleRuleId,
    String? occurrenceId,
    String? actorMemberId = 'owner',
    String? source = 'manual',
    String? commandType = 'FingerprintTest',
  }) => ExecutionContext(
    idempotencyKey: key,
    commitmentId: commitmentId,
    scheduleRuleId: scheduleRuleId,
    occurrenceId: occurrenceId,
    actorMemberId: actorMemberId,
    source: source,
    commandType: commandType,
  );

  TransactionMetadata metadata({String? note}) => TransactionMetadata(
    occurredAt: occurredAt,
    note: note,
    paymentMethod: 'cash',
    currencyCode: 'EGP',
  );

  FinancialTransactionRecord financialRecord({
    String transactionId = 'txn-1',
    String categoryId = 'dailyTransport',
    String note = 'record note',
  }) => FinancialTransactionRecord(
    transactionId: transactionId,
    type: 'expense',
    fromAccountId: 'wallet',
    categoryId: categoryId,
    amount: Money.parse('20.50'),
    currencyCode: 'EGP',
    paymentMethod: 'cash',
    occurredAt: occurredAt,
    note: note,
    isExceptional: false,
    source: 'manual',
    actorMemberId: 'owner',
  );

  List<FinancialOperation> allSupportedOperations(ExecutionContext ctx) => [
    BalanceReconciliationOperation(
      intent: BalanceReconciliationIntent(
        accountId: 'wallet',
        systemBalance: Money.parse('100'),
        observedBalance: Money.parse('125'),
        isLiability: false,
        reason: ReconciliationReason.other,
      ),
      metadata: metadata(),
      context: ctx,
    ),
    CommitmentPaymentOperation(
      sourceAccountId: 'wallet',
      liabilityAccountId: 'loan',
      commitmentId: 'commitment-1',
      amount: Money.parse('50'),
      metadata: metadata(),
      context: ctx,
    ),
    CorrectionOperation(
      intent: CorrectionIntent(
        transactionId: 'txn-1',
        before: financialRecord(),
        after: financialRecord(categoryId: 'bills'),
      ),
      metadata: metadata(),
      context: ctx,
    ),
    CreateGoalAllocationOperation(
      accountId: 'wallet',
      goalId: 'goal-1',
      amount: Money.parse('10'),
      occurredAt: occurredAt,
      metadata: metadata(),
      context: ctx,
    ),
    CreditCardChargeOperation(
      intent: CreditCardChargeIntent(
        creditCardAccountId: 'card-1',
        categoryId: 'supermarket',
        subCategoryId: 'groceries',
        amount: Money.parse('75'),
        isExceptional: false,
        actorMemberId: 'owner',
      ),
      metadata: metadata(),
      context: ctx,
    ),
    CreditCardPaymentOperation(
      sourceAssetAccountId: 'wallet',
      creditCardAccountId: 'card-1',
      amount: Money.parse('75'),
      metadata: metadata(),
      context: ctx,
    ),
    DeleteOperation(
      intent: DeleteTransactionIntent(
        transaction: Transaction(
          id: 'txn-delete-1',
          amount: 20.5,
          type: 'expense',
          fromAccountId: 'wallet',
          categoryId: 'dailyTransport',
          date: occurredAt,
          paymentMethod: 'cash',
          currencyCode: 'EGP',
          actorMemberId: 'owner',
        ),
      ),
      metadata: metadata(),
      context: ctx,
    ),
    ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'wallet',
        amount: Money.parse('25.75'),
        categoryId: 'dailyTransport',
        isExceptional: false,
        actorMemberId: 'owner',
      ),
      metadata: metadata(),
      context: ctx,
    ),
    GoalSavingTransferOperation(
      sourceAccountId: 'wallet',
      savingsAccountId: 'savings',
      goalId: 'goal-1',
      amount: Money.parse('30'),
      metadata: metadata(),
      context: ctx,
    ),
    GoalTransferOperation(
      sourceAccountId: 'wallet',
      savingsAccountId: 'savings',
      goalId: 'goal-1',
      amount: Money.parse('30'),
      metadata: metadata(),
      context: ctx,
    ),
    IncomeOperation(
      intent: IncomeIntent(
        sourceAccountId: 'wallet',
        amount: Money.parse('1000'),
        categoryId: 'salary',
        isExceptional: false,
        actorMemberId: 'owner',
      ),
      metadata: metadata(),
      context: ctx,
    ),
    OpeningBalanceOperation(
      intent: OpeningBalanceIntent(
        accountId: 'wallet',
        amount: Money.parse('100'),
        isLiability: false,
      ),
      metadata: metadata(),
      context: ctx,
    ),
    TransferOperation(
      intent: TransferIntent(
        fromAccountId: 'wallet',
        toAccountId: 'savings',
        amount: Money.parse('15'),
      ),
      metadata: metadata(),
      context: ctx,
    ),
  ];

  test('all supported operation types produce stable SHA-256 fingerprints', () {
    final ctx = context();
    final operations = allSupportedOperations(ctx);

    expect(operations, hasLength(13));

    for (final operation in operations) {
      final first = FinancialOperationFingerprint.compute(
        operation: operation,
        executionContext: ctx,
      );
      final second = FinancialOperationFingerprint.compute(
        operation: operation,
        executionContext: ctx,
      );

      expect(
        first,
        matches(RegExp(r'^[0-9a-f]{64}$')),
        reason: operation.runtimeType.toString(),
      );
      expect(second, first, reason: operation.runtimeType.toString());
    }
  });

  test(
    'same financial key with a changed expense amount changes fingerprint',
    () {
      final ctx = context();

      ExpenseOperation expense(Money amount) => ExpenseOperation(
        intent: ExpenseIntent(
          sourceAccountId: 'wallet',
          amount: amount,
          categoryId: 'dailyTransport',
          isExceptional: false,
          actorMemberId: 'owner',
        ),
        metadata: metadata(),
        context: ctx,
      );

      final first = FinancialOperationFingerprint.compute(
        operation: expense(Money.parse('100')),
        executionContext: ctx,
      );
      final changed = FinancialOperationFingerprint.compute(
        operation: expense(Money.parse('101')),
        executionContext: ctx,
      );

      expect(changed, isNot(first));
    },
  );

  test('metadata including null versus empty note affects fingerprint', () {
    final ctx = context();

    ExpenseOperation expense(String? note) => ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'wallet',
        amount: Money.parse('100'),
        categoryId: 'dailyTransport',
        isExceptional: false,
        actorMemberId: 'owner',
      ),
      metadata: metadata(note: note),
      context: ctx,
    );

    final withoutNote = FinancialOperationFingerprint.compute(
      operation: expense(null),
      executionContext: ctx,
    );
    final emptyNote = FinancialOperationFingerprint.compute(
      operation: expense(''),
      executionContext: ctx,
    );

    expect(emptyNote, isNot(withoutNote));
  });

  test('resolution participates in fingerprint', () {
    final ctx = context();
    final operation = ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'wallet',
        amount: Money.parse('100'),
        categoryId: 'dailyTransport',
        isExceptional: false,
        actorMemberId: 'owner',
      ),
      metadata: metadata(),
      context: ctx,
    );

    final executeFingerprint = FinancialOperationFingerprint.compute(
      operation: operation,
      executionContext: ctx,
    );
    final tempDebtFingerprint = FinancialOperationFingerprint.compute(
      operation: operation.resolve(Resolution.tempDebt),
      executionContext: ctx,
    );

    expect(tempDebtFingerprint, isNot(executeFingerprint));
  });

  test('external and internal idempotency keys must match', () {
    final internalContext = context(key: 'internal-key');
    final externalContext = context(key: 'external-key');
    final operation = ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'wallet',
        amount: Money.parse('100'),
        categoryId: 'dailyTransport',
        isExceptional: false,
        actorMemberId: 'owner',
      ),
      metadata: metadata(),
      context: internalContext,
    );

    expect(
      () => FinancialOperationFingerprint.compute(
        operation: operation,
        executionContext: externalContext,
      ),
      throwsArgumentError,
    );
  });

  test(
    'external execution context attribution participates in fingerprint',
    () {
      final operationContext = context();
      final operation = ExpenseOperation(
        intent: ExpenseIntent(
          sourceAccountId: 'wallet',
          amount: Money.parse('100'),
          categoryId: 'dailyTransport',
          isExceptional: false,
          actorMemberId: 'owner',
        ),
        metadata: metadata(),
        context: operationContext,
      );

      final original = FinancialOperationFingerprint.compute(
        operation: operation,
        executionContext: operationContext,
      );
      final changedAttribution = FinancialOperationFingerprint.compute(
        operation: operation,
        executionContext: context(source: 'scheduled'),
      );

      expect(changedAttribution, isNot(original));
    },
  );

  test('all optional execution context fields participate in fingerprint', () {
    final baseContext = context();

    ExpenseOperation expenseWithContext(ExecutionContext operationContext) =>
        ExpenseOperation(
          intent: ExpenseIntent(
            sourceAccountId: 'wallet',
            amount: Money.parse('100'),
            categoryId: 'dailyTransport',
            isExceptional: false,
            actorMemberId: 'owner',
          ),
          metadata: metadata(),
          context: operationContext,
        );

    String fingerprint({
      required ExecutionContext operationContext,
      required ExecutionContext executionContext,
    }) => FinancialOperationFingerprint.compute(
      operation: expenseWithContext(operationContext),
      executionContext: executionContext,
    );

    final baseline = fingerprint(
      operationContext: baseContext,
      executionContext: baseContext,
    );

    final operationContextVariants = <String, ExecutionContext>{
      'commitmentId': context(commitmentId: 'commitment-2'),
      'scheduleRuleId': context(scheduleRuleId: 'schedule-2'),
      'occurrenceId': context(occurrenceId: 'occurrence-2'),
      'actorMemberId': context(actorMemberId: 'another-member'),
      'source': context(source: 'scheduled'),
      'commandType': context(commandType: 'AnotherCommand'),
    };

    for (final entry in operationContextVariants.entries) {
      expect(
        fingerprint(
          operationContext: entry.value,
          executionContext: baseContext,
        ),
        isNot(baseline),
        reason:
            'Changing operation context ${entry.key} must change fingerprint',
      );
    }

    final executionContextVariants = <String, ExecutionContext>{
      'commitmentId': context(commitmentId: 'commitment-2'),
      'scheduleRuleId': context(scheduleRuleId: 'schedule-2'),
      'occurrenceId': context(occurrenceId: 'occurrence-2'),
      'actorMemberId': context(actorMemberId: 'another-member'),
      'source': context(source: 'scheduled'),
      'commandType': context(commandType: 'AnotherCommand'),
    };

    for (final entry in executionContextVariants.entries) {
      expect(
        fingerprint(
          operationContext: baseContext,
          executionContext: entry.value,
        ),
        isNot(baseline),
        reason:
            'Changing external context ${entry.key} must change fingerprint',
      );
    }
  });
}
