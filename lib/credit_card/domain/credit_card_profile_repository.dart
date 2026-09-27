import 'credit_card_profile.dart';

abstract interface class CreditCardProfileRepository {
  Future<CreditCardProfile?> findByAccountId(String accountId);
}
