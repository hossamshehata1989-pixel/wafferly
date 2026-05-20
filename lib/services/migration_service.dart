// lib/services/migration_service.dart

import 'package:hive/hive.dart';
import '../models/account.dart';
import '../utils/account_mapper.dart';

class MigrationService {
  final Box<Account> _box;

  MigrationService({Box<Account>? accountBox})
    : _box = accountBox ?? Hive.box<Account>('accounts');

  /// Migrate legacy account classification (group + nature)
  /// Fixes old accounts created before classification definitions were corrected
  Future<int> migrateLegacyAccountClassification() async {
    int fixedCount = 0;

    for (final account in _box.values) {
      final expectedGroup = resolveGroup(account.type);
      final expectedNature = resolveNature(account.type);

      final needsGroupFix = account.group != expectedGroup;
      final needsNatureFix = account.nature != expectedNature;

      if (needsGroupFix || needsNatureFix) {
        final corrected = account.copyWith(
          group: expectedGroup,
          nature: expectedNature,
        );

        await _box.put(account.id, corrected);
        fixedCount++;
      }
    }

    return fixedCount;
  }

  /// Check if any legacy accounts need migration
  Future<bool> needsMigration() async {
    for (final account in _box.values) {
      final expectedGroup = resolveGroup(account.type);
      final expectedNature = resolveNature(account.type);

      if (account.group != expectedGroup || account.nature != expectedNature) {
        return true;
      }
    }
    return false;
  }
}
