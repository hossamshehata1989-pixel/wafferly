// lib/widgets/expense_entry/member/member_picker_sheet.dart

import 'package:flutter/material.dart';
import '../../../features/members/models/member_model.dart';
import '../../../theme/app_colors.dart';
import '../../bottom_sheet/wafferly_bottom_sheet.dart';
import '../../bottom_sheet/sheet_header.dart';
import '../../bottom_sheet/sheet_footer.dart';
import 'member_card.dart';

Future<void> showMemberPickerSheet({
  required BuildContext context,
  required List<MemberModel> members,
  required String? selectedMemberId,
  required ValueChanged<String> onSelected,
}) async {
  await WafferlyBottomSheet.show(
    context: context,
    scrollable: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: 'Select Member',
          subtitle: 'Choose who made this transaction',
          icon: Icons.people_outlined,
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
          child: ListView(
            shrinkWrap: true,
            children: members.map((member) {
              final selected = member.id == selectedMemberId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MemberCard(
                  member: member,
                  selected: selected,
                  onTap: () {
                    onSelected(member.id);
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
              onPressed: () {
                Navigator.pop(context);
                // TODO: navigate to AddMemberScreen
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Member'),
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
