// lib/features/members/widgets/member_avatar.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../features/members/models/member_model.dart';
import '../../../theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  final MemberModel member;
  final double radius;

  const MemberAvatar({super.key, required this.member, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (member.photoUrl != null && File(member.photoUrl!).existsSync()) {
      child = Image.file(File(member.photoUrl!), fit: BoxFit.cover);
    } else if (member.avatarAsset != null) {
      child = SvgPicture.asset(member.avatarAsset!, fit: BoxFit.cover);
    } else {
      child = Center(
        child: Text(
          member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cardSecondary,
      child: ClipOval(
        child: SizedBox(width: radius * 2, height: radius * 2, child: child),
      ),
    );
  }
}
