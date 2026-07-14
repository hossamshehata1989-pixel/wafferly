// lib/widgets/expense_entry/member/no_member_sheet.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../bottom_sheet/sheet_header.dart';
import '../../../features/members/screens/add_member_screen.dart';

class NoMemberSheet extends StatelessWidget {
  const NoMemberSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: 'Add Members',
          icon: Icons.people_outlined,
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Members help you track who made each transaction.',
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
              label: const Text('Add Member'),
              onPressed: () async {
                Navigator.of(context).pop();

                await Future.delayed(const Duration(milliseconds: 180));

                if (!context.mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMemberScreen()),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
