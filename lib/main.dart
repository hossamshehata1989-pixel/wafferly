// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/account.dart';
import 'models/enums/account_enums.dart';
import 'models/transaction.dart';
import 'models/ledger_entry.dart'; // ✅ LedgerEntry model
import 'models/enums/entry_type.dart'; // ✅ EntryType enum
import 'models/enums/ledger_purpose.dart'; // ✅ LedgerPurpose enum
import 'models/ledger_account.dart'; // ✅ Sprint 3B - LedgerAccount model
import 'models/enums/ledger_account_type.dart'; // ✅ Sprint 3B - LedgerAccountType enum
import 'adapters/account_migration_adapter.dart';
import 'screens/main_navigation.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'services/ledger_stress_test_service.dart'; // TEMP for stress testing

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
  }

  // ========== Account & Transaction Adapters (existing) ==========
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(
      AccountMigrationAdapter(),
    ); // TEMPORARY migration adapter
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

  // ========== Ledger Foundation (Sprint 2) ==========
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(EntryTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(LedgerPurposeAdapter());
  }

  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(LedgerEntryAdapter());
  }

  // ========== LedgerAccount Foundation (Sprint 3B) ==========
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(LedgerAccountTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(LedgerAccountAdapter());
  }

  // ========== Open Boxes ==========
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<LedgerEntry>('ledger_entries');
  await Hive.openBox<LedgerAccount>('ledger_accounts');

  // ========== TEMP TEST ONLY (Stress Test) ==========
  // ⚠️ هذا السطر مؤقت للاختبار فقط – سيتم إزالته بعد Sprint 4B
  try {
    await LedgerStressTestService().runStressTest(
      transactionCount: 3000,
      verbose: true,
    );
  } catch (e) {
    print("⚠️ Stress test failed: $e");
  }
  // ===================================================

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

      home: const MainNavigation(),
    );
  }
}
