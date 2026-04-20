import 'package:hive/hive.dart';
import '../models/account.dart';

class AccountService {

static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

final Box<Account> box = Hive.box<Account>('accounts');

// 📥 Get all accounts
List<Account> getAllAccounts() {
return box.values.toList();
}

// ➕ Add account
Future<void> addAccount(Account account) async {
await box.put(account.id, account);
}

// ❌ Delete account
Future<void> deleteAccount(String id) async {
await box.delete(id);
}

// 🔄 Update account
Future<void> updateAccount(Account account) async {
await box.put(account.id, account);
}

// 🔍 Get by ID
Account? getById(String id) {
return box.get(id);
}
}
