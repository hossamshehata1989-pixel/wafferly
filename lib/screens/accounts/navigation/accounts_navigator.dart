// lib/screens/accounts/navigation/accounts_navigator.dart

import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../models/enums/section_type.dart';
import '../../../models/enums/liability_category.dart';
import '../add_account/add_account_screen.dart';
import '../add_credit_card/credit_card_intro_screen.dart';
import '../group_accounts_screen.dart';
import '../accounts_group/accounts_group_details_screen/accounts_group_details_screen.dart';
import '../account_deatails/account_details_screen.dart';
import '../liabilities/money_you_owe_screen.dart';
import '../liabilities/liability_category_screen.dart';
import '../liabilities/credit_card_account_details_screen.dart';
import '../liabilities/liability_account_details_screen.dart';

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
  // 🔹 Create Credit Card
  // ============================================================

  static Future<bool?> showCreateCreditCard({
    required BuildContext context,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreditCardIntroScreen()),
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

    if (sectionType == SectionType.liabilities) {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoneyYouOweScreen()),
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


  static Future<void> showLiabilityCategory({
    required BuildContext context,
    required LiabilityCategory category,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiabilityCategoryScreen(category: category),
      ),
    );
  }

  static Future<void> showCreditCardDetails({
    required BuildContext context,
    required String accountId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardAccountDetailsScreen(accountId: accountId),
      ),
    );
  }

  static Future<void> showLiabilityAccountDetails({
    required BuildContext context,
    required String accountId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiabilityAccountDetailsScreen(accountId: accountId),
      ),
    );
  }

  static Future<void> showLoanDetails({
    required BuildContext context,
    required String accountId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiabilityAccountDetailsScreen(accountId: accountId),
      ),
    );
  }

  static Future<void> showInstallmentDetails({
    required BuildContext context,
    required String accountId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiabilityAccountDetailsScreen(accountId: accountId),
      ),
    );
  }

  static Future<void> showBorrowedMoneyDetails({
    required BuildContext context,
    required String accountId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiabilityAccountDetailsScreen(accountId: accountId),
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
