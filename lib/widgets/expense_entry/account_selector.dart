// lib/widgets/expense_entry/account_selector.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../models/account_display_extension.dart';
import '../../widgets/bottom_sheet/wafferly_bottom_sheet.dart';
import 'account_picker_sheet.dart';

class AccountSelector {
  static Future<void> show({
    required BuildContext context,
    required TransactionEntryController controller,
    required GlobalKey anchorKey,
  }) async {
    final accounts = controller.availableAccounts;
    final count = accounts.length;

    // 1. حساب واحد → لا تفعل شيئًا
    if (count <= 1) {
      return;
    }

    // 2. حسابان → Toggle مباشر
    if (count == 2) {
      final currentIndex = accounts.indexWhere(
        (a) => a.id == controller.selectedAccountId,
      );

      final nextIndex = currentIndex == 0 ? 1 : 0;

      final nextAccount = accounts[nextIndex];

      controller.selectAccount(nextAccount.id, nextAccount.name);

      return;
    }

    // 3. 3 حسابات أو أكثر → BottomSheet
    await showAccountPickerSheet(context, controller);
  }
}
