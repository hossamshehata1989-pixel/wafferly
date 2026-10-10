import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import 'add_credit_card_screen.dart';
import 'credit_card_bank_account_selection_screen.dart';

/// Entry point for the add-credit-card flow. The only primary action is Continue.
class CreditCardIntroScreen extends StatelessWidget {
  const CreditCardIntroScreen({super.key});

  Future<void> _continue(BuildContext context) async {
    final bankAccount = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (_) => const CreditCardBankAccountSelectionScreen(),
      ),
    );
    if (bankAccount == null || !context.mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddCreditCardScreen(bankAccount: bankAccount),
      ),
    );
    if (created == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t.addCreditCard,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: m.typography.title,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use the available body height as well as ResponsiveMetrics. This
          // catches short phones even when the full MediaQuery height sits
          // just above the compact-height breakpoint.
          final compact = m.isCompactHeight || constraints.maxHeight < 640;
          double art(double value) =>
              m.size(value * (compact ? 0.78 : 1.0));

          return Column(
            children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                m.spacing(compact ? 16 : 20),
                compact ? m.space.xs : m.space.md,
                m.spacing(compact ? 16 : 20),
                compact ? m.space.sm : m.space.lg,
              ),
              child: Column(
                children: [
                  SizedBox(height: compact ? m.space.xs : m.space.md),
                  SizedBox(
                    width: art(248),
                    height: art(174),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: art(166),
                          height: art(166),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: .08),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: .16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .12),
                                blurRadius: art(30),
                                spreadRadius: art(5),
                              ),
                            ],
                          ),
                        ),
                        Transform.rotate(
                          angle: -0.10,
                          child: Container(
                            width: art(194),
                            height: art(120),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F766E),
                                  Color(0xFF064E4B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(m.radius.xl),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: .70),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: .20),
                                  blurRadius: art(20),
                                  offset: Offset(0, art(10)),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: art(18),
                                  top: art(27),
                                  child: Container(
                                    width: art(30),
                                    height: art(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6D365),
                                      borderRadius: BorderRadius.circular(m.radius.sm),
                                    ),
                                    child: Icon(
                                      Icons.grid_4x4_rounded,
                                      size: art(19),
                                      color: const Color(0xFF8A6A18),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: art(18),
                                  right: art(18),
                                  bottom: art(25),
                                  child: Container(
                                    height: art(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .15),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: art(18),
                                  right: art(48),
                                  bottom: art(15),
                                  child: Container(
                                    height: art(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .10),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: art(13),
                          top: art(17),
                          child: Container(
                            width: art(44),
                            height: art(44),
                            decoration: const BoxDecoration(
                              color: Color(0xFF35E0B5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: m.icon.medium,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: art(10),
                          bottom: art(15),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.accent,
                            size: m.icon.small,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? m.space.sm : m.space.lg),
                  Text(
                    t.addCreditCard,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? m.text(21) : m.typography.headline,
                    ),
                  ),
                  SizedBox(height: compact ? m.space.xs : m.space.sm),
                  Text(
                    t.creditCardIntroDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: compact ? m.text(12) : m.typography.body,
                      height: compact ? 1.35 : 1.5,
                    ),
                  ),
                  SizedBox(height: compact ? m.space.sm : m.space.lg),
                  Container(
                    padding: EdgeInsets.all(compact ? m.space.sm : m.space.md),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(m.radius.xl),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: .75),
                      ),
                    ),
                    child: Column(
                      children: [
                        _IntroBenefit(
                          metrics: m,
                          compact: compact,
                          icon: Icons.link_rounded,
                          title: t.creditCardIntroLinkedAccountTitle,
                          message: t.creditCardIntroLinkedAccountMessage,
                        ),
                        SizedBox(height: compact ? m.space.xs : m.space.md),
                        _IntroBenefit(
                          metrics: m,
                          compact: compact,
                          icon: Icons.account_balance_wallet_outlined,
                          title: t.creditCardIntroOrganizeTitle,
                          message: t.creditCardIntroOrganizeMessage,
                        ),
                        SizedBox(height: compact ? m.space.xs : m.space.md),
                        _IntroBenefit(
                          metrics: m,
                          compact: compact,
                          icon: Icons.account_balance_wallet_outlined,
                          title: t.creditCardIntroNoBalanceTitle,
                          message: t.creditCardIntroNoBalanceMessage,
                        ),
                        SizedBox(height: compact ? m.space.xs : m.space.md),
                        _IntroBenefit(
                          metrics: m,
                          compact: compact,
                          icon: Icons.verified_user_outlined,
                          title: t.creditCardIntroNoDebitCardTitle,
                          message: t.creditCardIntroNoDebitCardMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              m.spacing(compact ? 12 : 16),
              compact ? m.space.xs : m.space.sm,
              m.spacing(compact ? 12 : 16),
              compact ? m.space.xs : m.space.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .25),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: .06),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: WafferlyButton(
                onPressed: () => _continue(context),
                title: t.continueLabel,
                icon: Icons.arrow_forward_rounded,
                backgroundColor: const Color(0xFF35E0B5),
                foregroundColor: Colors.black,
              ),
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroBenefit extends StatelessWidget {
  const _IntroBenefit({
    required this.metrics,
    required this.compact,
    required this.icon,
    required this.title,
    required this.message,
  });

  final ResponsiveMetrics metrics;
  final bool compact;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: metrics.size(compact ? 36 : 44),
          height: metrics.size(compact ? 36 : 44),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: compact ? metrics.size(18) : metrics.icon.medium,
          ),
        ),
        SizedBox(width: compact ? metrics.space.sm : metrics.space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? metrics.text(12) : metrics.typography.body,
                ),
              ),
              SizedBox(height: metrics.space.xs),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? metrics.text(9.5) : metrics.typography.caption,
                  height: compact ? 1.25 : 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
