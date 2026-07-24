import '../models/ledger_entry.dart';

abstract class LedgerPort {
  Future<void> createEntries(List<LedgerEntry> entries);

  Future<List<LedgerEntry>> getEntriesByTransactionId(String transactionId);

  Future<void> deleteEntriesByTransactionId(String transactionId);
}
