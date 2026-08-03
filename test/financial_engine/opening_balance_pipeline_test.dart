import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/financial_engine/commands/opening_balance/opening_balance_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/domain_guard/balance_domain_guard.dart';
import 'package:wafferly/financial_engine/domain_guard/domain_guard_result.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/interpretation/default_financial_interpreter.dart';
import 'package:wafferly/financial_engine/interpretation/financial_action_type.dart';
import 'package:wafferly/financial_engine/mutations/create_transaction_mutation.dart';
import 'package:wafferly/financial_engine/mutations/journal_entry_mutation.dart';
import 'package:wafferly/financial_engine/operations/opening_balance_operation.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';
import 'package:wafferly/financial_engine/planning/default_financial_planner.dart';
import 'package:wafferly/financial_engine/ports/balance_port.dart';
import 'package:wafferly/financial_engine/ports/transaction_lookup_port.dart';

final class _NoopBalancePort implements BalancePort {
  @override
  Future<double> availableBalance(String accountId) async {
    return 0;
  }
}

final class _NoopTransactionLookupPort implements TransactionLookupPort {
  @override
  Future<FinancialTransactionRecord?> findById(String transactionId) async {
    return null;
  }
}

void main() {
  test(
    'zero opening balance still creates a genesis journal and transaction',
    () async {
      final occurredAt = DateTime(2026, 8, 3);
      const context = ExecutionContext(
        idempotencyKey: 'opening-balance-account-1',
      );
      final operation = OpeningBalanceOperation(
        intent: const OpeningBalanceIntent(
          accountId: 'account-1',
          amount: 0,
          isLiability: false,
        ),
        metadata: TransactionMetadata(
          occurredAt: occurredAt,
          note: 'Initial balance',
          paymentMethod: 'cash',
          currencyCode: 'EGP',
        ),
        context: context,
      );

      final intent = const DefaultFinancialInterpreter().interpret(operation);

      expect(intent.action, FinancialActionType.openingBalance);
      expect(intent.amount, 0);

      final planner = DefaultFinancialPlanner(
        chartOfAccounts: const ChartOfAccounts(),
        transactionLookupPort: _NoopTransactionLookupPort(),
      );
      final plan = await planner.build(
        operation.createPlanningContext(intent: intent, constraints: const []),
      );

      final journal = plan.mutations.whereType<JournalEntryMutation>().single;
      final transaction = plan.mutations
          .whereType<CreateTransactionMutation>()
          .single
          .record;

      expect(journal.description, 'Opening Balance');
      expect(journal.lines.length, 2);
      expect(journal.lines.first.accountId, 'account-1');
      expect(journal.lines.first.debit, 0);
      expect(
        journal.lines.last.accountId,
        ChartOfAccounts.openingBalanceEquityAccountId,
      );
      expect(journal.lines.last.credit, 0);

      expect(transaction.type, TransactionType.initialBalance);
      expect(transaction.amount, 0);
      expect(transaction.toAccountId, 'account-1');
      expect(transaction.fromAccountId, isNull);
      expect(transaction.source, TransactionSource.accountCreation);
      expect(transaction.occurredAt, occurredAt);
    },
  );

  test(
    'negative opening balance is preserved and rejected by domain guard',
    () async {
      const context = ExecutionContext(
        idempotencyKey: 'opening-balance-negative-account',
      );
      final operation = OpeningBalanceOperation(
        intent: const OpeningBalanceIntent(
          accountId: 'account-1',
          amount: -10,
          isLiability: false,
        ),
        metadata: TransactionMetadata(
          occurredAt: DateTime(2026, 8, 3),
          paymentMethod: 'cash',
          currencyCode: 'EGP',
        ),
        context: context,
      );

      final intent = const DefaultFinancialInterpreter().interpret(operation);
      final result = await BalanceDomainGuard(
        balancePort: _NoopBalancePort(),
      ).validate(intent);

      expect(intent.amount, -10);
      expect(result, isA<DomainViolation>());
    },
  );
}
