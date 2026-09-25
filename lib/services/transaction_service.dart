// lib/services/transaction_service.dart
import '../models/transaction.dart';
import 'transaction_query_service.dart';

/// Transitional compatibility facade for legacy callers/tests.
///
/// New production code must depend on [TransactionQueryService].
/// This class is query-only and contains no financial mutation capability.
@Deprecated('Use TransactionQueryService instead.')
final class TransactionService {
  TransactionService._privateConstructor();

  static final TransactionService _instance =
      TransactionService._privateConstructor();

  static TransactionService get instance => _instance;

  final TransactionQueryService _query = const TransactionQueryService();

  List<Transaction> getAllTransactions() => _query.getAllTransactions();
  Transaction? getById(String id) => _query.getById(id);
  List<Transaction> getByType(String type) => _query.getByType(type);
  List<Transaction> getIncomeTransactions() =>
      _query.getIncomeTransactions();
  List<Transaction> getExpenseTransactions() =>
      _query.getExpenseTransactions();
  List<Transaction> getByCategory(String categoryId) =>
      _query.getByCategory(categoryId);
  List<Transaction> getByDateRange(DateTime start, DateTime end) =>
      _query.getByDateRange(start, end);
  List<Transaction> getForAccount(String accountId) =>
      _query.getForAccount(accountId);
  bool hasTransactionsForAccount(String accountId) =>
      _query.hasTransactionsForAccount(accountId);
  double getTotalByType(String type, DateTime start, DateTime end) =>
      _query.getTotalByType(type, start, end);
  double getTotalExpenses(DateTime start, DateTime end) =>
      _query.getTotalExpenses(start, end);
  double getTotalIncome(DateTime start, DateTime end) =>
      _query.getTotalIncome(start, end);
  double getNormalExpenses(DateTime start, DateTime end) =>
      _query.getNormalExpenses(start, end);
  double getExceptionalExpenses(DateTime start, DateTime end) =>
      _query.getExceptionalExpenses(start, end);
  Map<String, double> getExpensesByCategory(DateTime start, DateTime end) =>
      _query.getExpensesByCategory(start, end);
  Map<String, double> getExpensesBySource(DateTime start, DateTime end) =>
      _query.getExpensesBySource(start, end);
  List<Transaction> getLegacyTransactions() => _query.getLegacyTransactions();
  int get count => _query.count;
  bool get isEmpty => _query.isEmpty;
  bool get isNotEmpty => _query.isNotEmpty;
}
