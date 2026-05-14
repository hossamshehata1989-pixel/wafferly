// lib/services/ledger_integrity_service.dart
// Sprint 4A — Runtime Validation & Data Integrity
// ⚠️ INTERNAL USE ONLY – ليس جزءاً من UI أو production flow
// يستخدم فقط للاختبار والتحقق من صحة البيانات في console

import 'package:hive/hive.dart';
import '../models/ledger_entry.dart';
import '../models/transaction.dart';
import 'ledger_service.dart';

class LedgerIntegrityService {
  final LedgerService _ledgerService = LedgerService();
  
  Box<Transaction> get _txBox => Hive.box<Transaction>('transactions');

  /// ============================================================
  /// 🔍 Detect duplicate ledger entries for same transaction
  /// ============================================================
  Future<List<String>> getDuplicateTransactionIds() async {
    final allEntries = await _ledgerService.getAllEntries();
    final Map<String, int> txCount = {};
    
    for (final entry in allEntries) {
      txCount[entry.transactionId] = (txCount[entry.transactionId] ?? 0) + 1;
    }
    
    final duplicates = <String>[];
    txCount.forEach((txId, count) {
      // Each transaction should have exactly 2 ledger entries (debit + credit)
      if (count != 2) {
        duplicates.add("$txId: $count entries (expected 2)");
      }
    });
    
    return duplicates;
  }

  /// ============================================================
  /// 🔍 Detect orphan ledger entries (transaction not found)
  /// ============================================================
  Future<List<LedgerEntry>> getOrphanLedgerEntries() async {
    final allEntries = await _ledgerService.getAllEntries();
    final orphans = <LedgerEntry>[];
    
    for (final entry in allEntries) {
      final tx = _txBox.get(entry.transactionId);
      if (tx == null) {
        orphans.add(entry);
      }
    }
    
    return orphans;
  }

  /// ============================================================
  /// 🔍 Detect transactions without ledger entries
  /// ============================================================
  Future<List<Transaction>> getTransactionsWithoutLedgerEntries() async {
    final allEntries = await _ledgerService.getAllEntries();
    final Set<String> txWithEntries = {};
    
    for (final entry in allEntries) {
      txWithEntries.add(entry.transactionId);
    }
    
    final missing = <Transaction>[];
    for (final tx in _txBox.values) {
      if (!txWithEntries.contains(tx.id) && 
          (tx.type == 'expense' || tx.type == 'income' || tx.type == 'transfer')) {
        missing.add(tx);
      }
    }
    
    return missing;
  }

  /// ============================================================
  /// 🔍 Full consistency validation
  /// ============================================================
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

  /// ============================================================
  /// 🖨️ Console report printer (testing only)
  /// ============================================================
  Future<void> printValidationReport() async {
    final report = await runFullValidation();
    
    print("\n" + "=" * 60);
    print("🔍 LEDGER INTEGRITY REPORT (Sprint 4A)");
    print("=" * 60);
    print("📊 Total Transactions: ${report.totalTransactions}");
    print("📊 Total Ledger Entries: ${report.totalLedgerEntries}");
    print("⏱️ Validation Time: ${report.validationDurationMs} ms");
    print("-" * 60);
    
    if (report.duplicateTransactionIssues.isEmpty) {
      print("✅ No duplicate transaction entries found.");
    } else {
      print("⚠️ DUPLICATE TRANSACTION ISSUES:");
      for (final issue in report.duplicateTransactionIssues) {
        print("   - $issue");
      }
    }
    
    if (report.orphanLedgerEntries.isEmpty) {
      print("✅ No orphan ledger entries found.");
    } else {
      print("⚠️ ORPHAN LEDGER ENTRIES (${report.orphanLedgerEntries.length}):");
      for (final entry in report.orphanLedgerEntries.take(5)) {
        print("   - Entry ${entry.id} -> missing transaction ${entry.transactionId}");
      }
      if (report.orphanLedgerEntries.length > 5) {
        print("   ... and ${report.orphanLedgerEntries.length - 5} more");
      }
    }
    
    if (report.transactionsWithoutLedger.isEmpty) {
      print("✅ All transactions have corresponding ledger entries.");
    } else {
      print("⚠️ TRANSACTIONS WITHOUT LEDGER ENTRIES (${report.transactionsWithoutLedger.length}):");
      for (final tx in report.transactionsWithoutLedger.take(5)) {
        print("   - Transaction ${tx.id} (${tx.type}, ${tx.amount} EGP)");
      }
      if (report.transactionsWithoutLedger.length > 5) {
        print("   ... and ${report.transactionsWithoutLedger.length - 5} more");
      }
    }
    
    print("=" * 60);
    print("✅ Integrity check completed.\n");
  }
}

/// ============================================================
/// 📋 Report data class
/// ============================================================
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