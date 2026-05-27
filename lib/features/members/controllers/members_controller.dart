// lib/features/members/controllers/members_controller.dart

import 'package:flutter/material.dart';
import '../models/member_model.dart';

class MembersController extends ChangeNotifier {
  final List<MemberModel> _members = [];

  // عرض الأعضاء غير المؤرشفين فقط
  List<MemberModel> get members =>
      List.unmodifiable(_members.where((m) => !m.isArchived));

  MemberModel? get owner {
    try {
      return _members.firstWhere((m) => m.isOwner);
    } catch (_) {
      return null;
    }
  }

  void addMember(MemberModel member) {
    final exists = _members.any((m) => m.id == member.id);
    if (exists) return;

    if (member.isOwner && _members.any((m) => m.isOwner && m.id != member.id)) {
      return;
    }

    _members.add(member);
    notifyListeners();
  }

  // أرشفة العضو بدلاً من الحذف

  void archiveMember(String id) {
    final index = _members.indexWhere((e) => e.id == id);

    if (index == -1) return;

    final member = _members[index];

    if (member.isOwner) return;

    _members[index] = member.copyWith(
      isArchived: true,

      archivedAt: DateTime.now(),
    );

    notifyListeners();
  }

  void updateMember(MemberModel member) {
    final index = _members.indexWhere((e) => e.id == member.id);
    if (index == -1) return;

    final existing = _members[index];

    // لا يمكن تغيير relationshipId للمالك
    if (existing.isOwner && member.relationshipId != existing.relationshipId) {
      return;
    }

    // ❌ لا يمكن تحويل Regular → Owner أو Owner → Regular
    if (member.isOwner != existing.isOwner) {
      return;
    }

    _members[index] = member;
    notifyListeners();
  }
}
