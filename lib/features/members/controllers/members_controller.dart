// lib/features/members/controllers/members_controller.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/member_model.dart';
import '../services/owner_member_service.dart';

class MembersController extends ChangeNotifier {
  final Box<MemberModel> _box = Hive.box<MemberModel>('members');
  List<MemberModel> _members = [];

  MembersController() {
    _loadMembers();
    _ensureOwnerExists();
  }

  void _loadMembers() {
    _members = _box.values.toList();
    notifyListeners();
  }

  List<MemberModel> get members =>
      _members.where((m) => !m.isArchived).toList();

  MemberModel? get owner {
    try {
      return _members.firstWhere((m) => m.isOwner);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMember(MemberModel member) async {
    final exists = _members.any((m) => m.id == member.id);
    if (exists) return;

    if (member.isOwner && _members.any((m) => m.isOwner && m.id != member.id)) {
      return;
    }

    await _box.put(member.id, member);
    _members.add(member);
    notifyListeners();
  }

  Future<void> archiveMember(String id) async {
    final index = _members.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final member = _members[index];
    if (member.isOwner) return;

    final updated = member.copyWith(
      isArchived: true,
      archivedAt: DateTime.now(),
    );
    await _box.put(id, updated);
    _members[index] = updated;
    notifyListeners();
  }

  Future<void> updateMember(MemberModel member) async {
    final index = _members.indexWhere((e) => e.id == member.id);
    if (index == -1) return;

    final existing = _members[index];

    // لا يمكن تغيير relationshipId للمالك
    if (existing.isOwner && member.relationshipId != existing.relationshipId) {
      return;
    }

    // لا يمكن تحويل Regular → Owner أو Owner → Regular
    if (member.isOwner != existing.isOwner) {
      return;
    }

    await _box.put(member.id, member);
    _members[index] = member;
    notifyListeners();
  }

  Future<void> _ensureOwnerExists() async {
    final hasOwner = _members.any((m) => m.isOwner);

    if (!hasOwner) {
      final owner = OwnerMemberService().createOwnerMember(name: "Me");
      await addMember(owner);
    }
  }
}
