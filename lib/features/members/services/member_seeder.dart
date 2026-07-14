import 'package:hive_flutter/hive_flutter.dart';

import '../models/member_model.dart';
import 'owner_member_service.dart';

class MemberSeeder {
  static Future<void> ensureOwnerExists() async {
    final box = Hive.box<MemberModel>('members');

    if (box.isNotEmpty) return;

    final owner = OwnerMemberService().createOwnerMember(name: 'Me');

    await box.put(owner.id, owner);
  }
}
