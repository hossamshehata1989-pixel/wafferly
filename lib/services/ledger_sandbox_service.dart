// lib/services/ledger_sandbox_service.dart
import 'ledger_service.dart';
import 'transaction_ledger_builder.dart';

/// Sandbox Service لاختبار Ledger pipeline بشكل معزول.
/// يستخدم LedgerService الحقيقي (ولكنه غير فعال حالياً لأنه لم يتم فتح box في main.dart).
/// لا يتم استدعاؤها من أي مكان في التطبيق حالياً.
class LedgerSandboxService {
  final LedgerService _ledgerService = LedgerService();
  final TransactionLedgerBuilder _builder = TransactionLedgerBuilder();

  /// تنفيذ اختبار كامل لـ Ledger pipeline باستخدام LedgerService الفعلي:
  /// 1. إنشاء entries باستخدام TransactionLedgerBuilder
  /// 2. حفظها عبر LedgerService.createEntries()
  /// 3. قراءتها عبر LedgerService.getEntriesByTransactionId()
  /// 4. طباعة النتائج في console
  Future<void> runSandboxTest() async {
    print("\n🧪 ========== Ledger Sandbox Test Started ==========\n");

    try {
      // 1. Mock transaction data
      const String mockTransactionId = "sandbox_tx_001";
      const String expenseAccountId = "sandbox_account_food";
      const String sourceAccountId = "sandbox_account_cash";
      const double amount = 150.0;
      final DateTime date = DateTime.now();

      // 2. Build LedgerEntries for an expense
      final entries = _builder.buildExpenseEntries(
        transactionId: mockTransactionId,
        expenseAccountId: expenseAccountId,
        sourceAccountId: sourceAccountId,
        amount: amount,
        date: date,
      );

      print("📝 Built ${entries.length} ledger entries:");
      for (var e in entries) {
        print("   - ${e.entryType.string}: ${e.accountId} (${e.amount} EGP)");
      }

      // 3. Save using LedgerService
      await _ledgerService.createEntries(entries);
      print("\n💾 Saved entries via LedgerService.");

      // 4. Retrieve using LedgerService
      final savedEntries = await _ledgerService.getEntriesByTransactionId(mockTransactionId);
      
      print("\n🔍 Retrieved ${savedEntries.length} entries by transactionId:");
      for (var e in savedEntries) {
        print("   - ID: ${e.id}, account: ${e.accountId}, amount: ${e.amount}, type: ${e.entryType.string}");
      }

      // 5. Verify
      if (savedEntries.length == 2) {
        print("\n✅ Sandbox test PASSED: Found both debit and credit entries.");
      } else {
        print("\n⚠️ Sandbox test WARNING: Expected 2 entries, found ${savedEntries.length}.");
      }
    } catch (e) {
      print("\n❌ Sandbox test FAILED: $e");
    }

    print("\n🧪 ========== Ledger Sandbox Test Finished ==========\n");
  }
}