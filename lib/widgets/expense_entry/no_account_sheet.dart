// lib/widgets/expense_entry/no_account_sheet.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_sheet/sheet_header.dart';
import '../../screens/accounts/add_account/add_account_screen.dart';
import '../../models/enums/section_type.dart';

class NoAccountSheet extends StatelessWidget {
  const NoAccountSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: 'No Accounts Yet',
          icon: Icons.account_balance_wallet_outlined,
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Create your first account to start recording transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Account'),
              onPressed: () async {
                // ✅ إغلاق الـ Sheet أولاً
                Navigator.of(context).pop();

                // ✅ انتظار بسيط لضمان انتهاء الرسوم المتحركة
                await Future.delayed(const Duration(milliseconds: 180));

                // ✅ التوجه إلى شاشة إنشاء الحساب
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddAccountScreen(sectionType: SectionType.asset),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
