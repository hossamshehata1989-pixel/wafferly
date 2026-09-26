// lib/services/transaction_service.dart
import '../models/transaction.dart';
import 'transaction_query_service.dart';

/// Compatibility-only read facade for tests and legacy callers.
///
/// Financial writes are intentionally absent. All production callers should
/// use [TransactionQueryService] for reads and [FinancialOperationEngine] for
/// financial mutations.
@Deprecated('Use TransactionQueryService for reads and FinancialOperationEngine for writes.')
final class TransactionService {
  TransactionService._privateConstructor();

  static final TransactionService _instance =
      TransactionService._privateConstructor();

  static TransactionService get instance => _instance;

  final TransactionQueryService _queryService = const TransactionQueryService();

  List<Transaction> getAllTransactions() => _queryService.getAllTransactions();

  Transaction? getById(String id) => _queryService.getById(id);

  List<Transaction> getByType(String type) => _queryService.getByType(type);

  List<Transaction> getIncomeTransactions() =>
      _queryService.getIncomeTransactions();

  List<Transaction> getExpenseTransactions() =>
      _queryService.getExpenseTransactions();

  List<Transaction> getByCategory(String categoryId) =>
      _queryService.getByCategory(categoryId);

  List<Transaction> getByDateRange(DateTime start, DateTime end) =>
      _queryService.getByDateRange(start, end);

  List<Transaction> getForAccount(String accountId) =>
      _queryService.getForAccount(accountId);

  bool hasTransactionsForAccount(String accountId) =>
      _queryService.hasTransactionsForAccount(accountId);

  double getTotalByType(String type, DateTime start, DateTime end) =>
      _queryService.getTotalByType(type, start, end);

  double getTotalExpenses(DateTime start, DateTime end) =>
      _queryService.getTotalExpenses(start, end);

  double getTotalIncome(DateTime start, DateTime end) =>
      _queryService.getTotalIncome(start, end);

  double getNormalExpenses(DateTime start, DateTime end) =>
      _queryService.getNormalExpenses(start, end);

  double getExceptionalExpenses(DateTime start, DateTime end) =>
      _queryService.getExceptionalExpenses(start, end);

  Map<String, double> getExpensesByCategory(DateTime start, DateTime end) =>
      _queryService.getExpensesByCategory(start, end);

  Map<String, double> getExpensesBySource(DateTime start, DateTime end) =>
      _queryService.getExpensesBySource(start, end);

  List<Transaction> getLegacyTransactions() =>
      _queryService.getLegacyTransactions();

  int get count => _queryService.count;
  bool get isEmpty => _queryService.isEmpty;
  bool get isNotEmpty => _queryService.isNotEmpty;
}
