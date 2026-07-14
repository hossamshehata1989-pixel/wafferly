// lib/widgets/expense_entry/member/member_selector.dart

import 'package:flutter/material.dart';
import '../../../features/members/models/member_model.dart';
import 'member_picker_sheet.dart';

class MemberSelector {
  static Future<void> show({
    required BuildContext context,
    required List<MemberModel> members,
    required String? selectedMemberId,
    required Function(String) onSelected,
    required GlobalKey anchorKey,
  }) async {
    final count = members.length;

    // 1. عضو واحد → لا تفعل شيئًا
    if (count <= 1) {
      return;
    }

    // 2. عضوان → تبديل مباشر (مثل AccountSelector)
    if (count == 2) {
      final currentIndex = members.indexWhere((m) => m.id == selectedMemberId);
      final nextIndex = currentIndex == 0 ? 1 : 0;
      final nextMember = members[nextIndex];
      onSelected(nextMember.id);
      return;
    }

    // 3. ثلاثة أعضاء أو أكثر → BottomSheet
    await showMemberPickerSheet(
      context: context,
      members: members,
      selectedMemberId: selectedMemberId,
      onSelected: onSelected,
    );
  }
}
