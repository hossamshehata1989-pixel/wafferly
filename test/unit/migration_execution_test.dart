import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/services/migration_service.dart';

void main() {
  late Box<Account> testBox;
  late String testPath;

  setUpAll(() async {
    testPath = Directory.systemTemp
        .createTempSync('wafferly_migration_test_')
        .path;

    Hive.init(testPath);

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
    if (Hive.isBoxOpen('test_migration_accounts')) {
      await testBox.clear();
      await testBox.close();
    }

    final directory = Directory(testPath);

    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  tearDown(() async {
    if (Hive.isBoxOpen('test_migration_accounts')) {
      await testBox.clear();
    }
  });

  group('Migration Execution Test', () {
    test(
      'Migrate legacy creditCard from liquidity to liabilities',
      () async {
        final legacyAccount = Account(
          id: 'cc_1',
          bookId: 'test',
          memberId: 'tester',
          name: 'Legacy Credit Card',
          type: 'creditCard',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.liquidity,
          nature: AccountNature.asset,
          isArchived: false,
        );

        await testBox.put(legacyAccount.id, legacyAccount);

        final migrationService = MigrationService(
          accountBox: testBox,
        );

        final fixedCount =
            await migrationService.migrateLegacyAccountClassification();

        final migrated = testBox.get(legacyAccount.id);

        expect(migrated, isNotNull);
        expect(migrated!.group, AccountGroup.liabilities);
        expect(migrated.nature, AccountNature.liability);
        expect(fixedCount, 1);
      },
    );

    test(
      'Migrate legacy gold from liquidity to investments',
      () async {
        final legacyAccount = Account(
          id: 'gold_1',
          bookId: 'test',
          memberId: 'tester',
          name: 'Legacy Gold',
          type: 'gold',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.liquidity,
          nature: AccountNature.asset,
          isArchived: false,
        );

        await testBox.put(legacyAccount.id, legacyAccount);

        final migrationService = MigrationService(
          accountBox: testBox,
        );

        final fixedCount =
            await migrationService.migrateLegacyAccountClassification();

        final migrated = testBox.get(legacyAccount.id);

        expect(migrated, isNotNull);
        expect(migrated!.group, AccountGroup.investments);
        expect(migrated.nature, AccountNature.asset);
        expect(fixedCount, 1);
      },
    );

    test(
      'Migrate legacy lent from liquidity to receivable',
      () async {
        final legacyAccount = Account(
          id: 'lent_1',
          bookId: 'test',
          memberId: 'tester',
          name: 'Legacy Lent',
          type: 'lent',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.liquidity,
          nature: AccountNature.asset,
          isArchived: false,
        );

        await testBox.put(legacyAccount.id, legacyAccount);

        final migrationService = MigrationService(
          accountBox: testBox,
        );

        final fixedCount =
            await migrationService.migrateLegacyAccountClassification();

        final migrated = testBox.get(legacyAccount.id);

        expect(migrated, isNotNull);
        expect(migrated!.group, AccountGroup.receivable);
        expect(migrated.nature, AccountNature.asset);
        expect(fixedCount, 1);
      },
    );

    test('Already correct account is not modified', () async {
      final correctAccount = Account(
        id: 'cash_1',
        bookId: 'test',
        memberId: 'tester',
        name: 'Cash',
        type: 'cash',
        currency: 'EGP',
        createdAt: DateTime.now(),
        group: AccountGroup.liquidity,
        nature: AccountNature.asset,
        isArchived: false,
      );

      await testBox.put(correctAccount.id, correctAccount);

      final migrationService = MigrationService(
        accountBox: testBox,
      );

      final needsMigration = await migrationService.needsMigration();

      expect(needsMigration, false);

      final fixedCount =
          await migrationService.migrateLegacyAccountClassification();

      expect(fixedCount, 0);

      final migrated = testBox.get(correctAccount.id);

      expect(migrated, isNotNull);
      expect(migrated!.group, AccountGroup.liquidity);
      expect(migrated.nature, AccountNature.asset);
    });

    test(
      'Migrate all legacy account classifications',
      () async {
        final legacyAccounts = <Account>[
          Account(
            id: 'gold_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Gold',
            type: 'gold',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
          Account(
            id: 'stocks_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Stocks',
            type: 'stocks',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
          Account(
            id: 'certificates_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Certificates',
            type: 'certificates',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
          Account(
            id: 'lent_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Lent',
            type: 'lent',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
          Account(
            id: 'rosca_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Rosca',
            type: 'rosca',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
          Account(
            id: 'credit_card_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Credit Card',
            type: 'creditCard',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
          Account(
            id: 'loan_1',
            bookId: 'test',
            memberId: 'tester',
            name: 'Legacy Loan',
            type: 'loan',
            currency: 'EGP',
            createdAt: DateTime.now(),
            group: AccountGroup.liquidity,
            nature: AccountNature.asset,
            isArchived: false,
          ),
        ];

        for (final account in legacyAccounts) {
          await testBox.put(account.id, account);
        }

        final migrationService = MigrationService(
          accountBox: testBox,
        );

        final fixedCount =
            await migrationService.migrateLegacyAccountClassification();

        expect(fixedCount, 7);

        expect(
          testBox.get('gold_1')!.group,
          AccountGroup.investments,
        );
        expect(
          testBox.get('stocks_1')!.group,
          AccountGroup.investments,
        );
        expect(
          testBox.get('certificates_1')!.group,
          AccountGroup.investments,
        );
        expect(
          testBox.get('lent_1')!.group,
          AccountGroup.receivable,
        );
        expect(
  testBox.get('rosca_1')!.group,
  AccountGroup.receivable,
);
        expect(
          testBox.get('credit_card_1')!.group,
          AccountGroup.liabilities,
        );
        expect(
          testBox.get('loan_1')!.group,
          AccountGroup.liabilities,
        );

        expect(
          testBox.get('gold_1')!.nature,
          AccountNature.asset,
        );
        expect(
          testBox.get('stocks_1')!.nature,
          AccountNature.asset,
        );
        expect(
          testBox.get('certificates_1')!.nature,
          AccountNature.asset,
        );
        expect(
          testBox.get('lent_1')!.nature,
          AccountNature.asset,
        );
        expect(
          testBox.get('rosca_1')!.nature,
          AccountNature.asset,
        );
        expect(
          testBox.get('credit_card_1')!.nature,
          AccountNature.liability,
        );
        expect(
          testBox.get('loan_1')!.nature,
          AccountNature.liability,
        );

        expect(
          await migrationService.needsMigration(),
          false,
        );
      },
    );

    test(
      'Migration is idempotent and second run makes no changes',
      () async {
        final legacyAccount = Account(
          id: 'idempotent_loan',
          bookId: 'test',
          memberId: 'tester',
          name: 'Legacy Loan',
          type: 'loan',
          currency: 'EGP',
          createdAt: DateTime.now(),
          group: AccountGroup.liquidity,
          nature: AccountNature.asset,
          isArchived: false,
        );

        await testBox.put(legacyAccount.id, legacyAccount);

        final migrationService = MigrationService(
          accountBox: testBox,
        );

        final firstRun =
            await migrationService.migrateLegacyAccountClassification();

        expect(firstRun, 1);
        expect(await migrationService.needsMigration(), false);

        final secondRun =
            await migrationService.migrateLegacyAccountClassification();

        expect(secondRun, 0);
        expect(await migrationService.needsMigration(), false);

        final migrated = testBox.get(legacyAccount.id);

        expect(migrated, isNotNull);
        expect(migrated!.group, AccountGroup.liabilities);
        expect(migrated.nature, AccountNature.liability);
      },
    );
  });
}