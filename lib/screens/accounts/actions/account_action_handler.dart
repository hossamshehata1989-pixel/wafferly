// lib/screens/accounts/actions/account_action_handler.dart

import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../models/enums/section_type.dart';
import '../navigation/accounts_navigator.dart';

/// مسؤول عن تنفيذ إجراءات الحسابات (Actions) فقط.
///
/// لا يحتوي على:
/// - Business Rules
/// - UI Decisions (Dialogs, etc.)
/// - Mapping
/// - Refresh Logic
///
/// فقط يستدعي AccountsNavigator ويعيد نتيجة العملية.
abstract final class AccountActionHandler {
  AccountActionHandler._();

  // ============================================================
  // 🔹 Add Account
  // ============================================================

  /// ينفذ عملية إنشاء حساب جديد.
  ///
  /// يرجع `true` لو تم الحفظ بنجاح، أو `false`/`null` لو تم الإلغاء.
  static Future<bool?> addAccount({
    required BuildContext context,
    required SectionType sectionType,
  }) {
    return AccountsNavigator.showCreateAccount(
      context: context,
      sectionType: sectionType,
    );
  }

  // ============================================================
  // 🔹 Edit Account
  // ============================================================

  /// ينفذ عملية تعديل حساب موجود.
  ///
  /// يرجع `true` لو تم التعديل بنجاح، أو `false`/`null` لو تم الإلغاء.
  static Future<bool?> editAccount({
    required BuildContext context,
    required SectionType sectionType,
    required Account account,
  }) {
    return AccountsNavigator.showEditAccount(
      context: context,
      sectionType: sectionType,
      account: account,
    );
  }
}
