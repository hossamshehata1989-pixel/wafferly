import '../domain/financial_invalidation_record.dart';
import '../planning/financial_mutation.dart';

final class InvalidateTransactionMutation extends DomainMutation {
  final FinancialInvalidationRecord record;

  const InvalidateTransactionMutation({required this.record});
}
