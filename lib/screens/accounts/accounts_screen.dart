// lib/screens/accounts/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import '../../services/account_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/balance_service.dart';
import 'add_account/add_account_screen.dart';
import '../../models/enums/section_type.dart';
import '../../utils/account_mapper.dart';
import 'package:wafferly/screens/accounts/group_accounts_screen.dart';
import 'widgets/section_summary_card.dart';
import 'widgets/net_worth_card.dart';
import 'controllers/accounts_screen_controller.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = AccountService();

  final AccountsScreenController _controller = AccountsScreenController();

  static const String TEMP_DEBT_ACCOUNT_NAME = 'دين مؤقت';

  void _showSimpleTempDebtDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.tempDebtTitle),
        content: Text(t.tempDebtDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.incomeLinkingComingSoon)),
              );
            },
            child: Text(t.settleNow),
          ),
        ],
      ),
    );
  }

  SectionType _getSectionTypeFromString(String sectionType) {
    switch (sectionType) {
      case 'asset':
        return SectionType.asset;
      case 'liability':
        return SectionType.liability;
      case 'investment':
        return SectionType.investment;
      case 'receivable':
        return SectionType.receivable;
      case 'saving':
        return SectionType.saving;
      default:
        return SectionType.asset;
    }
  }

  SectionType _getSectionTypeFromAccount(Account account) {
    if (account.group == AccountGroup.savings) {
      return SectionType.saving;
    }
    if (account.group == AccountGroup.investments) {
      return SectionType.investment;
    }
    if (account.group == AccountGroup.receivable) {
      return SectionType.receivable;
    }
    if (account.group == AccountGroup.liabilities) {
      return SectionType.liability;
    }
    return SectionType.asset;
  }

  void _addAccount(String sectionType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(
          sectionType: _getSectionTypeFromString(sectionType),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _editAccount(Account account) {
    if (account.name == TEMP_DEBT_ACCOUNT_NAME) {
      _showSimpleTempDebtDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(
          sectionType: _getSectionTypeFromAccount(account),
          accountToEdit: account,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final balanceService = BalanceService();
    final isSmallPhone = screenWidth < 380;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          t.accounts,
          style: TextStyle(
            fontSize: isSmallPhone ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),

      // TODO:
      // Replace ValueListenableBuilder with AnimatedBuilder
      // listening to Accounts + Transactions boxes.
      body: ValueListenableBuilder(
        valueListenable: _accountService.box.listenable(),
        builder: (context, Box<Account> box, _) {
          final accounts = _accountService.getAllActiveAccounts();

          // DEBUG مؤقت
          for (final a in accounts) {
            print(
              'DEBUG: ${a.name} | '
              'type=${a.type} | '
              'storedGroup=${a.group} | '
              'resolvedGroup=${resolveGroup(a.type)}',
            );
          }

          final data = _controller.buildScreenData(accounts, balanceService);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: NetWorthCard(
                  netWorth: data.netWorth,
                  totalAssets: data.totalAssets,
                  totalLiabilities: data.totalLiabilities,
                  isTablet: isTablet,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)), // Spacing
              _buildSection(
                // 💰 Money You Have
                t.moneyYouHave,
                Icons.account_balance_wallet,
                data.moneyHave,
                balanceService,
                Colors.green,
                isTablet,
                isLargeTablet,
                () => _addAccount('asset'),
                false,
              ),
              _buildSection(
                //
                t.savings,
                Icons.savings,
                data.savings,
                balanceService,
                Colors.teal,
                isTablet,
                isLargeTablet,
                () => _addAccount('saving'),
                false,
              ),
              _buildSection(
                t.investments,
                Icons.trending_up,
                data.investments,
                balanceService,
                Colors.orange,
                isTablet,
                isLargeTablet,
                () => _addAccount('investment'),
                false,
              ),
              _buildSection(
                t.moneyYouOwe,
                Icons.credit_card,
                data.liabilities,
                balanceService,
                Colors.red,
                isTablet,
                isLargeTablet,
                () => _addAccount('liability'),
                false,
              ),
              _buildSection(
                t.moneyYouWillGet,
                Icons.handshake,
                data.receivables,
                balanceService,
                Colors.blue,
                isTablet,
                isLargeTablet,
                () => _addAccount('receivable'),
                false,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Account> accounts,
    BalanceService balanceService,
    Color color,
    bool isTablet,
    bool isLargeTablet,
    VoidCallback onAddTap,
    bool showAddButton,
  ) {
    final t = AppLocalizations.of(context)!;
    final sectionTotal = _controller.calculateSectionTotal(
      accounts,
      balanceService,
    );
    final formatter = NumberFormat("#,###");
    return SliverToBoxAdapter(
      child: SectionSummaryCard(
        title: title,
        icon: icon,
        amountText: '${formatter.format(sectionTotal.toInt())} ${t.currency}',
        accountsCount: accounts.length,
        color: color,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupAccountsScreen(
                title: title,
                isSavings: _controller.isSavingsSection(title),
                sectionType: _controller.getSectionType(title),
              ),
            ),
          );
        },
      ),
    );
  }
}
