import 'package:flutter/material.dart';
import '../models/member_model.dart';

class MembersController extends ChangeNotifier {
  final List<MemberModel> _members = [];

  List<MemberModel> get members => _members;

  void addMember(MemberModel member) {
    _members.add(member);

    notifyListeners();
  }

  void removeMember(String id) {
    _members.removeWhere((e) => e.id == id);

    notifyListeners();
  }

  void updateMember(MemberModel member) {
    final index = _members.indexWhere((e) => e.id == member.id);

    if (index == -1) return;

    _members[index] = member;

    notifyListeners();
  }
}
