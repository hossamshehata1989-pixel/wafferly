import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/config/category_config.dart';
import 'package:wafferly/constants/ledger_system_account_ids.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/services/ledger_account_service.dart';

void main() {
  late Directory testDirectory;
  late Box<LedgerAccount> ledgerAccountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_ledger_mapping_coverage_test_',
    );
    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(LedgerAccountTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(LedgerAccountAdapter());
    }

    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await ledgerAccountsBox.clear();
  });

  test(
    'all configured expense and income categories resolve to a real ledger account after seed',
    () async {
      final seeder = LedgerAccountSeeder();
      await seeder.seedIfNeeded();

      final service = LedgerAccountService();
      for (final category in expenseCategories) {
        final account = service.getByCategoryId(category.id);
        expect(
          account,
          isNotNull,
          reason: 'Missing expense mapping: ${category.id}',
        );
        expect(
          account!.type,
          LedgerAccountType.expense,
          reason: 'Wrong ledger type for expense category: ${category.id}',
        );
        expect(account.isSystem, isTrue);
      }

      for (final category in incomeCategories) {
        final account = service.getByCategoryId(category.id);
        expect(
          account,
          isNotNull,
          reason: 'Missing income mapping: ${category.id}',
        );
        expect(
          account!.type,
          LedgerAccountType.income,
          reason: 'Wrong ledger type for income category: ${category.id}',
        );
        expect(account.isSystem, isTrue);
      }

      final openingEquity = service.getById(
        LedgerSystemAccountIds.openingBalanceEquity,
      );
      expect(openingEquity, isNotNull);
      expect(openingEquity!.type, LedgerAccountType.equity);
      expect(openingEquity.isSystem, isTrue);

      final reconciliationEquity = service.getById(
        LedgerSystemAccountIds.balanceReconciliationEquity,
      );
      expect(reconciliationEquity, isNotNull);
      expect(reconciliationEquity!.type, LedgerAccountType.equity);
      expect(reconciliationEquity.isSystem, isTrue);

      final seededCount = ledgerAccountsBox.length;
      await seeder.seedIfNeeded();
      expect(ledgerAccountsBox.length, seededCount);
    },
  );

  test(
    'runtime lookup rejects duplicate persisted mappings instead of choosing the first',
    () async {
      final seeder = LedgerAccountSeeder();
      await seeder.seedIfNeeded();

      const categoryId = 'dailyTransport';
      final service = LedgerAccountService();
      final original = service.getByCategoryId(categoryId);
      expect(original, isNotNull);

      await service.createAccount(
        name: 'Duplicate mapping',
        type: LedgerAccountType.expense,
        categoryId: categoryId,
        isSystem: true,
      );

      expect(
        () => service.getByCategoryId(categoryId),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('multiple Ledger account mappings'),
          ),
        ),
      );
    },
  );
}
