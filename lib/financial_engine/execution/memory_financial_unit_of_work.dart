import 'financial_unit_of_work.dart';

final class MemoryFinancialUnitOfWork implements FinancialUnitOfWork {
  const MemoryFinancialUnitOfWork();

  @override
  Future<void> execute(Future<void> Function() action) async {
    await action();
  }
}
