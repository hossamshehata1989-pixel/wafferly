import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../models/enums/section_type.dart';
import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';
import '../add_account/add_account_screen.dart';
import '../add_credit_card/add_credit_card_screen.dart';
import '../navigation/accounts_navigator.dart';
import 'money_you_owe_screen.dart';

class LiabilityCategoryScreen extends StatelessWidget {
  const LiabilityCategoryScreen({super.key, required this.category});

  final LiabilityCategory category;

  @override
  Widget build(BuildContext context) {
    final service = AccountService();
    final balances = BalanceService();
    final spec = _spec(category);

    return Scaffold(
      backgroundColor: const Color(0xFF031722),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(spec.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ValueListenableBuilder(
        valueListenable: service.box.listenable(),
        builder: (context, Box<Account> _, __) {
          final accounts = service.getAllActiveAccounts()
              .where((a) => a.group == AccountGroup.liabilities && spec.matches(a.type))
              .toList();
          final total = accounts.fold<double>(0, (sum, a) => sum + (-balances.getBalance(a.id)).clamp(0, double.infinity).toDouble());

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [spec.accent.withValues(alpha: .24), const Color(0xFF0B1B29)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: spec.accent.withValues(alpha: .45)),
                ),
                child: Row(
                  children: [
                    Icon(spec.icon, color: spec.accent, size: 34),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(spec.title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(spec.subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Outstanding', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text('${total.toStringAsFixed(0)} EGP', style: TextStyle(color: spec.accent, fontSize: 17, fontWeight: FontWeight.w800)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (accounts.isEmpty)
                _EmptyLiabilityState(spec: spec, onAdd: () => _add(context))
              else
                ...accounts.map((account) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LiabilityAccountTile(
                    account: account,
                    balance: (-balances.getBalance(account.id)).clamp(0, double.infinity).toDouble(),
                    accent: spec.accent,
                    onTap: () => _openAccount(context, account),
                  ),
                )),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(spec.addLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  void _add(BuildContext context) {
    if (category == LiabilityCategory.creditCards) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCreditCardScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(sectionType: SectionType.liabilities)));
  }

  void _openAccount(BuildContext context, Account account) {
    if (account.type == 'creditCard') {
      AccountsNavigator.showCreditCardDetails(context: context, accountId: account.id);
      return;
    }
    AccountsNavigator.showLiabilityAccountDetails(context: context, accountId: account.id);
  }

  _LiabilityCategorySpec _spec(LiabilityCategory category) {
    switch (category) {
      case LiabilityCategory.creditCards:
        return _LiabilityCategorySpec('Credit Cards', 'Cards, limits, statements and purchases', Icons.credit_card_rounded, const Color(0xFFFF3D81), const {'creditCard'}, 'Add Credit Card');
      case LiabilityCategory.loans:
        return _LiabilityCategorySpec('Loans', 'Principal, payments and due dates', Icons.account_balance_rounded, const Color(0xFF4D9CFF), const {'loan'}, 'Add Loan');
      case LiabilityCategory.installments:
        return _LiabilityCategorySpec('Installments / BNPL', 'Installment plans and buy-now-pay-later', Icons.calendar_month_rounded, const Color(0xFFFFA52F), const {'installment', 'bnpl'}, 'Add Installment / BNPL');
      case LiabilityCategory.borrowedMoney:
        return _LiabilityCategorySpec('Borrowed Money', 'Money borrowed from people or other sources', Icons.person_rounded, const Color(0xFF7C72FF), const {'debt', 'moneyBorrowed'}, 'Add Borrowed Money');
    }
  }
}

class _LiabilityCategorySpec {
  const _LiabilityCategorySpec(this.title, this.subtitle, this.icon, this.accent, this.types, this.addLabel);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Set<String> types;
  final String addLabel;
  bool matches(String type) => types.contains(type);
}

class _LiabilityAccountTile extends StatelessWidget {
  const _LiabilityAccountTile({required this.account, required this.balance, required this.accent, required this.onTap});
  final Account account;
  final double balance;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      tileColor: const Color(0xFF0C1C2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: accent.withValues(alpha: .24))),
      leading: CircleAvatar(backgroundColor: accent.withValues(alpha: .14), child: Icon(_icon(account.type), color: accent)),
      title: Text(account.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      subtitle: Text(_subtitle(account), style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${balance.toStringAsFixed(0)} ${account.currency}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const Icon(Icons.chevron_right_rounded, color: Colors.white54),
      ]),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'creditCard': return Icons.credit_card_rounded;
      case 'loan': return Icons.account_balance_rounded;
      case 'installment':
      case 'bnpl': return Icons.calendar_month_rounded;
      default: return Icons.person_rounded;
    }
  }

  String _subtitle(Account account) {
    switch (account.type) {
      case 'creditCard': return 'Credit Card';
      case 'loan': return 'Loan';
      case 'installment':
      case 'bnpl': return 'Installment / BNPL';
      default: return 'Borrowed Money';
    }
  }
}

class _EmptyLiabilityState extends StatelessWidget {
  const _EmptyLiabilityState({required this.spec, required this.onAdd});
  final _LiabilityCategorySpec spec;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: const Color(0xFF0C1C2A), borderRadius: BorderRadius.circular(20), border: Border.all(color: spec.accent.withValues(alpha: .22))),
      child: Column(children: [
        Icon(spec.icon, size: 44, color: spec.accent.withValues(alpha: .8)),
        const SizedBox(height: 14),
        Text('No ${spec.title.toLowerCase()} yet', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text('This category stays visible even when you have no accounts in it.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(spec.addLabel)),
      ]),
    );
  }
}
