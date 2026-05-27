// lib/features/members/services/owner_member_service.dart

import 'package:uuid/uuid.dart';
import '../models/member_model.dart';

class OwnerMemberService {
  final _uuid = const Uuid();

  /// Create owner member automatically when first Book/Wallet is created
  MemberModel createOwnerMember({
    required String name,
    String? photoUrl,
    DateTime? birthday,
  }) {
    return MemberModel(
      id: _uuid.v4(),
      name: name,
      relationshipId: "me",
      photoUrl: photoUrl,
      birthday: birthday,
      isOwner: true,
      isLinked: true,
    );
  }
}
