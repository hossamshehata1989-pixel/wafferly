import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/interpretation/default_financial_interpreter.dart';
import 'package:wafferly/financial_engine/interpretation/financial_action_type.dart';
import 'package:wafferly/financial_engine/mutations/create_transaction_mutation.dart';
import 'package:wafferly/financial_engine/mutations/journal_entry_mutation.dart';
import 'package:wafferly/financial_engine/operations/commitment_payment_operation.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';
import 'package:wafferly/financial_engine/planning/default_financial_planner.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/core/money/money.dart';

void main() {
  test('commitment payment flows from operation to transfer plan', () async {
    final occurredAt = DateTime(2026, 9, 12, 10, 30);
    const executionContext = ExecutionContext(
      idempotencyKey: 'commitment-payment-1',
    );

    final operation = CommitmentPaymentOperation(
      sourceAccountId: 'cash-account',
      liabilityAccountId: 'loan-account',
      commitmentId: 'commitment-1',
      amount: 250.50,
      metadata: TransactionMetadata(
        occurredAt: occurredAt,
        note: 'September installment',
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: executionContext,
    );

    final intent = const DefaultFinancialInterpreter().interpret(operation);

    expect(intent.action, FinancialActionType.commitmentPayment);
    expect(intent.sourceAccountId, 'cash-account');
    expect(intent.destinationAccountId, 'loan-account');
    expect(intent.amount, 250.50);

    final planner = DefaultFinancialPlanner(
      chartOfAccounts: const ChartOfAccounts(),
    );
    final plan = await planner.build(
      operation.createPlanningContext(
        intent: intent,
        constraints: const [],
      ),
    );

    expect(plan.idempotencyKey, 'commitment-payment-1');

    final transaction = plan.mutations
        .whereType<CreateTransactionMutation>()
        .single
        .record;
    final journal = plan.mutations
        .whereType<JournalEntryMutation>()
        .single;

    expect(transaction.type, TransactionType.transfer);
    expect(transaction.fromAccountId, 'cash-account');
    expect(transaction.toAccountId, 'loan-account');
    expect(transaction.categoryId, isNull);
    expect(transaction.amount, Money.fromDouble(250.50));
    expect(transaction.source, TransactionSource.scheduled);
    expect(transaction.occurredAt, occurredAt);
    expect(transaction.note, 'September installment');
    expect(transaction.currencyCode, 'EGP');
    expect(transaction.paymentMethod, 'cash');

    expect(journal.description, 'Commitment Payment');
    expect(journal.lines.length, 2);
    expect(journal.lines[0].accountId, 'loan-account');
    expect(journal.lines[0].debit, 250.50);
    expect(journal.lines[0].credit, 0);
    expect(journal.lines[1].accountId, 'cash-account');
    expect(journal.lines[1].debit, 0);
    expect(journal.lines[1].credit, 250.50);
  });

  test('commitment payment resolution preserves all operation data', () {
    const context = ExecutionContext(idempotencyKey: 'commitment-payment-2');
    final operation = CommitmentPaymentOperation(
      sourceAccountId: 'cash-account',
      liabilityAccountId: 'loan-account',
      commitmentId: 'commitment-2',
      amount: 100,
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 9, 12),
        paymentMethod: 'bank',
        currencyCode: 'EGP',
      ),
      context: context,
    );

    final resolved = operation.resolve(Resolution.execute);

    expect(resolved.sourceAccountId, operation.sourceAccountId);
    expect(resolved.liabilityAccountId, operation.liabilityAccountId);
    expect(resolved.commitmentId, operation.commitmentId);
    expect(resolved.amount, operation.amount);
    expect(resolved.metadata, same(operation.metadata));
    expect(resolved.context, same(operation.context));
    expect(resolved.resolution, isNotNull);
  });
}
