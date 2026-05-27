// lib/features/members/screens/members_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../controllers/members_controller.dart';
import '../models/member_model.dart';
import '../utils/relationship_mapper.dart';
import 'add_member_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/constants/app_spacing.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Members"),
      ),
      body: Consumer<MembersController>(
        builder: (_, controller, __) {
          final members = controller.members;

          if (members.isEmpty) {
            return const Center(
              child: Text(
                "No members yet",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final sortedMembers = members.toList()
            ..sort((a, b) {
              if (a.isOwner) return -1;
              if (b.isOwner) return 1;
              return a.name.compareTo(b.name);
            });

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _summaryCard(members.length),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                "All Members",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...sortedMembers.map((member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _memberCard(context, member, controller),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "membersFab",
        child: const Icon(Icons.add),
        onPressed: () async {
          final member = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMemberScreen()),
          );
          if (member != null) {
            context.read<MembersController>().addMember(member);
          }
        },
      ),
    );
  }

  Widget _summaryCard(int totalMembers) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.cardSecondary,
            child: const Icon(Icons.people, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Members Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$totalMembers members",
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(
    BuildContext context,
    MemberModel member,
    MembersController controller,
  ) {
    final isOwner = member.isOwner;

    // Avatar widget
    final avatar = CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.cardSecondary,
      child: ClipOval(
        child: SizedBox(
          width: 60,
          height: 60,
          child: member.photoUrl != null
              ? Image.file(File(member.photoUrl!), fit: BoxFit.cover)
              : member.avatarAsset != null
              ? SvgPicture.asset(member.avatarAsset!, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    (member.name.isNotEmpty ? member.name[0] : "?")
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "You",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RelationshipMapper.getDisplayName(member.relationshipId),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              // Action buttons: Edit and Archive (only for non-owner)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                    tooltip: "Edit",
                    onPressed: () async {
                      final updatedMember = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMemberScreen(member: member),
                        ),
                      );
                      if (updatedMember != null) {
                        controller.updateMember(updatedMember);
                      }
                    },
                  ),
                  if (!isOwner)
                    IconButton(
                      icon: const Icon(
                        Icons.archive_outlined,
                        color: Colors.orange,
                      ),
                      tooltip: "Archive",
                      onPressed: () async {
                        // ✅ Confirmation dialog before archiving
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.card,
                            title: const Text(
                              "Archive Member",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              "Archive ${member.name}?",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Archive",
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          controller.archiveMember(member.id);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${member.name} archived"),
                              action: SnackBarAction(
                                label: "Undo",
                                onPressed: () {
                                  controller.updateMember(
                                    member.copyWith(
                                      isArchived: false,
                                      archivedAt: null,
                                    ),
                                  );
                                },
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(
                "Transactions",
                member.transactionsCount.toString(),
                AppColors.primary,
              ),
              _stat("Spent", "${member.monthlySpent} EGP", AppColors.income),
              _stat("Goals", member.goalsCount.toString(), AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
