import '../../core/money/money.dart';

/// Read-only balance contract used by Credit Card domain guards.
///
/// It deliberately exposes no mutation capability.
abstract interface class CreditCardBalanceReader {
  Future<Money> currentBalance(String accountId);
}
