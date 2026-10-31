import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/domain/financial_correction_record.dart';
import 'package:wafferly/financial_engine/domain/financial_invalidation_record.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/handlers/create_correction_mutation_handler.dart';
import 'package:wafferly/financial_engine/handlers/invalidate_transaction_mutation_handler.dart';
import 'package:wafferly/financial_engine/memory/memory_correction_port.dart';
import 'package:wafferly/financial_engine/memory/memory_invalidation_port.dart';
import 'package:wafferly/financial_engine/mutations/create_correction_mutation.dart';
import 'package:wafferly/financial_engine/mutations/invalidate_transaction_mutation.dart';
import 'package:wafferly/financial_engine/ports/transaction_port.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/ports/ledger_port.dart';
import 'package:wafferly/services/ledger_projection_service.dart';

/// M2.3-B4: a Ledger projection that fails halfway through persistence must
/// leave no partial entries behind, and a retry must project the full set.
///
/// Before B4 the projection rollback was registered only AFTER the projection
/// returned, so a partial write was never cleaned up and the retry saw
/// `_alreadyProjected == true` and skipped the missing entries.
void main() {
  const unitOfWork = MemoryFinancialUnitOfWork();

  group('correction projection', () {
    test(
      'partial ledger write is rolled back and the retry projects the full set',
      () async {
        final ledgerPort = _PartialLedgerPort(failAfterWriting: 1);
        final correctionPort = MemoryCorrectionPort();
        final transactionPort = _FakeTransactionPort();
        final handler = CreateCorrectionMutationHandler(
          correctionPort: correctionPort,
          transactionPort: transactionPort,
          ledgerProjectionService: LedgerProjectionService(
            ledgerPort: ledgerPort,
          ),
        );
        final record = _correction('correction-b4-001');

        await expectLater(
          unitOfWork.execute((context) async {
            await handler.execute(
              CreateCorrectionMutation(record: record),
              context,
            );
          }),
          throwsA(isA<StateError>()),
        );

        expect(
          ledgerPort.entries,
          isEmpty,
          reason: 'Entries written before the failure must be removed.',
        );
        expect(correctionPort.records, isEmpty);
        expect(transactionPort.transactions, isEmpty);

        // Retry with a healthy ledger: the whole projection must exist, not
        // be skipped because a partial leftover looked "already projected".
        ledgerPort.failAfterWriting = null;

        await unitOfWork.execute((context) async {
          await handler.execute(
            CreateCorrectionMutation(record: record),
            context,
          );
        });

        // Transfer: 2 reversal entries + 2 corrected entries.
        expect(ledgerPort.entries, hasLength(4));
        expect(
          await ledgerPort.getEntriesByTransactionId(record.correctionId),
          hasLength(4),
        );
        expect(correctionPort.records, hasLength(1));
        expect(
          transactionPort.transactions.keys,
          contains(record.after.transactionId),
        );
      },
    );

    test(
      'rollback is safe when the projection failed before writing anything',
      () async {
        final ledgerPort = _PartialLedgerPort(failAfterWriting: 0);
        final handler = CreateCorrectionMutationHandler(
          correctionPort: MemoryCorrectionPort(),
          transactionPort: _FakeTransactionPort(),
          ledgerProjectionService: LedgerProjectionService(
            ledgerPort: ledgerPort,
          ),
        );

        await expectLater(
          unitOfWork.execute((context) async {
            await handler.execute(
              CreateCorrectionMutation(record: _correction('correction-b4-002')),
              context,
            );
          }),
          throwsA(isA<StateError>()),
        );

        expect(ledgerPort.entries, isEmpty);
      },
    );
  });

  group('invalidation projection', () {
    test(
      'partial ledger write is rolled back and the retry projects the full set',
      () async {
        final ledgerPort = _PartialLedgerPort(failAfterWriting: 1);
        final invalidationPort = MemoryInvalidationPort();
        final handler = InvalidateTransactionMutationHandler(
          invalidationPort: invalidationPort,
          ledgerProjectionService: LedgerProjectionService(
            ledgerPort: ledgerPort,
          ),
        );
        final record = _invalidation('invalidation-b4-001');

        await expectLater(
          unitOfWork.execute((context) async {
            await handler.execute(
              InvalidateTransactionMutation(record: record),
              context,
            );
          }),
          throwsA(isA<StateError>()),
        );

        expect(
          ledgerPort.entries,
          isEmpty,
          reason: 'Entries written before the failure must be removed.',
        );
        expect(invalidationPort.records, isEmpty);

        ledgerPort.failAfterWriting = null;

        await unitOfWork.execute((context) async {
          await handler.execute(
            InvalidateTransactionMutation(record: record),
            context,
          );
        });

        // Transfer reversal: debit + credit.
        expect(ledgerPort.entries, hasLength(2));
        expect(
          await ledgerPort.getEntriesByTransactionId(record.invalidationId),
          hasLength(2),
        );
        expect(invalidationPort.records, hasLength(1));
      },
    );
  });
}

FinancialTransactionRecord _transfer(String id, double amount) {
  return FinancialTransactionRecord(
    transactionId: id,
    type: TransactionType.transfer,
    fromAccountId: 'wallet-source',
    toAccountId: 'wallet-target',
    amount: Money.fromDouble(amount),
    currencyCode: 'EGP',
    paymentMethod: 'cash',
    occurredAt: DateTime(2026, 1, 2),
    isExceptional: false,
    source: 'manual',
  );
}

FinancialCorrectionRecord _correction(String correctionId) {
  return FinancialCorrectionRecord(
    correctionId: correctionId,
    originalTransactionId: 'b4-original-transfer',
    before: _transfer('b4-original-transfer', 25),
    after: _transfer('corrected-$correctionId', 30),
  );
}

FinancialInvalidationRecord _invalidation(String invalidationId) {
  final original = _transfer('b4-original-transfer', 25);
  return FinancialInvalidationRecord(
    invalidationId: invalidationId,
    originalTransactionId: original.transactionId,
    before: original,
  );
}

/// Persists the first [failAfterWriting] entries of a batch and then throws,
/// simulating a non-atomic write that fails halfway. `null` means healthy.
final class _PartialLedgerPort implements LedgerPort {
  _PartialLedgerPort({required this.failAfterWriting});

  int? failAfterWriting;
  final List<LedgerEntry> entries = [];

  @override
  Future<void> createEntries(List<LedgerEntry> newEntries) async {
    final limit = failAfterWriting;
    if (limit == null) {
      entries.addAll(newEntries);
      return;
    }

    entries.addAll(newEntries.take(limit));
    throw StateError('Simulated partial ledger write failure');
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
