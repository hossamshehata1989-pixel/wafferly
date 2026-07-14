// lib/widgets/expense_entry/member/member_button.dart

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../controllers/transaction_entry_controller.dart';
import '../../../features/members/models/member_model.dart';
import '../entry_context_chip.dart';
import 'member_selector.dart';
import 'no_member_sheet.dart';
import '../../bottom_sheet/wafferly_bottom_sheet.dart';

class MemberButton extends StatefulWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;

  const MemberButton({
    super.key,
    required this.controller,
    required this.metrics,
  });

  @override
  State<MemberButton> createState() => _MemberButtonState();
}

class _MemberButtonState extends State<MemberButton> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _pressed = false;

  MemberModel? get selectedMember {
    final members = widget.controller.availableMembers;
    return members.cast<MemberModel?>().firstWhere(
      (m) => m?.id == widget.controller.selectedMemberId,
      orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final member = selectedMember;
        final members = widget.controller.availableMembers;
        final count = members.length;

        if (member == null) {
          return EntryContextChip(
            key: _anchorKey,
            metrics: widget.metrics,
            label: 'No Member',
            onTap: _showNoMemberSheet,
          );
        }

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
      },
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
      members: widget.controller.availableMembers,
      selectedMemberId: widget.controller.selectedMemberId,
      onSelected: widget.controller.selectMember,
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
