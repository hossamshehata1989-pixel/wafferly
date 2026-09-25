import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/execution/default_financial_executor.dart';
import 'package:wafferly/financial_engine/execution/financial_transaction_context.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/execution/mutation_handler_registry.dart';
import 'package:wafferly/financial_engine/handlers/create_transaction_mutation_handler.dart';
import 'package:wafferly/financial_engine/mutations/create_transaction_mutation.dart';
import 'package:wafferly/financial_engine/planning/financial_execution_plan.dart';
import 'package:wafferly/financial_engine/planning/financial_mutation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/financial_engine/ports/transaction_port.dart';
import 'package:wafferly/ports/ledger_port.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/services/ledger_projection_service.dart';
import 'package:wafferly/financial_engine/execution/financial_mutation_handler.dart';
void main() {
  test(
    'transaction and ledger projection are both rolled back '
    'when a later mutation fails',
    () async {
      final transactionPort = _FakeTransactionPort();
      final ledgerPort = _FakeLedgerPort();

      final ledgerProjectionService = LedgerProjectionService(
        ledgerPort: ledgerPort,
      );

      final createTransactionHandler = CreateTransactionMutationHandler(
        transactionPort,
        ledgerProjectionService,
      );

      const failingHandler = _FailingMutationHandler();

      final registry = MutationHandlerRegistry(
        handlers: {
          CreateTransactionMutation: createTransactionHandler,
          _FailingMutation: failingHandler,
        },
      );

      final executor = DefaultFinancialExecutor(
        registry: registry,
        unitOfWork: const MemoryFinancialUnitOfWork(),
      );

      final record = FinancialTransactionRecord(
        transactionId: 'rollback-tx-001',
        type: 'transfer',
        fromAccountId: 'cash',
        toAccountId: 'wallet',
        amount: Money.fromDouble(100),
        currencyCode: 'EGP',
        paymentMethod: 'cash',
        occurredAt: DateTime(2026, 9, 21),
        isExceptional: false,
        source: 'test',
      );

      final plan = FinancialExecutionPlan(
        planId: 'rollback-plan-001',
        operationId: 'rollback-operation-001',
        idempotencyKey: 'rollback-key-001',
        mutations: [
          CreateTransactionMutation(record: record),
          const _FailingMutation(),
        ],
      );

      final result = await executor.execute(plan);

      expect(result, isA<OperationFailed>());

      expect(
        ledgerPort.createEntriesCalled,
        1,
        reason: 'Ledger projection must be created before the later mutation fails.',
      );

      expect(
        ledgerPort.entriesCreated,
        2,
        reason: 'Transfer projection must create both debit and credit entries.',
      );

      expect(
        transactionPort.transactions,
        isEmpty,
        reason: 'Transaction must be deleted during rollback.',
      );

      expect(
        await ledgerPort.getEntriesByTransactionId(
          record.transactionId,
        ),
        isEmpty,
        reason: 'Ledger projection must be deleted during rollback.',
      );
    },
  );
}

final class _FailingMutation extends FinancialMutation {
  const _FailingMutation();
}

final class _FailingMutationHandler
    implements FinancialMutationHandler<_FailingMutation> {
  const _FailingMutationHandler();

  @override
  Future<void> execute(
    _FailingMutation mutation,
    FinancialTransactionContext context,
  ) async {
    throw StateError('Simulated mutation failure');
  }
}

final class _FakeTransactionPort implements TransactionPort {
  final Map<String, FinancialTransactionRecord> transactions = {};

  @override
  Future<void> save(FinancialTransactionRecord record) async {
    transactions[record.transactionId] = record;
  }

  @override
  Future<void> delete(String transactionId) async {
    transactions.remove(transactionId);
  }
}

final class _FakeLedgerPort implements LedgerPort {
  final List<LedgerEntry> entries = [];
  int createEntriesCalled = 0;
  int entriesCreated = 0;

  @override
  Future<void> createEntries(List<LedgerEntry> newEntries) async {
    createEntriesCalled++;
    entriesCreated += newEntries.length;
    entries.addAll(newEntries);
  }

  @override
  Future<List<LedgerEntry>> getEntriesByTransactionId(
    String transactionId,
  ) async {
    return entries
        .where(
          (entry) => entry.transactionId == transactionId,
        )
        .toList();
  }

  @override
  Future<void> deleteEntriesByTransactionId(
    String transactionId,
  ) async {
    entries.removeWhere(
      (entry) => entry.transactionId == transactionId,
    );
  }
}