// lib/features/members/services/owner_member_service.dart

import 'package:uuid/uuid.dart';
import '../models/member_model.dart';

class OwnerMemberService {
  final _uuid = const Uuid();

  MemberModel createOwnerMember({
    required String name,
    String? photoUrl,
    DateTime? birthday,
  }) {
    return MemberModel(
      id: _uuid.v4(),
      name: name,
      relationshipId: "me",

      // ✅ local uploaded image if exists
      photoUrl: photoUrl,

      // ✅ default avatar for owner
      avatarAsset: 'assets/avatars/other1.svg',

      birthday: birthday,

      isOwner: true,
      isLinked: true,
    );
  }
}
