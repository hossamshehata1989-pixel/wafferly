// lib/services/ledger_account_service.dart
// Sprint 3B — LedgerAccount Foundation
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/ledger_account.dart';
import '../models/enums/ledger_account_type.dart';

class LedgerAccountService {
  static final LedgerAccountService _instance =
      LedgerAccountService._internal();
  factory LedgerAccountService() => _instance;
  LedgerAccountService._internal();

  static const String _boxName = 'ledger_accounts';
  final _uuid = const Uuid();

  Box<LedgerAccount> get _box => Hive.box<LedgerAccount>(_boxName);

  // ==================== CRUD ====================

  /// Ensures a system account exists under its stable canonical identifier.
  ///
  /// Existing records are validated rather than silently rewritten. A
  /// conflicting record must be investigated because system IDs are part of
  /// the persisted accounting contract.
  Future<LedgerAccount> ensureSystemAccount({
    required String id,
    required String name,
    required LedgerAccountType type,
  }) async {
    final existing = getById(id);
    if (existing != null) {
      if (existing.id != id ||
          !existing.isSystem ||
          existing.type != type ||
          existing.categoryId != null) {
        throw StateError(
          'System Ledger account "$id" exists with an incompatible definition.',
        );
      }
      return existing;
    }

    final account = LedgerAccount(
      id: id,
      name: name,
      type: type,
      isSystem: true,
    );
    await _box.put(id, account);
    return account;
  }

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
    final matches = _box.values
        .where((account) => account.categoryId == categoryId)
        .toList(growable: false);

    if (matches.length > 1) {
      throw StateError(
        'Category "$categoryId" has multiple Ledger account mappings.',
      );
    }

    return matches.isEmpty ? null : matches.single;
  }

  List<LedgerAccount> getSystemAccounts() {
    return _box.values.where((a) => a.isSystem).toList();
  }

  // ==================== Helper ====================

  Future<void> deleteAllAccounts() async {
    await _box.clear();
  }
}
