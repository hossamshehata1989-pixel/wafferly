import 'package:hive/hive.dart';
import '../../../models/account.dart';

class AccountService {
  final box = Hive.box<Account>('accounts');

  void createAccount({
    required String name,
    required String type,
    required String currency,
  }) {
    box.add(Account(
      name: name,
      type: type,
      currency: currency,
    ));
  }

  List<Account> getAllAccounts() {
    return box.values.toList();
  }
}