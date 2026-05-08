import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/account.dart';
import 'models/account_enums.dart';
import 'models/transaction.dart';
import 'screens/main_navigation.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// 🔥 Init Hive
await Hive.initFlutter();

// 🔥 Debug reset (controlled)
bool RESET_DB = true; // ⚠️ خليها false قبل release

if (RESET_DB) {
  await Hive.deleteBoxFromDisk('accounts');
  await Hive.deleteBoxFromDisk('transactions');
}

  // 🔥 Register Adapters (الصح)
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AccountAdapter());
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

  // 🔥 Open Boxes
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<Transaction>('transactions');

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