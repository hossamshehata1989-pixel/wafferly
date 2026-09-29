
import '../../../../models/account.dart';
import '../../../../models/transaction.dart';
import '../../../../credit_card/domain/credit_card_profile.dart';
import '../account_details_models.dart';

abstract interface class AccountDetailsRepository {
  Account? getAccount(String accountId);

  double getBalance(String accountId);

  double getBalanceAtDate(String accountId, DateTime date);

  Future<CreditCardProfile?> getCreditCardProfile(String accountId);

  Future<AccountProjection> getProjection({
    required String accountId,
    required double balance,
  });

  List<Transaction> getTransactions(String accountId);

  Future<List<RecurringAccountItem>> getRecurring(String accountId);
}

class AccountProjection {
  const AccountProjection({
    required this.balance,
    required this.available,
    required this.reserved,
  });

  final double balance;
  final double available;
  final double reserved;
}
