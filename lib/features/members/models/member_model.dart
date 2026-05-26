// lib/features/members/models/member_model.dart

class MemberModel {
  final String id;

  // Basic
  final String name;
  final String relationshipId;
  final String? photoUrl;

  // Personal
  final DateTime? birthday;
  final String? gender;

  // Contact
  final String? phone;
  final String? email;

  // Identity
  final String? accountId;
  final bool isLinked;
  final bool isOwner;

  // Notes
  final String? notes;

  // Stats
  final int transactionsCount;
  final double monthlySpent;
  final int goalsCount;

  const MemberModel({
    required this.id,
    required this.name,
    required this.relationshipId,

    this.photoUrl,

    this.birthday,
    this.gender,

    this.phone,
    this.email,

    this.accountId,
    this.isLinked = false,
    this.isOwner = false,

    this.notes,

    this.transactionsCount = 0,
    this.monthlySpent = 0,
    this.goalsCount = 0,
  });

  MemberModel copyWith({
    String? id,
    String? name,
    String? relationshipId,
    String? photoUrl,
    DateTime? birthday,
    String? gender,
    String? phone,
    String? email,
    String? accountId,
    bool? isLinked,
    bool? isOwner,
    String? notes,
    int? transactionsCount,
    double? monthlySpent,
    int? goalsCount,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationshipId: relationshipId ?? this.relationshipId,

      photoUrl: photoUrl ?? this.photoUrl,

      birthday: birthday ?? this.birthday,

      gender: gender ?? this.gender,

      phone: phone ?? this.phone,

      email: email ?? this.email,

      accountId: accountId ?? this.accountId,

      isLinked: isLinked ?? this.isLinked,

      isOwner: isOwner ?? this.isOwner,

      notes: notes ?? this.notes,

      transactionsCount: transactionsCount ?? this.transactionsCount,

      monthlySpent: monthlySpent ?? this.monthlySpent,

      goalsCount: goalsCount ?? this.goalsCount,
    );
  }
}
