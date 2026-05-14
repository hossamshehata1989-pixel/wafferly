// lib/services/ledger_account_service.dart
// Sprint 3B — LedgerAccount Foundation
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/ledger_account.dart';
import '../models/enums/ledger_account_type.dart';

class LedgerAccountService {
  static final LedgerAccountService _instance = LedgerAccountService._internal();
  factory LedgerAccountService() => _instance;
  LedgerAccountService._internal();

  static const String _boxName = 'ledger_accounts';
  final _uuid = const Uuid();

  Box<LedgerAccount> get _box => Hive.box<LedgerAccount>(_boxName);

  // ==================== CRUD ====================

  Future<LedgerAccount> createAccount({
    required String name,
    required LedgerAccountType type,
    String? categoryId,
    bool isSystem = false,
    String? parentId,
  }) async {
    final account = LedgerAccount(
      id: _uuid.v4(),
      name: name,
      type: type,
      categoryId: categoryId,
      isSystem: isSystem,
      parentId: parentId,
    );
    await _box.put(account.id, account);
    return account;
  }

  LedgerAccount? getById(String id) {
    return _box.get(id);
  }

  List<LedgerAccount> getAllAccounts() {
    return _box.values.toList();
  }

  List<LedgerAccount> getByType(LedgerAccountType type) {
    return _box.values.where((a) => a.type == type).toList();
  }

  // ✅ Sprint 3C: دالة الربط بين Category و LedgerAccount
  LedgerAccount? getByCategoryId(String categoryId) {
    try {
      return _box.values.firstWhere((a) => a.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  List<LedgerAccount> getSystemAccounts() {
    return _box.values.where((a) => a.isSystem).toList();
  }

  // ==================== Helper ====================

  Future<void> deleteAllAccounts() async {
    await _box.clear();
  }
}