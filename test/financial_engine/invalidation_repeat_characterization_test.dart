import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/domain/financial_invalidation_record.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/handlers/invalidate_transaction_mutation_handler.dart';
import 'package:wafferly/financial_engine/memory/memory_invalidation_port.dart';
import 'package:wafferly/financial_engine/mutations/invalidate_transaction_mutation.dart';
import 'package:wafferly/ports/ledger_port.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/services/ledger_projection_service.dart';

void main() {
  test(
    'repeating the same invalidation is a no-op, while a different invalidation ID for the same transaction is rejected',
    () async {
      final invalidationPort = MemoryInvalidationPort();
      final ledgerPort = _MemoryLedgerPort();
      final handler = InvalidateTransactionMutationHandler(
        invalidationPort: invalidationPort,
        ledgerProjectionService: LedgerProjectionService(ledgerPort: ledgerPort),
      );
      const unitOfWork = MemoryFinancialUnitOfWork();
      final firstRecord = _invalidation('invalidation-001');

      await unitOfWork.execute((context) async {
        await handler.execute(
          InvalidateTransactionMutation(record: firstRecord),
          context,
        );
      });

      expect(invalidationPort.records, hasLength(1));
      expect(ledgerPort.entries, isNotEmpty);
      final entryCountAfterFirst = ledgerPort.entries.length;

      // Characterize the existing guard: retrying the same record returns
      // without writing another invalidation or another ledger projection.
      await unitOfWork.execute((context) async {
        await handler.execute(
          InvalidateTransactionMutation(record: firstRecord),
          context,
        );
      });

      expect(invalidationPort.records, hasLength(1));
      expect(ledgerPort.entries, hasLength(entryCountAfterFirst));

      // A different event identity for an already-invalidated original is
      // rejected rather than silently treated as the same request.
      await expectLater(
        unitOfWork.execute((context) async {
          await handler.execute(
            InvalidateTransactionMutation(
              record: _invalidation('invalidation-002'),
            ),
            context,
          );
        }),
        throwsA(isA<StateError>()),
      );
      expect(invalidationPort.records, hasLength(1));
      expect(ledgerPort.entries, hasLength(entryCountAfterFirst));
    },
  );
}

FinancialInvalidationRecord _invalidation(String invalidationId) {
  final original = FinancialTransactionRecord(
    transactionId: 'txn-original-transfer',
    type: TransactionType.transfer,
    fromAccountId: 'wallet-source',
    toAccountId: 'wallet-target',
    amount: Money.fromDouble(25),
    currencyCode: 'EGP',
    paymentMethod: 'cash',
    occurredAt: DateTime(2026, 1, 2),
    isExceptional: false,
    source: 'manual',
  );

  return FinancialInvalidationRecord(
    invalidationId: invalidationId,
    originalTransactionId: original.transactionId,
    before: original,
  );
}

final class _MemoryLedgerPort implements LedgerPort {
  final List<LedgerEntry> entries = [];

  @override
  Future<void> createEntries(List<LedgerEntry> newEntries) async {
    entries.addAll(newEntries);
  }

  @override
  Future<List<LedgerEntry>> getEntriesByTransactionId(
    String transactionId,
  ) async {
    return entries
        .where((entry) => entry.transactionId == transactionId)
        .toList(growable: false);
  }

  @override
  Future<void> deleteEntriesByTransactionId(String transactionId) async {
    entries.removeWhere((entry) => entry.transactionId == transactionId);
  }
}
