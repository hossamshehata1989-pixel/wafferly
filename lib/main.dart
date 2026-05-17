// main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/account.dart';
import 'models/budget.dart';
import 'models/enums/account_enums.dart';
import 'models/enums/budget_period.dart';
import 'models/transaction.dart';
import 'models/ledger_entry.dart';
import 'models/enums/entry_type.dart';
import 'models/enums/ledger_purpose.dart';
import 'models/ledger_account.dart';
import 'models/enums/ledger_account_type.dart';
import 'adapters/account_migration_adapter.dart';
import 'screens/main_navigation.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'services/ledger_stress_test_service.dart';
import 'features/analysis/registry/category_registry.dart';
import 'screens/planning/planning_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Optional: reset for debugging
  bool RESET_DB = false;
  if (RESET_DB) {
    await Hive.deleteBoxFromDisk('accounts');
    await Hive.deleteBoxFromDisk('transactions');
    await Hive.deleteBoxFromDisk('ledger_entries');
    await Hive.deleteBoxFromDisk('ledger_accounts');
    await Hive.deleteBoxFromDisk('budgets');
  }

  // ========== Account & Transaction Adapters ==========
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

  // ========== Ledger Foundation ==========
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(EntryTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(LedgerPurposeAdapter());
  }

  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(LedgerEntryAdapter());
  }

  // ========== LedgerAccount Foundation ==========
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(LedgerAccountTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(LedgerAccountAdapter());
  }

  // ========== Budget Engine ==========
  if (!Hive.isAdapterRegistered(40)) {
    Hive.registerAdapter(BudgetPeriodAdapter());
  }

  if (!Hive.isAdapterRegistered(41)) {
    Hive.registerAdapter(BudgetAdapter());
  }

  // ========== Open Boxes ==========
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<LedgerEntry>('ledger_entries');
  await Hive.openBox<LedgerAccount>('ledger_accounts');
  await Hive.openBox<Budget>('budgets');

  // ========== TEMP TEST ONLY (Stress Test) ==========
  // ⚠️ هذا السطر مؤقت للاختبار فقط – سيتم إزالته بعد Sprint 4B
  // try {
  //   await LedgerStressTestService().runStressTest(
  //     transactionCount: 10,
  //     verbose: false,
  //   );
  // } catch (e) {
  //   print("⚠️ Stress test failed: $e");
  // }
  // ===================================================

  // ✅ IMPORTANT: Initialize CategoryRegistry BEFORE runApp
  CategoryRegistry.initialize();

  runApp(const WafferlyApp());
}

class WafferlyApp extends StatelessWidget {
  const WafferlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wafferly',
      debugShowCheckedModeBanner: false,

      // 🌍 Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // 🎨 Theme
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
      ),

      home: const PlanningScreen(),
    );
  }
}
