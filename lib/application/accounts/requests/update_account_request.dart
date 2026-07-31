import 'package:wafferly/models/account.dart';

class UpdateAccountRequest {
  final Account account;
  final String accountId;
  final double oldBalance;
  final double newBalance;
  final String paymentMethod;
  final String currency;

  const UpdateAccountRequest({
    required this.account,
    required this.accountId,
    required this.oldBalance,
    required this.newBalance,
    required this.paymentMethod,
    required this.currency,
  });
}
