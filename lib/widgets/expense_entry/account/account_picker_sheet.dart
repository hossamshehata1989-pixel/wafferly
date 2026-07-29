// lib/widgets/expense_entry/account/account_picker_sheet.dart

import 'package:flutter/material.dart';
import '../../../controllers/transaction_entry_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../screens/accounts/add_account/add_account_screen.dart';
import '../../../models/enums/section_type.dart';
import '../../../models/account_display_extension.dart';
import '../../../widgets/bottom_sheet/wafferly_bottom_sheet.dart';
import '../../bottom_sheet/sheet_header.dart';
import '../../bottom_sheet/sheet_footer.dart';
import '../account_card.dart';
import '../../../services/balance_service.dart';
import '../../../theme/app_colors.dart'; // ✅ إضافة الاستيراد المفقود

Future<void> showAccountPickerSheet(
  BuildContext context,
  TransactionEntryController controller,
) async {
  final accounts = controller.availableAccounts;

  if (accounts.isEmpty) {
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No accounts found'),
        content: const Text('You need to create an account first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );

    if (create == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddAccountScreen(sectionType: SectionType.liquidity),
        ),
      );

      if (context.mounted) {
        await showAccountPickerSheet(context, controller);
      }
    }

    return;
  }

  final balanceService = BalanceService();

  // ✅ 2. استخدام حيثية مستقرة لتقديم الحساب المختار أولاً
  final selectedAccount = accounts.where(
    (a) => a.id == controller.selectedAccountId,
  );
  final otherAccounts = accounts.where(
    (a) => a.id != controller.selectedAccountId,
  );
  final sortedAccounts = [...selectedAccount, ...otherAccounts];

  await WafferlyBottomSheet.show(
    context: context,
    scrollable: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: AppLocalizations.of(context)!.selectAccount,
          subtitle: 'Choose where the transaction will be recorded',
          icon: Icons.account_balance_wallet_outlined,
          onClose: () => Navigator.pop(context),
        ),

        const SizedBox(height: 20),

        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
          child: ListView(
            shrinkWrap: true,
            children: sortedAccounts.map((acc) {
              final selected = acc.id == controller.selectedAccountId;

              final balance = balanceService.getAvailableBalance(acc.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AccountCard(
                  icon: acc.display.icon,
                  iconColor: acc.display.color,
                  title: acc.name,
                  balance: '${acc.currency} ${balance.toStringAsFixed(0)}',
                  selected: selected,
                  onTap: () {
                    controller.selectAccount(acc.id, acc.name);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        SheetFooter(
          actions: [
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddAccountScreen(sectionType: SectionType.liquidity),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
