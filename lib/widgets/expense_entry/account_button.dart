// lib/widgets/expense_entry/account_button.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import '../../features/transactions/models/entry_mode.dart';
import '../../models/account_display_extension.dart';
import 'account_selector.dart';

class AccountButton extends StatefulWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final EntryMode mode;

  const AccountButton({
    super.key,
    required this.controller,
    required this.metrics,
    required this.mode,
  });

  @override
  State<AccountButton> createState() => _AccountButtonState();
}

class _AccountButtonState extends State<AccountButton> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final accounts = widget.controller.availableAccounts;
        final selectedId = widget.controller.selectedAccountId;

        // البحث عن الحساب المحدد
        final selectedAccount = accounts
            .where((acc) => acc.id == selectedId)
            .firstOrNull;

        // إذا لم يكن هناك أي حساب، نعرض عنصرًا احتياطيًا
        if (selectedAccount == null) {
          return Container(
            key: _anchorKey,
            height: widget.metrics.width < 360
                ? widget.metrics.h(38)
                : widget.metrics.h(45),
            decoration: BoxDecoration(
              color: AppColors.calculatorButton,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Colors.white54,
                ),
                SizedBox(width: 6),
                Text('No Account', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        final display = selectedAccount.display;
        final accountCount = accounts.length;

        return AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: Container(
            key: _anchorKey,
            child: InkWell(
              onTap: _handleTap,
              splashColor: display.color.withValues(alpha: 0.18),
              highlightColor: display.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,

                height: widget.metrics.width < 360
                    ? widget.metrics.h(38)
                    : widget.metrics.h(45),

                decoration: BoxDecoration(
                  color: AppColors.calculatorButton,

                  borderRadius: BorderRadius.circular(10),

                  border: Border.all(
                    color: display.color.withValues(alpha: 0.20),
                  ),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ أيقونة الحساب المحدد بلونه
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.85,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        display.icon,
                        key: ValueKey(selectedAccount.id),
                        size: widget.metrics.size(15),
                        color: display.color,
                      ),
                    ),
                    SizedBox(width: widget.metrics.spacing(4)),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          selectedAccount.name,
                          key: ValueKey(selectedAccount.id),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: widget.metrics.text(11),
                          ),
                        ),
                      ),
                    ),
                    if (accountCount > 1) ...[
                      const SizedBox(width: 4),
                      // ✅ سهم بلون الحساب مع شفافية
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: display.color.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap() async {
    setState(() => _pressed = true);

    await Future.delayed(const Duration(milliseconds: 80));

    if (mounted) {
      setState(() => _pressed = false);
    }

    if (!mounted) return;

    await AccountSelector.show(
      context: context,
      controller: widget.controller,
      anchorKey: _anchorKey,
    );
  }
}
