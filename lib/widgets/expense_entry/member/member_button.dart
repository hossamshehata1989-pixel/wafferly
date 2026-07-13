// lib/widgets/expense_entry/member/member_button.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../models/member.dart';
import '../entry_context_chip.dart'; // تم تعديل المسار
import 'member_selector.dart';
import 'no_member_sheet.dart';
import '../../bottom_sheet/wafferly_bottom_sheet.dart';

class MemberButton extends StatefulWidget {
  final List<Member> members;
  final String? selectedMemberId;
  final ValueChanged<String> onSelected;
  final ResponsiveMetrics metrics;

  const MemberButton({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
    required this.metrics,
  });

  @override
  State<MemberButton> createState() => _MemberButtonState();
}

class _MemberButtonState extends State<MemberButton> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _pressed = false;

  Member? get selectedMember =>
      widget.members.firstWhereOrNull((m) => m.id == widget.selectedMemberId);

  @override
  Widget build(BuildContext context) {
    final member = selectedMember;

    if (member == null) {
      return EntryContextChip(
        key: _anchorKey,
        metrics: widget.metrics,
        label: 'Add Member',
        onTap: _showNoMemberSheet,
      );
    }

    final count = widget.members.length;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: EntryContextChip(
        key: _anchorKey,
        metrics: widget.metrics,
        icon: Icons.person,
        iconColor: AppColors.primary,
        label: member.name,
        trailing: count > 1
            ? Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.primary,
              )
            : null,
        borderColor: AppColors.primary.withValues(alpha: 0.20),
        onTap: _handleTap,
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() => _pressed = true);

    await Future.delayed(const Duration(milliseconds: 80));

    if (mounted) {
      setState(() => _pressed = false);
    }

    if (!mounted) return;

    await MemberSelector.show(
      context: context,
      members: widget.members,
      selectedMemberId: widget.selectedMemberId,
      onSelected: widget.onSelected,
      anchorKey: _anchorKey,
    );
  }

  Future<void> _showNoMemberSheet() async {
    await WafferlyBottomSheet.show(
      context: context,
      child: const NoMemberSheet(),
    );
  }
}
