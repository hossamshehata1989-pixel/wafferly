import '../domain/financial_transaction_record.dart';

/// Persistence port for financial transactions.
///
/// The Financial Engine writes transaction records through this port.
///
/// The implementation may persist to:
/// - Hive
/// - Supabase
/// - SQLite
/// - Firestore
///
/// The Engine never knows which implementation is used.
///
/// ADR-0013
/// ADR-0014
abstract interface class TransactionPort {
  /// Persists a financial transaction record.
  Future<void> save(FinancialTransactionRecord record);
}
