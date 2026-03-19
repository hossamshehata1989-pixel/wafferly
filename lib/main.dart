import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Screens
import 'screens/main_navigation.dart';

/// Localization
import 'l10n/app_localizations.dart';

/// Theme
import 'theme/app_colors.dart';

/// Models
import 'models/expense.dart';

void main() async {

  // ---------------------------------------------------
  // ⚠️ مهم جدًا
  // ---------------------------------------------------
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------
  // 🔥 Init Hive
  // ---------------------------------------------------
  await Hive.initFlutter();

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