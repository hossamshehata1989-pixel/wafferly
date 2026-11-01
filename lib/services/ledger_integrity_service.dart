// lib/services/ledger_integrity_service.dart
// Internal diagnostics for persisted Ledger projection consistency.

import 'package:hive/hive.dart';
import '../constants/transaction_constants.dart';
import '../models/enums/entry_type.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import 'ledger_service.dart';

class LedgerIntegrityService {
  final LedgerService _ledgerService = LedgerService();

  Box<Transaction> get _txBox => Hive.box<Transaction>('transactions');

  Set<String> _correctionIds() {
    if (!Hive.isBoxOpen('financial_corrections')) return <String>{};
    return Hive.box<Map>(
      'financial_corrections',
    ).keys.map((key) => key.toString()).toSet();
  }

  Set<String> _invalidationIds() {
    if (!Hive.isBoxOpen('financial_invalidations')) return <String>{};
    return Hive.box<Map>(
      'financial_invalidations',
    ).keys.map((key) => key.toString()).toSet();
  }

  Set<String> _correctedTransactionIds() {
    if (!Hive.isBoxOpen('financial_corrections')) return <String>{};

    final correctedIds = <String>{};
    for (final correction in Hive.box<Map>('financial_corrections').values) {
      final after = correction['after'];
      if (after is Map && after['transactionId'] is String) {
        correctedIds.add(after['transactionId'] as String);
      }
    }
    return correctedIds;
  }

  /// Detects incomplete or duplicated Ledger projection groups.
  ///
  /// A regular transaction and an invalidation each project two entries.
  /// A correction projects four entries: two reversal entries plus two entries
  /// for the corrected truth. Correction/invalidation IDs are resolved from
  /// their persisted write-model boxes rather than mistaken for Transaction IDs.
  Future<List<String>> getDuplicateTransactionIds() async {
    final allEntries = await _ledgerService.getAllEntries();
    final correctionIds = _correctionIds();
    final entriesByProjectionId = <String, List<LedgerEntry>>{};

    for (final entry in allEntries) {
      entriesByProjectionId
          .putIfAbsent(entry.transactionId, () => <LedgerEntry>[])
          .add(entry);
    }

    final issues = <String>[];
    entriesByProjectionId.forEach((projectionId, entries) {
      final expectedCount = correctionIds.contains(projectionId) ? 4 : 2;
      final debitEntries = entries
          .where((entry) => entry.entryType == EntryType.debit)
          .toList(growable: false);
      final creditEntries = entries
          .where((entry) => entry.entryType == EntryType.credit)
          .toList(growable: false);
      final debitTotal = debitEntries.fold<double>(
        0,
        (total, entry) => total + entry.amount,
      );
      final creditTotal = creditEntries.fold<double>(
        0,
        (total, entry) => total + entry.amount,
      );

      final hasValidLineCounts =
          debitEntries.isNotEmpty &&
          creditEntries.isNotEmpty &&
          debitEntries.length == creditEntries.length;
      final hasValidAmounts = entries.every(
        (entry) => entry.amount.isFinite && entry.amount >= 0,
      );
      final hasValidAccounts = entries.every(
        (entry) => entry.accountId.trim().isNotEmpty,
      );
      final isBalanced = (debitTotal - creditTotal).abs() <= 0.000001;
      if (entries.length != expectedCount ||
          !hasValidLineCounts ||
          !hasValidAmounts ||
          !hasValidAccounts ||
          !isBalanced) {
        issues.add(
          '$projectionId: ${entries.length} entries (expected $expectedCount), '
          'debit=$debitTotal, credit=$creditTotal',
        );
      }
    });

    for (final correctionId in correctionIds) {
      if (!entriesByProjectionId.containsKey(correctionId)) {
        issues.add(
          '$correctionId: 0 entries (expected 4), debit=0.0, credit=0.0',
        );
      }
    }
    for (final invalidationId in _invalidationIds()) {
      if (!entriesByProjectionId.containsKey(invalidationId)) {
        issues.add(
          '$invalidationId: 0 entries (expected 2), debit=0.0, credit=0.0',
        );
      }
    }

    issues.addAll(_missingWriteModelTransactionReferences());
    return issues;
  }

  /// Verifies that correction and invalidation write models still reference
  /// the immutable transaction snapshots they preserve.
  List<String> _missingWriteModelTransactionReferences() {
    final issues = <String>[];

    if (Hive.isBoxOpen('financial_corrections')) {
      final box = Hive.box<Map>('financial_corrections');
      for (final key in box.keys) {
        final value = box.get(key);
        if (value == null) continue;

        final correctionId = value['correctionId'] is String
            ? value['correctionId'] as String
            : key.toString();
        final originalTransactionId = value['originalTransactionId'];
        final after = value['after'];
        final correctedTransactionId = after is Map
            ? after['transactionId']
            : null;

        if (originalTransactionId is! String ||
            originalTransactionId.trim().isEmpty) {
          issues.add(
            '$correctionId: original transaction reference is missing.',
          );
        } else if (!_txBox.containsKey(originalTransactionId)) {
          issues.add(
            '$correctionId: original transaction '
            '"$originalTransactionId" is missing.',
          );
        }

        if (correctedTransactionId is! String ||
            correctedTransactionId.trim().isEmpty) {
          issues.add(
            '$correctionId: corrected transaction reference is missing.',
          );
        } else if (!_txBox.containsKey(correctedTransactionId)) {
          issues.add(
            '$correctionId: corrected transaction '
            '"$correctedTransactionId" is missing.',
          );
        }
      }
    }

    if (Hive.isBoxOpen('financial_invalidations')) {
      final box = Hive.box<Map>('financial_invalidations');
      for (final key in box.keys) {
        final value = box.get(key);
        if (value == null) continue;

        final invalidationId = value['invalidationId'] is String
            ? value['invalidationId'] as String
            : key.toString();
        final originalTransactionId = value['originalTransactionId'];

        if (originalTransactionId is! String ||
            originalTransactionId.trim().isEmpty) {
          issues.add(
            '$invalidationId: original transaction reference is missing.',
          );
        } else if (!_txBox.containsKey(originalTransactionId)) {
          issues.add(
            '$invalidationId: original transaction '
            '"$originalTransactionId" is missing.',
          );
        }
      }
    }

    return issues;
  }

  /// Detects Ledger entries whose transaction or projection record is missing.
  Future<List<LedgerEntry>> getOrphanLedgerEntries() async {
    final allEntries = await _ledgerService.getAllEntries();
    final correctionIds = _correctionIds();
    final invalidationIds = _invalidationIds();
    final orphans = <LedgerEntry>[];

    for (final entry in allEntries) {
      final belongsToTransaction = _txBox.containsKey(entry.transactionId);
      final belongsToCorrection = correctionIds.contains(entry.transactionId);
      final belongsToInvalidation = invalidationIds.contains(
        entry.transactionId,
      );

      if (!belongsToTransaction &&
          !belongsToCorrection &&
          !belongsToInvalidation) {
        orphans.add(entry);
      }
    }

    return orphans;
  }

  /// Detects supported financial transactions that have no Ledger projection.
  Future<List<Transaction>> getTransactionsWithoutLedgerEntries() async {
    final allEntries = await _ledgerService.getAllEntries();
    final transactionIdsWithEntries = <String>{
      for (final entry in allEntries) entry.transactionId,
    };
    final correctedTransactionIds = _correctedTransactionIds();

    const supportedTypes = <String>{
      TransactionType.expense,
      TransactionType.income,
      TransactionType.transfer,
      TransactionType.creditCardCharge,
      TransactionType.initialBalance,
      TransactionType.balanceReconciliation,
    };

    return _txBox.values
        .where((transaction) {
          if (!supportedTypes.contains(transaction.type)) return false;
          // Corrected truth is projected under its correction ID so that the
          // reversal and replacement remain one rollback-safe projection group.
          if (correctedTransactionIds.contains(transaction.id)) return false;
          return !transactionIdsWithEntries.contains(transaction.id);
        })
        .toList(growable: false);
  }

  /// Full consistency validation.
  Future<IntegrityReport> runFullValidation() async {
    final startTime = DateTime.now();
    final duplicates = await getDuplicateTransactionIds();
    final orphans = await getOrphanLedgerEntries();
    final missing = await getTransactionsWithoutLedgerEntries();
    final endTime = DateTime.now();

    return IntegrityReport(
      duplicateTransactionIssues: duplicates,
      orphanLedgerEntries: orphans,
      transactionsWithoutLedger: missing,
      totalLedgerEntries: (await _ledgerService.getAllEntries()).length,
      totalTransactions: _txBox.values.length,
      validationDurationMs: endTime.difference(startTime).inMilliseconds,
    );
  }

  /// Console report printer (internal diagnostics only).
  Future<void> printValidationReport() async {
    final report = await runFullValidation();

    print('\n${'=' * 60}');
    print('LEDGER PROJECTION INTEGRITY REPORT');
    print('=' * 60);
    print('Total Transactions: ${report.totalTransactions}');
    print('Total Ledger Entries: ${report.totalLedgerEntries}');
    print('Validation Time: ${report.validationDurationMs} ms');
    print('-' * 60);

    if (report.duplicateTransactionIssues.isEmpty) {
      print('No incomplete or duplicated projection groups found.');
    } else {
      print('PROJECTION GROUP ISSUES:');
      for (final issue in report.duplicateTransactionIssues) {
        print(' - $issue');
      }
    }

    if (report.orphanLedgerEntries.isEmpty) {
      print('No orphan Ledger entries found.');
    } else {
      print('ORPHAN LEDGER ENTRIES (${report.orphanLedgerEntries.length}):');
      for (final entry in report.orphanLedgerEntries.take(5)) {
        print(
          ' - Entry ${entry.id} -> missing transaction/projection '
          '${entry.transactionId}',
        );
      }
      if (report.orphanLedgerEntries.length > 5) {
        print(' ... and ${report.orphanLedgerEntries.length - 5} more');
      }
    }

    if (report.transactionsWithoutLedger.isEmpty) {
      print('All supported transactions have Ledger projections.');
    } else {
      print(
        'TRANSACTIONS WITHOUT LEDGER ENTRIES '
        '(${report.transactionsWithoutLedger.length}):',
      );
      for (final transaction in report.transactionsWithoutLedger.take(5)) {
        print(
          ' - Transaction ${transaction.id} '
          '(${transaction.type}, ${transaction.amount} ${transaction.currencyCode})',
        );
      }
      if (report.transactionsWithoutLedger.length > 5) {
        print(' ... and ${report.transactionsWithoutLedger.length - 5} more');
      }
    }

    print('=' * 60);
    print('Ledger projection integrity check completed.\n');
  }
}

class IntegrityReport {
  final List<String> duplicateTransactionIssues;
  final List<LedgerEntry> orphanLedgerEntries;
  final List<Transaction> transactionsWithoutLedger;
  final int totalLedgerEntries;
  final int totalTransactions;
  final int validationDurationMs;

  IntegrityReport({
    required this.duplicateTransactionIssues,
    required this.orphanLedgerEntries,
    required this.transactionsWithoutLedger,
    required this.totalLedgerEntries,
    required this.totalTransactions,
    required this.validationDurationMs,
  });
}
