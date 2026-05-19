// test/unit/migration_dry_run_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/utils/account_mapper.dart';

void main() async {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountNatureAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountGroupAdapter());
    }

    await Hive.openBox<Account>('migration_test_accounts');
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('migration_test_accounts');
  });

  tearDown(() async {
    await Hive.box<Account>('migration_test_accounts').clear();
  });

  Future<Account> createLegacyAccount({
    required String name,
    required String type,
    required AccountNature nature,
    required AccountGroup group,
  }) async {
    final box = Hive.box<Account>('migration_test_accounts');
    final account = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: 'test',
      memberId: 'tester',
      name: name,
      type: type,
      currency: 'EGP',
      createdAt: DateTime.now(),
      group: group,
      nature: nature,
      isArchived: false,
    );
    await box.put(account.id, account);
    return account;
  }

  group('Migration Dry Run - Nature Migration', () {
    late Box<Account> box;

    setUp(() async {
      box = Hive.box<Account>('migration_test_accounts');

      await createLegacyAccount(
        name: 'Legacy Debt',
        type: 'debt',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouOwe,
      );

      await createLegacyAccount(
        name: 'Legacy Loan',
        type: 'loan',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouOwe,
      );

      await createLegacyAccount(
        name: 'Legacy Credit Card',
        type: 'creditCard',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouOwe,
      );

      await createLegacyAccount(
        name: 'Legacy Installment',
        type: 'installment',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouOwe,
      );

      await createLegacyAccount(
        name: 'Correct Cash',
        type: 'cash',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Correct Investment',
        type: 'investment',
        nature: AccountNature.asset,
        group: AccountGroup.investments,
      );
    });

    test('Migration Dry Run - Scan and Identify', () async {
      final allAccounts = box.values.toList();
      int needsNatureMigration = 0;

      for (final account in allAccounts) {
        final expectedNature = resolveNature(account.type);
        if (account.nature != expectedNature) {
          needsNatureMigration++;
        }
      }

      expect(needsNatureMigration, 4);
    });
  });

  group('Migration Dry Run - Group Migration', () {
    late Box<Account> box;

    setUp(() async {
      box = Hive.box<Account>('migration_test_accounts');
      await box.clear();

      await createLegacyAccount(
        name: 'Legacy Gold',
        type: 'gold',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Legacy Stocks',
        type: 'stocks',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Legacy Certificates',
        type: 'certificates',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Legacy Lent',
        type: 'lent',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Legacy Rosca',
        type: 'rosca',
        nature: AccountNature.asset,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Legacy Credit Card Group',
        type: 'creditCard',
        nature: AccountNature.liability,
        group: AccountGroup.moneyYouHave,
      );

      await createLegacyAccount(
        name: 'Legacy Loan Group',
        type: 'loan',
        nature: AccountNature.liability,
        group: AccountGroup.moneyYouHave,
      );
    });

    test('Migration Dry Run - Group Migration Scan', () async {
      final allAccounts = box.values.toList();
      int needsGroupMigration = 0;

      for (final account in allAccounts) {
        final expectedGroup = resolveGroup(account.type);
        if (account.group != expectedGroup) {
          needsGroupMigration++;
        }
      }

      expect(needsGroupMigration, 7);
    });
  });

  group('Migration Dry Run - Rollback Behavior', () {
    test('Rollback simulation - Migration can be reversed', () async {
      final beforeMigration = Account(
        id: 'loan_1',
        bookId: 'test',
        memberId: 'tester',
        name: 'Loan',
        type: 'loan',
        currency: 'EGP',
        createdAt: DateTime.now(),
        group: AccountGroup.moneyYouHave,
        nature: AccountNature.asset,
        isArchived: false,
      );

      final afterMigration = beforeMigration.copyWith(
        nature: resolveNature(beforeMigration.type),
        group: resolveGroup(beforeMigration.type),
      );

      final rollback = afterMigration.copyWith(
        nature: beforeMigration.nature,
        group: beforeMigration.group,
      );

      expect(rollback.nature, beforeMigration.nature);
      expect(rollback.group, beforeMigration.group);
    });
  });

  group('Migration Dry Run - Money Conservation After Migration', () {
    test('Money conservation preserved after simulated migration', () async {
      final accountsBefore = [
        Account(
          id: 'loan_1',
          bookId: 'test',
          memberId: 'tester',
          name: 'Loan',
          type: 'loan',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.moneyYouHave,
          nature: AccountNature.asset,
          isArchived: false,
        ),
        Account(
          id: 'cash_1',
          bookId: 'test',
          memberId: 'tester',
          name: 'Cash',
          type: 'cash',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.moneyYouHave,
          nature: AccountNature.asset,
          isArchived: false,
        ),
      ];

      final accountsAfter = accountsBefore.map((account) {
        return account.copyWith(
          nature: resolveNature(account.type),
          group: resolveGroup(account.type),
        );
      }).toList();

      final balances = {'loan_1': -50000.0, 'cash_1': 10000.0};

      double calculateNetWorth(List<Account> accounts) {
        double total = 0;
        for (final account in accounts) {
          final balance = balances[account.id] ?? 0;
          if (account.nature == AccountNature.asset) {
            total += balance;
          } else if (account.nature == AccountNature.liability) {
            total -= balance.abs();
          }
        }
        return total;
      }

      final netWorthBefore = calculateNetWorth(accountsBefore);
      final netWorthAfter = calculateNetWorth(accountsAfter);

      expect(netWorthBefore, netWorthAfter);
    });
  });
}
