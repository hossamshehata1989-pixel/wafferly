// lib/services/current_account_service.dart

import 'package:hive/hive.dart';
import '../models/account.dart';

class CurrentAccountService {
  String getFirstActiveAccountId() {
    final box = Hive.box<Account>('accounts');
    final accounts = box.values.where((a) => !a.isArchived).toList();
    return accounts.isNotEmpty ? accounts.first.id : '';
  }

  Account? getFirstActiveAccount() {
    final box = Hive.box<Account>('accounts');
    final accounts = box.values.where((a) => !a.isArchived).toList();
    return accounts.isNotEmpty ? accounts.first : null;
  }
}
