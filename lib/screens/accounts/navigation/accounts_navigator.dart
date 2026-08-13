// lib/screens/accounts/navigation/accounts_navigator.dart

import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../models/enums/section_type.dart';
import '../add_account/add_account_screen.dart';
import '../group_accounts_screen.dart';
import '../accounts_group/accounts_group_details_screen/accounts_group_details_screen.dart';
import '../account_details_screen.dart';

/// Centralized navigation for the Accounts module only.
///
/// Responsible only for navigation between Accounts screens.
///
/// This class intentionally does not contain:
/// - Business Logic
/// - Financial Calculations
/// - Account Mapping
///
/// Any future navigation changes (Dialog, BottomSheet, Router)
/// should be implemented here.
abstract final class AccountsNavigator {
  AccountsNavigator._();

  // ============================================================
  // 🔹 Add Account (إنشاء حساب جديد)
  // ============================================================

  /// يفتح شاشة إنشاء حساب جديد.
  ///
  /// يرجع `true` لو تم الحفظ بنجاح، أو `false`/`null` لو تم الإلغاء.
  static Future<bool?> showCreateAccount({
    required BuildContext context,
    required SectionType sectionType,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(sectionType: sectionType),
      ),
    );
  }

  // ============================================================
  // 🔹 Edit Account (تعديل حساب موجود)
  // ============================================================

  /// يفتح شاشة تعديل حساب موجود.
  ///
  /// يرجع `true` لو تم التعديل بنجاح، أو `false`/`null` لو تم الإلغاء.
  static Future<bool?> showEditAccount({
    required BuildContext context,
    required SectionType sectionType,
    required Account account,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddAccountScreen(sectionType: sectionType, accountToEdit: account),
      ),
    );
  }

  // ============================================================
  // 🔹 Group Accounts (عرض حسابات مجموعة)
  // ============================================================

  /// يفتح شاشة عرض حسابات مجموعة معينة.
  static Future<void> showGroupAccounts({
    required BuildContext context,
    required String title,
    required SectionType sectionType,
    bool isSavings = false,
  }) {
    // Liquidity now uses the new AccountsGroupDetailsScreen.
    // Other account groups keep the existing GroupAccountsScreen.
    if (sectionType == SectionType.liquidity) {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountsGroupDetailsScreen()),
      );
    }

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupAccountsScreen(
          title: title,
          sectionType: sectionType,
          isSavings: isSavings,
        ),
      ),
    );
  }

  // ============================================================
  // 🔹 Account Details (تفاصيل حساب)
  // ============================================================

  /// يفتح شاشة تفاصيل حساب معين.
  static Future<void> showAccountDetails({
    required BuildContext context,
    required String accountId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailsScreen(accountId: accountId),
      ),
    );
  }
}
