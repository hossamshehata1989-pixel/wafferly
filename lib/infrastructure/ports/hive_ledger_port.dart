import '../../models/ledger_entry.dart';
import '../../ports/ledger_port.dart';
import '../../services/ledger_service.dart';

class HiveLedgerPort implements LedgerPort {
  HiveLedgerPort({LedgerService? ledgerService})
    : _ledgerService = ledgerService ?? LedgerService();

  final LedgerService _ledgerService;

  @override
  Future<void> createEntries(List<LedgerEntry> entries) {
    return _ledgerService.createEntries(entries);
  }

  @override
  Future<List<LedgerEntry>> getEntriesByTransactionId(String transactionId) {
    return _ledgerService.getEntriesByTransactionId(transactionId);
  }

  @override
  Future<void> deleteEntriesByTransactionId(String transactionId) {
    return _ledgerService.deleteEntriesByTransactionId(transactionId);
  }
}
