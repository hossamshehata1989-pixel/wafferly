// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'features/members/controllers/members_controller.dart';
import 'features/members/models/member_model.dart';

import 'models/account.dart';
import 'models/budget.dart';
import 'models/reserved_money.dart';
import 'models/goal.dart';

import 'models/enums/account_enums.dart';
import 'models/enums/budget_period.dart';
import 'models/enums/reserved_money_type.dart';
import 'models/enums/goal_status.dart';

import 'models/transaction.dart';
import 'models/ledger_entry.dart';
import 'models/enums/entry_type.dart';
import 'models/enums/ledger_purpose.dart';
import 'models/ledger_account.dart';
import 'models/enums/ledger_account_type.dart';

import 'adapters/account_migration_adapter.dart';

import 'screens/main_navigation.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

import 'services/ledger_stress_test_service.dart';

import 'features/analysis/registry/category_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ====================================================
  // Debug Flags
  // ====================================================

  const bool RESET_DB = true;
  const bool runStressTest = false;
  const bool runActorTest = false;

  // ====================================================
  // Optional DB Reset
  // ====================================================

  if (RESET_DB) {
    await Hive.deleteBoxFromDisk('accounts');
    await Hive.deleteBoxFromDisk('transactions');
    await Hive.deleteBoxFromDisk('ledger_entries');
    await Hive.deleteBoxFromDisk('ledger_accounts');
    await Hive.deleteBoxFromDisk('budgets');
    await Hive.deleteBoxFromDisk('reserved_money');
    await Hive.deleteBoxFromDisk('goals');
    await Hive.deleteBoxFromDisk('members');
  }

  // ====================================================
  // Account & Transaction Adapters
  // ====================================================

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AccountMigrationAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AccountNatureAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AccountGroupAdapter());
  }

  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(TransactionAdapter());
  }

  // ====================================================
  // Ledger Foundation
  // ====================================================

  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(EntryTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(LedgerPurposeAdapter());
  }

  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(LedgerEntryAdapter());
  }

  // ====================================================
  // LedgerAccount Foundation
  // ====================================================

  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(LedgerAccountTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(LedgerAccountAdapter());
  }

  // ====================================================
  // Budget Engine
  // ====================================================

  if (!Hive.isAdapterRegistered(40)) {
    Hive.registerAdapter(BudgetPeriodAdapter());
  }

  if (!Hive.isAdapterRegistered(41)) {
    Hive.registerAdapter(BudgetAdapter());
  }

  // ====================================================
  // Reserved Money Foundation
  // ====================================================

  if (!Hive.isAdapterRegistered(50)) {
    Hive.registerAdapter(ReservedMoneyTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(51)) {
    Hive.registerAdapter(ReservedMoneyAdapter());
  }

  // ====================================================
  // Goals Foundation
  // ====================================================

  if (!Hive.isAdapterRegistered(60)) {
    Hive.registerAdapter(GoalAdapter());
  }

  if (!Hive.isAdapterRegistered(61)) {
    Hive.registerAdapter(GoalStatusAdapter());
  }

  // ====================================================
  // Members Feature
  // ====================================================

  if (!Hive.isAdapterRegistered(70)) {
    Hive.registerAdapter(MemberModelAdapter());
  }

  // ====================================================
  // Open Boxes
  // ====================================================

  await Hive.openBox<Account>('accounts');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<LedgerEntry>('ledger_entries');
  await Hive.openBox<LedgerAccount>('ledger_accounts');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<ReservedMoney>('reserved_money');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<MemberModel>('members');

  // ====================================================
  // Ledger Stress Test
  // ====================================================

  if (runStressTest) {
    try {
      await LedgerStressTestService().runStressTest(
        transactionCount: 300,
        verbose: false,
      );

      debugPrint("✅ Ledger stress test completed");
    } catch (e) {
      debugPrint("⚠️ Stress test failed: $e");
    }
  }

  // ====================================================
  // ActorMemberId Test
  // ====================================================

  if (runActorTest) {
    try {
      final txBox = Hive.box<Transaction>('transactions');

      final testTransaction = Transaction.create(
        amount: 250,
        type: 'expense',
        categoryId: 'food',
        date: DateTime.now(),
        actorMemberId: 'member_test_1',
      );

      final key = await txBox.add(testTransaction);

      final savedTransaction = txBox.get(key);

      debugPrint(
        "✅ Actor test saved successfully: "
        "${savedTransaction?.actorMemberId}",
      );
    } catch (e) {
      debugPrint("⚠️ ActorMemberId test failed: $e");
    }
  }

  // ====================================================
  // Initialize Registries
  // ====================================================

  CategoryRegistry.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MembersController())],
      child: const WafferlyApp(),
    ),
  );
}

class WafferlyApp extends StatelessWidget {
  const WafferlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wafferly',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}
