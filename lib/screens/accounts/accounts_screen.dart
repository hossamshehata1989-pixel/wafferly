// lib/screens/accounts/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import '../../services/account_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/balance_service.dart';
import '../../models/enums/section_type.dart';
import 'widgets/net_worth_card.dart';

import 'controllers/accounts_screen_controller.dart';
import 'navigation/accounts_navigator.dart';
import 'actions/account_action_handler.dart';
import 'presentation/account_section_definition.dart';
import 'widgets/financial_group_card.dart';
import '../../theme/financial_group_visual_resolver.dart';

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

  SectionType _getSectionTypeFromAccount(Account account) {
    if (account.group == AccountGroup.savings) {
      return SectionType.savings;
    }
    if (account.group == AccountGroup.investments) {
      return SectionType.investments;
    }
    if (account.group == AccountGroup.receivable) {
      return SectionType.receivable;
    }
    if (account.group == AccountGroup.liabilities) {
      return SectionType.liabilities;
    }
    return SectionType.liquidity;
  }

  // ============================================================
  // 🔹 Navigation Methods (Refactored)
  // ============================================================

  Future<void> _addAccount(SectionType sectionType) async {
    final result = await AccountActionHandler.addAccount(
      context: context,
      sectionType: sectionType,
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _editAccount(Account account) async {
    if (account.name == TEMP_DEBT_ACCOUNT_NAME) {
      _showSimpleTempDebtDialog();
      return;
    }
    final result = await AccountActionHandler.editAccount(
      context: context,
      sectionType: _getSectionTypeFromAccount(account),
      account: account,
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // 🔹 Helpers
  // ============================================================

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,###");
    return formatter.format(amount.toInt());
  }

  String _getSectionSubtitle(SectionType sectionType) {
    switch (sectionType) {
      case SectionType.liquidity:
        return 'Cash • Wallet • +2';

      case SectionType.savings:
        return 'Real • Virtual • Circle';

      case SectionType.investments:
        return 'Gold • Stocks • +2';

      case SectionType.liabilities:
        return 'Loans • Cards • +1';

      case SectionType.receivable:
        return 'Friends • Family';
    }
  }

  // ============================================================
  // 🔹 Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final balanceService = BalanceService();
    final isSmallPhone = screenWidth < 380;
    final isTablet = screenWidth >= 600;

    // ============================================================
    // 🔹 Section Definitions (Data-Driven)
    // ============================================================

    final sections = [
      AccountSectionDefinition(
        title: t.moneyYouHave,
        visual: FinancialGroupVisualResolver.resolve(SectionType.liquidity),
        sectionType: SectionType.liquidity,
        isSavings: false,
        selector: (data) => data.liquidity,
      ),
      AccountSectionDefinition(
        title: t.savings,
        visual: FinancialGroupVisualResolver.resolve(SectionType.savings),
        sectionType: SectionType.savings,
        isSavings: true,
        selector: (data) => data.savings,
      ),
      AccountSectionDefinition(
        title: t.investments,
        visual: FinancialGroupVisualResolver.resolve(SectionType.investments),
        sectionType: SectionType.investments,
        isSavings: false,
        selector: (data) => data.investments,
      ),
      AccountSectionDefinition(
        title: t.moneyYouOwe,
        visual: FinancialGroupVisualResolver.resolve(SectionType.liabilities),
        sectionType: SectionType.liabilities,
        isSavings: false,
        selector: (data) => data.liabilities,
      ),
      AccountSectionDefinition(
        title: t.moneyYouWillGet,
        visual: FinancialGroupVisualResolver.resolve(SectionType.receivable),
        sectionType: SectionType.receivable,
        isSavings: false,
        selector: (data) => data.receivable,
      ),
    ];

    return Stack(
      children: [
        Scaffold(
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
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: _accountService.box.listenable(),
            builder: (context, Box<Account> box, _) {
              final accounts = _accountService.getAllActiveAccounts();
              final data = _controller.buildScreenData(
                accounts,
                balanceService,
              );

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
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ...sections.map((section) {
                    final accountsList = section.selector(data);
                    final total = _controller.calculateSectionTotal(
                      accountsList,
                      balanceService,
                    );

                    return SliverToBoxAdapter(
                      child: FinancialGroupCard(
                        title: section.title,
                        subtitle: _getSectionSubtitle(section.sectionType),
                        visual: section.visual,
                        amountText: '${_formatCurrency(total)} ${t.currency}',
                        onTap: () {
                          AccountsNavigator.showGroupAccounts(
                            context: context,
                            title: section.title,
                            sectionType: section.sectionType,
                            isSavings: section.isSavings,
                          );
                        },
                      ),
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
