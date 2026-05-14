// lib/services/ledger_stress_test_service.dart
// Sprint 4B — Ledger Stress Simulator
// ⚠️ INTERNAL TESTING ONLY – لا يتم ربطه بأي UI production
// يستخدم فقط لاختبار تحمل واستقرار Ledger Engine تحت ضغط عالٍ

import 'dart:math';
import 'package:hive/hive.dart';
import '../constants/transaction_constants.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../config/category_config.dart';
import 'transaction_service.dart';
import 'ledger_integrity_service.dart';

class LedgerStressTestService {
  final TransactionService _txService = TransactionService.instance;  // ✅ تم التصحيح
  final LedgerIntegrityService _integrityService = LedgerIntegrityService();
  final Random _random = Random();
  
  Box<Account> get _accountsBox => Hive.box<Account>('accounts');
  
  // ============================================================
  // 🧪 Generate random test data
  // ============================================================
  
  List<String> get _availableAccountIds {
    return _accountsBox.values
        .where((a) => !a.isArchived)
        .map((a) => a.id)
        .toList();
  }
  
  List<String> get _expenseCategoryIds {
    return expenseCategories.map((c) => c.id).toList();
  }
  
  List<String> get _incomeCategoryIds {
    return incomeCategories.map((c) => c.id).toList();
  }
  
  double _randomAmount() {
    return (_random.nextInt(5000) + 10).toDouble();
  }
  
  DateTime _randomDate() {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(90);
    return now.subtract(Duration(days: daysAgo));
  }
  
  String _randomAccountId() {
    final accounts = _availableAccountIds;
    if (accounts.isEmpty) return '';
    return accounts[_random.nextInt(accounts.length)];
  }
  
  String _randomExpenseCategoryId() {
    final categories = _expenseCategoryIds;
    if (categories.isEmpty) return 'supermarket';
    return categories[_random.nextInt(categories.length)];
  }
  
  String _randomIncomeCategoryId() {
    final categories = _incomeCategoryIds;
    if (categories.isEmpty) return 'salary';
    return categories[_random.nextInt(categories.length)];
  }
  
  // ============================================================
  // 🎲 Generate random transaction
  // ============================================================
  
  Future<Transaction?> _generateRandomTransaction() async {
    final accounts = _availableAccountIds;
    if (accounts.length < 2) {
      print("⚠️ Stress test: Need at least 2 accounts for transfers");
      return null;
    }
    
    final type = _random.nextInt(3);
    
    switch (type) {
      case 0: // Expense
        final fromAccountId = _randomAccountId();
        if (fromAccountId.isEmpty) return null;
        return Transaction.create(
          amount: _randomAmount(),
          type: TransactionType.expense,
          fromAccountId: fromAccountId,
          categoryId: _randomExpenseCategoryId(),
          date: _randomDate(),
          paymentMethod: 'cash',
          note: 'stress_test_expense_${DateTime.now().millisecondsSinceEpoch}',
          source: TransactionSource.manual,
        );
        
      case 1: // Income
        final toAccountId = _randomAccountId();
        if (toAccountId.isEmpty) return null;
        return Transaction.create(
          amount: _randomAmount(),
          type: TransactionType.income,
          toAccountId: toAccountId,
          categoryId: _randomIncomeCategoryId(),
          date: _randomDate(),
          paymentMethod: 'cash',
          note: 'stress_test_income_${DateTime.now().millisecondsSinceEpoch}',
          source: TransactionSource.manual,
        );
        
      case 2: // Transfer
        final fromAccountId = _randomAccountId();
        var toAccountId = _randomAccountId();
        // Ensure from != to
        while (toAccountId == fromAccountId && accounts.length > 1) {
          toAccountId = _randomAccountId();
        }
        if (fromAccountId.isEmpty || toAccountId.isEmpty || fromAccountId == toAccountId) {
          return null;
        }
        return Transaction.create(
          amount: _randomAmount(),
          type: TransactionType.transfer,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          categoryId: 'transfer',
          date: _randomDate(),
          paymentMethod: 'cash',
          note: 'stress_test_transfer_${DateTime.now().millisecondsSinceEpoch}',
          source: TransactionSource.manual,
        );
        
      default:
        return null;
    }
  }
  
  // ============================================================
  // 🚀 Run stress simulation
  // ============================================================
  
  Future<StressTestResult> runStressTest({
    required int transactionCount,
    int delayMs = 0,
    bool verbose = false,
  }) async {
    print("\n" + "=" * 70);
    print("🧪 LEDGER STRESS TEST STARTED");
    print("=" * 70);
    print("📊 Target Transactions: $transactionCount");
    print("⏱️ Delay between transactions: ${delayMs}ms");
    print("-" * 70);
    
    final startTime = DateTime.now();
    int successCount = 0;
    int failCount = 0;
    
    for (int i = 0; i < transactionCount; i++) {
      try {
        final tx = await _generateRandomTransaction();
        if (tx != null) {
          await _txService.addTransaction(tx);
          successCount++;
          if (verbose && i % 50 == 0) {
            print("   ✅ Progress: $successCount / $transactionCount transactions created");
          }
        } else {
          failCount++;
        }
        
        if (delayMs > 0 && i < transactionCount - 1) {
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e) {
        failCount++;
        if (verbose) {
          print("   ❌ Failed at iteration $i: $e");
        }
      }
    }
    
    final endTime = DateTime.now();
    final executionDuration = endTime.difference(startTime);
    
    print("-" * 70);
    print("📈 Stress Test Completed:");
    print("   ✅ Successful: $successCount");
    print("   ❌ Failed: $failCount");
    print("   ⏱️ Execution Time: ${executionDuration.inMilliseconds} ms");
    
    // Run integrity validation
    print("\n🔍 Running integrity validation...");
    final validationStart = DateTime.now();
    final report = await _integrityService.runFullValidation();
    final validationDuration = DateTime.now().difference(validationStart);
    
    print("-" * 70);
    print("🔍 INTEGRITY VALIDATION RESULTS:");
    print("   📊 Total Transactions: ${report.totalTransactions}");
    print("   📊 Total Ledger Entries: ${report.totalLedgerEntries}");
    print("   ⚠️ Duplicate Issues: ${report.duplicateTransactionIssues.length}");
    print("   🧹 Orphan Entries: ${report.orphanLedgerEntries.length}");
    print("   🔗 Missing Ledger: ${report.transactionsWithoutLedger.length}");
    print("   ⏱️ Validation Time: ${validationDuration.inMilliseconds} ms");
    
    if (report.duplicateTransactionIssues.isNotEmpty) {
      print("\n⚠️ DUPLICATE TRANSACTION ISSUES DETECTED:");
      for (final issue in report.duplicateTransactionIssues.take(5)) {
        print("   - $issue");
      }
      if (report.duplicateTransactionIssues.length > 5) {
        print("   ... and ${report.duplicateTransactionIssues.length - 5} more");
      }
    }
    
    if (report.orphanLedgerEntries.isNotEmpty) {
      print("\n⚠️ ORPHAN LEDGER ENTRIES DETECTED: ${report.orphanLedgerEntries.length}");
    }
    
    print("\n" + "=" * 70);
    print("✅ STRESS TEST COMPLETED");
    print("=" * 70 + "\n");
    
    return StressTestResult(
      targetCount: transactionCount,
      successCount: successCount,
      failCount: failCount,
      executionDurationMs: executionDuration.inMilliseconds,
      integrityReport: report,
      validationDurationMs: validationDuration.inMilliseconds,
    );
  }
  
  // ============================================================
  // 🧹 Cleanup stress test data
  // ============================================================
  
  Future<void> cleanupStressTestData() async {
    print("\n🧹 Cleaning up stress test transactions...");
    final allTransactions = _txService.getAllTransactions();
    int deletedCount = 0;
    
    for (final tx in allTransactions) {
      if (tx.note?.contains('stress_test_') == true) {
        await _txService.deleteTransaction(tx.id);
        deletedCount++;
      }
    }
    
    print("✅ Deleted $deletedCount stress test transactions");
  }
}

// ============================================================
// 📋 Result data class
// ============================================================

class StressTestResult {
  final int targetCount;
  final int successCount;
  final int failCount;
  final int executionDurationMs;
  final IntegrityReport integrityReport;
  final int validationDurationMs;
  
  StressTestResult({
    required this.targetCount,
    required this.successCount,
    required this.failCount,
    required this.executionDurationMs,
    required this.integrityReport,
    required this.validationDurationMs,
  });
  
  double get successRate => targetCount > 0 ? (successCount / targetCount) * 100 : 0;
}