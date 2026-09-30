import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../models/enums/liability_category.dart';
import '../../../services/liability_read_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../add_credit_card/add_credit_card_screen.dart';
import '../navigation/accounts_navigator.dart';

class LiabilityCategoryScreen extends StatelessWidget {
  const LiabilityCategoryScreen({super.key, required this.category});

  final LiabilityCategory category;

  @override
  Widget build(BuildContext context) {
    final service = LiabilityReadService();
    final spec = _spec(context, category);
    final metrics = ResponsiveMetrics.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          spec.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: metrics.typography.title,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: service.listenable,
        builder: (context, _) {
          final model = service.getCategory(types: spec.types);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              metrics.spacing(16),
              metrics.spacing(10),
              metrics.spacing(16),
              metrics.spacing(32),
            ),
            children: [
              _CategoryHeader(spec: spec, total: model.totalOutstanding),
              SizedBox(height: metrics.space.lg),
              if (model.accounts.isEmpty)
                _EmptyLiabilityState(
                  spec: spec,
                  onAdd: () => _add(context),
                )
              else
                ...model.accounts.map(
                  (account) => Padding(
                    padding: EdgeInsets.only(bottom: metrics.space.sm),
                    child: _LiabilityAccountTile(
                      account: account,
                      balance: service.outstandingFor(account.id),
                      accent: spec.accent,
                      onTap: () => _openAccount(context, account),
                    ),
                  ),
                ),
              SizedBox(height: metrics.space.sm),
              WafferlyButton(
                onPressed: () => _add(context),
                title: spec.addLabel,
                icon: Icons.add_rounded,
                backgroundColor: spec.accent,
              ),
            ],
          );
        },
      ),
    );
  }

  void _add(BuildContext context) {
    if (category == LiabilityCategory.creditCards) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddCreditCardScreen()),
      );
      return;
    }

    final t = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.workflowUnavailableTitle),
        content: Text(t.workflowUnavailableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  void _openAccount(BuildContext context, Account account) {
    switch (category) {
      case LiabilityCategory.creditCards:
        AccountsNavigator.showCreditCardDetails(
          context: context,
          accountId: account.id,
        );
      case LiabilityCategory.loans:
        AccountsNavigator.showLoanDetails(
          context: context,
          accountId: account.id,
        );
      case LiabilityCategory.installments:
        AccountsNavigator.showInstallmentDetails(
          context: context,
          accountId: account.id,
        );
      case LiabilityCategory.borrowedMoney:
        AccountsNavigator.showBorrowedMoneyDetails(
          context: context,
          accountId: account.id,
        );
    }
  }

  _LiabilityCategorySpec _spec(
    BuildContext context,
    LiabilityCategory category,
  ) {
    final t = AppLocalizations.of(context)!;
    switch (category) {
      case LiabilityCategory.creditCards:
        return _LiabilityCategorySpec(
          title: t.creditCards,
          subtitle: t.creditCardsSubtitle,
          icon: Icons.credit_card_rounded,
          accent: const Color(0xFFFF3D81),
          types: const {'creditCard'},
          addLabel: t.addCreditCard,
        );
      case LiabilityCategory.loans:
        return _LiabilityCategorySpec(
          title: t.loans,
          subtitle: t.loansSubtitle,
          icon: Icons.account_balance_rounded,
          accent: const Color(0xFF4D9CFF),
          types: const {'loan'},
          addLabel: t.addLoan,
        );
      case LiabilityCategory.installments:
        return _LiabilityCategorySpec(
          title: t.installmentsBnpl,
          subtitle: t.installmentsBnplSubtitle,
          icon: Icons.calendar_month_rounded,
          accent: const Color(0xFFFFA52F),
          types: const {'installment', 'bnpl'},
          addLabel: t.addInstallmentBnpl,
        );
      case LiabilityCategory.borrowedMoney:
        return _LiabilityCategorySpec(
          title: t.borrowedMoney,
          subtitle: t.borrowedMoneySubtitle,
          icon: Icons.person_rounded,
          accent: const Color(0xFF7C72FF),
          types: const {'debt', 'moneyBorrowed'},
          addLabel: t.addBorrowedMoney,
        );
    }
  }
}

class _LiabilityCategorySpec {
  const _LiabilityCategorySpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.types,
    required this.addLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Set<String> types;
  final String addLabel;
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.spec, required this.total});

  final _LiabilityCategorySpec spec;
  final Money total;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(m.spacing(18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            spec.accent.withValues(alpha: .24),
            const Color(0xFF0B1B29),
          ],
        ),
        borderRadius: BorderRadius.circular(m.radius.xl),
        border: Border.all(color: spec.accent.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Icon(spec.icon, color: spec.accent, size: m.icon.large),
          SizedBox(width: m.space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: m.space.xs),
                Text(
                  spec.subtitle,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: m.typography.caption,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: m.space.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.outstanding,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: m.typography.caption,
                  ),
                ),
                SizedBox(height: m.space.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${total.toDouble().toStringAsFixed(0)} ${t.currency}',
                    style: TextStyle(
                      color: spec.accent,
                      fontSize: m.text(17),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiabilityAccountTile extends StatelessWidget {
  const _LiabilityAccountTile({
    required this.account,
    required this.balance,
    required this.accent,
    required this.onTap,
  });

  final Account account;
  final Money balance;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: m.space.sm,
        vertical: m.space.xs,
      ),
      tileColor: const Color(0xFF0C1C2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m.radius.lg),
        side: BorderSide(color: accent.withValues(alpha: .24)),
      ),
      leading: CircleAvatar(
        radius: m.size(22),
        backgroundColor: accent.withValues(alpha: .14),
        child: Icon(_icon(account.type), color: accent, size: m.icon.medium),
      ),
      title: Text(
        account.name,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: m.typography.body,
        ),
      ),
      subtitle: Text(
        _subtitle(t, account.type),
        style: TextStyle(color: Colors.white54, fontSize: m.typography.caption),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: m.size(110)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${balance.toDouble().toStringAsFixed(0)} ${account.currency}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: m.typography.body,
                ),
              ),
            ),
          ),
          SizedBox(width: m.space.xs),
          Icon(Icons.chevron_right_rounded, color: Colors.white54, size: m.icon.medium),
        ],
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'creditCard':
        return Icons.credit_card_rounded;
      case 'loan':
        return Icons.account_balance_rounded;
      case 'installment':
      case 'bnpl':
        return Icons.calendar_month_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _subtitle(AppLocalizations t, String type) {
    switch (type) {
      case 'creditCard':
        return t.creditCard;
      case 'loan':
        return t.loan;
      case 'installment':
      case 'bnpl':
        return t.installment;
      default:
        return t.borrowedMoney;
    }
  }
}

class _EmptyLiabilityState extends StatelessWidget {
  const _EmptyLiabilityState({required this.spec, required this.onAdd});

  final _LiabilityCategorySpec spec;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(m.spacing(24)),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1C2A),
        borderRadius: BorderRadius.circular(m.radius.xl),
        border: Border.all(color: spec.accent.withValues(alpha: .22)),
      ),
      child: Column(
        children: [
          Icon(spec.icon, size: m.icon.hero, color: spec.accent.withValues(alpha: .8)),
          SizedBox(height: m.space.md),
          Text(
            '${t.noItemsYetPrefix} ${spec.title.toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: m.typography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: m.space.xs),
          Text(
            t.liabilityCategoryAlwaysVisible,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: m.typography.body),
          ),
          SizedBox(height: m.space.md),
          WafferlyButton(
            onPressed: onAdd,
            title: spec.addLabel,
            icon: Icons.add_rounded,
            fullWidth: false,
            backgroundColor: spec.accent,
          ),
        ],
      ),
    );
  }
}
