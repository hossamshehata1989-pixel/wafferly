// lib/screens/accounts/presentation/account_section_definition.dart

import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../models/enums/section_type.dart';
import '../models/accounts_screen_data.dart';

/// تعريف ثابت لقسم واحد في شاشة Accounts.
///
/// هذا الكلاس مسؤول عن:
/// - وصف القسم (العنوان، الأيقونة، اللون، النوع).
/// - توفير `selector` لاستخراج الحسابات المناسبة من `AccountsScreenData`.
///
/// لا يحتوي على أي Business Logic.
/// لا يحتوي على أي حسابات.
/// فقط تعريف للـ UI.
class AccountSectionDefinition {
  const AccountSectionDefinition({
    required this.title,
    required this.icon,
    required this.color,
    required this.sectionType,
    required this.isSavings,
    required this.selector,
  });

  final String title;
  final IconData icon;
  final Color color;
  final SectionType sectionType;
  final bool isSavings;
  final List<Account> Function(AccountsScreenData data) selector;
}
