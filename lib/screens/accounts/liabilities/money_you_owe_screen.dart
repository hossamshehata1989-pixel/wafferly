import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../models/enums/section_type.dart';
import '../../../models/enums/liability_category.dart';
import '../../../services/liability_read_service.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../add_account/add_account_screen.dart';
import '../navigation/accounts_navigator.dart';

class MoneyYouOweScreen extends StatelessWidget {
  const MoneyYouOweScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LiabilityReadService();
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          t.moneyYouOwe,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.typography.title),
        ),
      ),
      body: AnimatedBuilder(
        animation: service.listenable,
        builder: (context, _) {
          final creditCards = service.getCategory(types: {'creditCard'});
          final loans = service.getCategory(types: {'loan'});
          final installments = service.getCategory(
            types: {'installment', 'bnpl'},
          );
          final borrowedMoney = service.getCategory(
            types: {'debt', 'moneyBorrowed'},
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              m.spacing(16),
              m.spacing(10),
              m.spacing(16),
              m.spacing(32),
            ),
            children: [
              Text(
                t.manageEachLiabilitySeparately,
                style: TextStyle(color: Colors.white60, fontSize: m.typography.body),
              ),
              SizedBox(height: m.space.md),
              _LiabilityCategoryCard(
                title: t.creditCards,
                subtitle: t.creditCardsSubtitle,
                icon: Icons.credit_card_rounded,
                accent: const Color(0xFFFF3D81),
                accounts: creditCards.accounts,
                totalOutstanding: creditCards.totalOutstanding,
                balanceService: service,
                emptyLabel: t.noCreditCardsYet,
                onTap: () => AccountsNavigator.showLiabilityCategory(
                  context: context,
                  category: LiabilityCategory.creditCards,
                ),
              ),
              SizedBox(height: m.space.sm),
              _LiabilityCategoryCard(
                title: t.loans,
                subtitle: t.loansSubtitle,
                icon: Icons.account_balance_rounded,
                accent: const Color(0xFF4D9CFF),
                accounts: loans.accounts,
                totalOutstanding: loans.totalOutstanding,
                balanceService: service,
                emptyLabel: t.noLoansYet,
                onTap: () => AccountsNavigator.showLiabilityCategory(
                  context: context,
                  category: LiabilityCategory.loans,
                ),
              ),
              SizedBox(height: m.space.sm),
              _LiabilityCategoryCard(
                title: t.installmentsBnpl,
                subtitle: t.installmentsBnplSubtitle,
                icon: Icons.calendar_month_rounded,
                accent: const Color(0xFFFFA52F),
                accounts: installments.accounts,
                totalOutstanding: installments.totalOutstanding,
                balanceService: service,
                emptyLabel: t.noInstallmentPlansYet,
                onTap: () => AccountsNavigator.showLiabilityCategory(
                  context: context,
                  category: LiabilityCategory.installments,
                ),
              ),
              SizedBox(height: m.space.sm),
              _LiabilityCategoryCard(
                title: t.borrowedMoney,
                subtitle: t.borrowedMoneySubtitle,
                icon: Icons.person_rounded,
                accent: const Color(0xFF7C72FF),
                accounts: borrowedMoney.accounts,
                totalOutstanding: borrowedMoney.totalOutstanding,
                balanceService: service,
                emptyLabel: t.noBorrowedMoneyYet,
                onTap: () => AccountsNavigator.showLiabilityCategory(
                  context: context,
                  category: LiabilityCategory.borrowedMoney,
                ),
              ),
              SizedBox(height: m.space.lg),
              WafferlyButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddAccountScreen(
                      sectionType: SectionType.liabilities,
                    ),
                  ),
                ),
                title: t.addOtherLiability,
              ),
            ],
          );
        },
      ),
    );
  }
}


class _LiabilityCategoryCard extends StatelessWidget {
  const _LiabilityCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accounts,
    required this.totalOutstanding,
    required this.balanceService,
    required this.emptyLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Account> accounts;
  final Money totalOutstanding;
  final LiabilityReadService balanceService;
  final String emptyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(m.radius.xl),
      child: Container(
        padding: EdgeInsets.all(m.spacing(16)),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1C2A),
          borderRadius: BorderRadius.circular(m.radius.xl),
          border: Border.all(color: accent.withValues(alpha: .32)),
        ),
        child: Row(
          children: [
            Container(
              width: m.size(52),
              height: m.size(52),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(m.radius.lg),
              ),
              child: Icon(icon, color: accent, size: m.icon.medium),
            ),
            SizedBox(width: m.space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: m.typography.title,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: m.space.xs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: m.typography.caption,
                    ),
                  ),
                  SizedBox(height: m.space.sm),
                  Text(
                    accounts.isEmpty
                        ? emptyLabel
                        : '${accounts.length} ${accounts.length == 1 ? t.account : t.accounts}',
                    style: TextStyle(
                      color: accent,
                      fontSize: m.typography.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: m.space.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${totalOutstanding.toDouble().toStringAsFixed(0)} ${t.currency}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: m.typography.body,
                    ),
                  ),
                ),
                SizedBox(height: m.space.xs),
                Icon(Icons.chevron_right_rounded, color: Colors.white54, size: m.icon.medium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
