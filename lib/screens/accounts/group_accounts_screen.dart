import 'package:flutter/material.dart';
import '../savings/virtual_saving_screen.dart';
import 'add_account/add_account_screen.dart';
import '../../models/enums/section_type.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../models/enums/account_enums.dart';
import '../../services/balance_service.dart';
import '../../theme/section_type_visual.dart';
import 'widgets/account_card.dart';
import '../../theme/financial_group_visual_mapper.dart';
import '../../theme/account_asset_resolver.dart';

class GroupAccountsScreen extends StatelessWidget {
  final String title;
  final bool isSavings;
  final SectionType sectionType;
  final AccountService _accountService = AccountService();
  final BalanceService _balanceService = BalanceService();

  GroupAccountsScreen({
    super.key,
    required this.title,
    required this.sectionType,
    this.isSavings = false,
  });

  @override
  Widget build(BuildContext context) {
    print('NEW GROUP SCREEN');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ValueListenableBuilder(
        valueListenable: _accountService.box.listenable(),
        builder: (context, Box<Account> box, _) {
          final allAccounts = _accountService.getAllActiveAccounts();

          final accounts = allAccounts.where((a) {
            switch (sectionType) {
              case SectionType.liquidity:
                return a.group == AccountGroup.liquidity;
              case SectionType.savings:
                return a.group == AccountGroup.savings;
              case SectionType.investments:
                return a.group == AccountGroup.investments;
              case SectionType.liabilities:
                return a.group == AccountGroup.liabilities;
              case SectionType.receivable:
                return a.group == AccountGroup.receivable;
            }
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                if (accounts.isEmpty) ...[
                  const Text(
                    'No Accounts Yet',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create your first account to start tracking balances and transactions.',
                  ),
                ] else ...[
                  ...accounts.map(
                    (account) => AccountCard(
                      name: account.name,
                      subtitle: account.type,
                      balanceText:
                          '${_balanceService.getBalance(account.id).toStringAsFixed(0)} EGP',

                      iconAsset:
                          account.icon ??
                          AccountAssetResolver.defaultIcon(sectionType),
                      visual: sectionType.groupVisual.toEntityVisual(),

                      onTap: () {
                        // TODO
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddAccountScreen(sectionType: sectionType),
                        ),
                      );
                    },
                    child: const Text('Create Account'),
                  ),
                ),
                if (isSavings) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildVirtualSavingCard(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVirtualSavingCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VirtualSavingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Virtual Saving',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Reserved money for goals, buckets and future planning.'),
          ],
        ),
      ),
    );
  }
}
