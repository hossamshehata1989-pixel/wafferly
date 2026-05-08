import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/account_enums.dart';
import '../utils/account_mapper.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  final Box<Account> box = Hive.box<Account>('accounts');

  final _uuid = const Uuid();

  Account _buildAccount({
    required String name,
    required String type,
    required String currency,
    String? notes,
  }) {
    final natureEnum = resolveNature(type);
    final group = resolveGroup(type);

    return Account(
      id: _uuid.v4(),
      bookId: 'default',
      memberId: 'owner',
      name: name,
      type: type,
      nature: natureEnum.name,
      currency: currency,
      createdAt: DateTime.now(),
      natureEnum: natureEnum,
      group: group,
      isArchived: false,
      notes: notes,
    );
  }

  Future<Account> createAccount({
    required String name,
    required String type,
    required String currency,
    String? notes,
  }) async {
    try {
      final account = _buildAccount(
        name: name,
        type: type,
        currency: currency,
        notes: notes,
      );

      await box.put(account.id, account);
      return account;
    } catch (e) {
      print("❌ Error creating account: $e");
      throw Exception("Failed to create account");
    }
  }

  List<Account> getAllAccounts() => box.values.toList();

  List<Account> getAllActiveAccounts() =>
      box.values.where((acc) => !acc.isArchived).toList();

  Future<void> updateAccount(Account account) async {
    await box.put(account.id, account);
  }

  Future<void> archiveAccount(String id) async {
    final acc = box.get(id);
    if (acc != null) {
      acc.isArchived = true;
      await acc.save();
    }
  }
}