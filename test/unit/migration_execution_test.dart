// test/unit/migration_execution_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/services/migration_service.dart';
import 'package:wafferly/utils/account_mapper.dart';

void main() {
  late Box<Account> testBox;

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

    testBox = await Hive.openBox<Account>('test_migration_accounts');
  });

  tearDownAll(() async {
    await testBox.clear();
    await Hive.deleteBoxFromDisk('test_migration_accounts');
  });

  tearDown(() async {
    await testBox.clear();
  });

  group('Migration Execution Test', () {
    test(
      'Migrate legacy creditCard from moneyYouHave to moneyYouOwe',
      () async {
        final legacyAccount = Account(
          id: 'cc_1',
          bookId: 'test',
          memberId: 'tester',
          name: 'Legacy Credit Card',
          type: 'creditCard',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.moneyYouHave,
          nature: AccountNature.asset,
          isArchived: false,
        );
        await testBox.put(legacyAccount.id, legacyAccount);

        final migrationService = MigrationService(accountBox: testBox);
        final fixedCount = await migrationService
            .migrateLegacyAccountClassification();

        final migrated = testBox.get(legacyAccount.id);
        expect(migrated!.group, AccountGroup.moneyYouOwe);
        expect(migrated.nature, AccountNature.liability);
        expect(fixedCount, 1);
      },
    );

    test('Migrate legacy gold from moneyYouHave to investments', () async {
      final legacyAccount = Account(
        id: 'gold_1',
        bookId: 'test',
        memberId: 'tester',
        name: 'Legacy Gold',
        type: 'gold',
        currency: 'EGP',
        createdAt: DateTime.now(),
        group: AccountGroup.moneyYouHave,
        nature: AccountNature.asset,
        isArchived: false,
      );
      await testBox.put(legacyAccount.id, legacyAccount);

      final migrationService = MigrationService(accountBox: testBox);
      await migrationService.migrateLegacyAccountClassification();

      final migrated = testBox.get(legacyAccount.id);
      expect(migrated!.group, AccountGroup.investments);
    });

    test('Migrate legacy lent from moneyYouHave to moneyYouWillGet', () async {
      final legacyAccount = Account(
        id: 'lent_1',
        bookId: 'test',
        memberId: 'tester',
        name: 'Legacy Lent',
        type: 'lent',
        currency: 'EGP',
        createdAt: DateTime.now(),
        group: AccountGroup.moneyYouHave,
        nature: AccountNature.asset,
        isArchived: false,
      );
      await testBox.put(legacyAccount.id, legacyAccount);

      final migrationService = MigrationService(accountBox: testBox);
      await migrationService.migrateLegacyAccountClassification();

      final migrated = testBox.get(legacyAccount.id);
      expect(migrated!.group, AccountGroup.moneyYouWillGet);
    });

    test('Already correct account is not modified', () async {
      final correctAccount = Account(
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
      );
      await testBox.put(correctAccount.id, correctAccount);

      final migrationService = MigrationService(accountBox: testBox);
      final needsMigration = await migrationService.needsMigration();

      expect(needsMigration, false);
    });
  });
}
