import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/account.dart';
import 'screens/main_navigation.dart';
import 'models/expense.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';

void main() async {

  // ---------------------------------------------------
  // ⚠️ مهم جدًا
  // ---------------------------------------------------
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------
  // 🔥 Init Hive
  // ---------------------------------------------------
  await Hive.initFlutter();
  await Hive.openBox<Account>('accounts');
final accountsBox = Hive.box<Account>('accounts');

if (accountsBox.isEmpty) {
  accountsBox.addAll([
    Account(name: 'Cash', type: 'cash', currency: 'EGP'),
    Account(name: 'Bank', type: 'bank', currency: 'EGP'),
    Account(name: 'Wallet', type: 'wallet', currency: 'EGP'),
    Account(name: 'Credit Card', type: 'credit', currency: 'EGP'),
  ]);
}

  // ---------------------------------------------------
  // 🧠 Register Adapter
  // ---------------------------------------------------
  Hive.registerAdapter(ExpenseAdapter());

  // ---------------------------------------------------
  // 📦 Open Box
  // ---------------------------------------------------
  await Hive.openBox<Expense>('expenses');

  runApp(const WafferlyApp());
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

      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
      ),

      home: const MainNavigation(),
    );
  }
}
