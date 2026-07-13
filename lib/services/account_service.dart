// lib/services/account_service.dart

import 'package:hive_flutter/hive_flutter.dart'; // ✅ التعديل هنا
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/enums/account_enums.dart';
import '../utils/account_mapper.dart';
import '../constants/temp_debt_constants.dart';

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
      nature: natureEnum,
      currency: currency,
      createdAt: DateTime.now(),
      group: group,
      isArchived: false,
      notes: notes,
    );
  }

  /// إنشاء حساب جديد
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
      debugPrint("❌ Error creating account: $e");
      throw Exception("Failed to create account");
    }
  }

  /// إنشاء حساب نظامي (مثل الدين المؤقت)
  Future<Account> createSystemAccount({
    required String id,
    required String name,
    required String type,
    required String currency,
    String? notes,
  }) async {
    try {
      final natureEnum = resolveNature(type);
      final group = resolveGroup(type);

      final account = Account(
        id: id,
        bookId: 'default',
        memberId: 'owner',
        name: name,
        type: type,
        nature: natureEnum,
        currency: currency,
        createdAt: DateTime.now(),
        group: group,
        isArchived: false,
        notes: notes,
      );

      await box.put(account.id, account);
      return account;
    } catch (e) {
      debugPrint("❌ Error creating system account: $e");
      throw Exception("Failed to create system account");
    }
  }

  /// الحصول على جميع الحسابات
  List<Account> getAllAccounts() => box.values.toList();

  /// الحصول على الحسابات النشطة فقط
  List<Account> getAllActiveAccounts() =>
      box.values.where((acc) => !acc.isArchived).toList();

  /// تحديث حساب موجود
  Future<void> updateAccount(Account account) async {
    await box.put(account.id, account);
  }

  /// أرشفة حساب (تعطيله)
  Future<void> archiveAccount(String id) async {
    if (id == tempDebtAccountId) {
      return;
    }

    final acc = box.get(id);
    if (acc != null) {
      acc.isArchived = true;
      await updateAccount(acc);
    }
  }

  /// الحصول على حساب بالمعرف
  Account? getAccountById(String id) {
    return box.get(id);
  }

  /// مسح جميع الحسابات (للاختبار)
  Future<void> clearAllAccounts() async {
    if (box.isNotEmpty) {
      await box.clear();
    }
  }

  /// ✅ مصدر استماع لتغييرات الحسابات (يخفي تفاصيل Hive)
  Listenable get accountsListenable => box.listenable();
}
