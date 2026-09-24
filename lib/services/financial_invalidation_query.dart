import 'package:hive/hive.dart';

/// Read-side access to persisted financial invalidations.
///
/// It deliberately exposes only synchronous lookup needed by the existing
/// synchronous balance and transaction query APIs. It does not mutate state.
final class FinancialInvalidationQuery {
  const FinancialInvalidationQuery();

  bool isInvalidated(String transactionId) {
    if (!Hive.isBoxOpen('financial_invalidations')) return false;

    final box = Hive.box<Map>('financial_invalidations');
    return box.values.any(
      (value) => value['originalTransactionId'] == transactionId,
    );
  }

  Set<String> invalidatedTransactionIds() {
    if (!Hive.isBoxOpen('financial_invalidations')) return <String>{};

    final box = Hive.box<Map>('financial_invalidations');
    return box.values
        .map((value) => value['originalTransactionId'])
        .whereType<String>()
        .toSet();
  }
}
