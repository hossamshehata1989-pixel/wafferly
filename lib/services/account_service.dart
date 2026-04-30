import 'package:hive/hive.dart';
import '../models/account.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  final Box<Account> box = Hive.box<Account>('accounts');

  List<Account> getAllAccounts() {
    return box.values.toList();
  }

  Future<void> addAccount(Account account) async {
    await box.put(account.id, account);
  }

  Future<void> deleteAccount(String id) async {
    await box.delete(id);
  }

  Future<void> updateAccount(Account account) async {
    await box.put(account.id, account);
  }

  Account? getById(String id) {
    return box.get(id);
  }
}