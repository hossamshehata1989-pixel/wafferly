// main.dart

import 'package:flutter/material.dart';
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
import 'features/settings/controller/settings_controller.dart';
import 'features/analysis/registry/category_registry.dart';

import 'models/allocation.dart';
import 'models/enums/allocation_type.dart';

import 'models/enums/goal_type.dart';

import 'models/goal_activity.dart';

import 'models/commitment.dart';
import 'models/schedule_rule.dart';

import 'models/enums/commitment_type.dart';
import 'models/enums/commitment_status.dart';
import 'models/enums/commitment_amount_mode.dart';
import 'models/enums/frequency.dart';

import 'services/financial_action_engine.dart';
import 'services/providers/commitment_action_provider.dart';
import 'services/schedule_evaluator.dart';

import 'services/transaction_service.dart';

// NEW imports for Engine and Application Service
import 'bootstrap/financial_engine_bootstrap.dart';
import 'financial_engine/engine/financial_operation_engine.dart';
import 'services/transaction_application_service.dart';

import 'services/balance_service.dart';
import 'features/members/services/member_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ====================================================
  // Debug Flags
  // ====================================================

  const bool resetDb =
      false; // Set to true to clear all data on app start (for testing)
  const bool runStressTest = false;
  const bool runActorTest = false;
  const bool runFinancialActionEngineTest = false;

  // ====================================================
  // Optional DB Reset
  // ====================================================

  if (resetDb) {
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

  if (!Hive.isAdapterRegistered(62)) {
    Hive.registerAdapter(GoalTypeAdapter());
  }

  // ====================================================
  // Members Feature
  // ====================================================

  if (!Hive.isAdapterRegistered(70)) {
    Hive.registerAdapter(MemberModelAdapter());
  }

  // ====================================================
  // Allocation Foundation
  // ====================================================

  if (!Hive.isAdapterRegistered(80)) {
    Hive.registerAdapter(AllocationAdapter());
  }

  if (!Hive.isAdapterRegistered(90)) {
    Hive.registerAdapter(GoalActivityAdapter());
  }

  if (!Hive.isAdapterRegistered(81)) {
    Hive.registerAdapter(AllocationTypeAdapter());
  }

  // ====================================================
  // Commitment Foundation
  // ====================================================

  if (!Hive.isAdapterRegistered(91)) {
    Hive.registerAdapter(CommitmentTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(92)) {
    Hive.registerAdapter(CommitmentStatusAdapter());
  }

  if (!Hive.isAdapterRegistered(93)) {
    Hive.registerAdapter(CommitmentAmountModeAdapter());
  }

  if (!Hive.isAdapterRegistered(94)) {
    Hive.registerAdapter(FrequencyAdapter());
  }

  if (!Hive.isAdapterRegistered(95)) {
    Hive.registerAdapter(ScheduleRuleAdapter());
  }

  if (!Hive.isAdapterRegistered(96)) {
    Hive.registerAdapter(CommitmentAdapter());
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
  await MemberSeeder.ensureOwnerExists();
  await Hive.openBox<Allocation>('allocations');
  await Hive.openBox<GoalActivity>('goal_activities');
  await Hive.openBox<Commitment>('commitments');

  await Hive.openBox<ScheduleRule>('schedule_rules');

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
  // Financial Action Engine Test
  // ====================================================

  if (runFinancialActionEngineTest) {
    {
      final engine = FinancialActionEngine(
        providers: [
          CommitmentActionProvider(evaluator: const ScheduleEvaluator()),
        ],
      );

      final contexts = await engine.getActions(today: DateTime.now());

      debugPrint('');
      debugPrint('========== FINANCIAL ACTION ENGINE ==========');
      debugPrint('TOTAL ACTIONS: ${contexts.length}');
      debugPrint('');

      for (final context in contexts) {
        debugPrint(
          '${context.action.state.name.toUpperCase()} | '
          '${context.action.kind.name} | '
          '${context.action.title} | '
          '${context.action.amount}',
        );
      }

      debugPrint('=============================================');
    }
  }

  // ====================================================
  // Initialize Registries
  // ====================================================

  CategoryRegistry.initialize();

  // Create shared services
  final balanceService = BalanceService();
  final transactionBox = Hive.box<Transaction>('transactions');
  // Create engine once
  final engineContext = FinancialEngineBootstrap.create(
    balanceService: balanceService,
    transactionBox: transactionBox,
  );

  final engine = engineContext.engine;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MembersController()),
        ChangeNotifierProvider(
          create: (_) => SettingsController()..loadSettings(),
        ),

        Provider<FinancialOperationEngine>(create: (_) => engine),

        Provider<TransactionApplicationService>(
          create: (_) => TransactionApplicationService(
            engine: engine,
            legacyTransactionService: TransactionService.instance,
          ),
        ),
      ],
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
