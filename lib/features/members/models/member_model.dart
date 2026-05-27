// lib/features/members/models/member_model.dart

import 'package:hive/hive.dart';

part 'member_model.g.dart';

@HiveType(typeId: 70)
class MemberModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String relationshipId;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final String? avatarAsset;

  @HiveField(5)
  final DateTime? birthday;

  @HiveField(6)
  final String? gender;

  @HiveField(7)
  final String? phone;

  @HiveField(8)
  final String? email;

  @HiveField(9)
  final String? accountId;

  @HiveField(10)
  final bool isLinked;

  @HiveField(11)
  final bool isOwner;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final bool isArchived;

  @HiveField(14)
  final DateTime? archivedAt;

  @HiveField(15)
  final int transactionsCount;

  @HiveField(16)
  final double monthlySpent;

  @HiveField(17)
  final int goalsCount;

  const MemberModel({
    required this.id,
    required this.name,
    required this.relationshipId,
    this.photoUrl,
    this.avatarAsset,
    this.birthday,
    this.gender,
    this.phone,
    this.email,
    this.accountId,
    this.isLinked = false,
    this.isOwner = false,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
    this.transactionsCount = 0,
    this.monthlySpent = 0,
    this.goalsCount = 0,
  });

  // Temporary budget UI helpers (no Hive persistence)
  bool get isOverBudget => monthlySpent > 5000;

  double get budgetUsagePercent {
    const limit = 5000.0;

    if (limit <= 0) return 0;

    final percent = (monthlySpent / limit) * 100;

    return percent;
  }

  MemberModel copyWith({
    String? id,
    String? name,
    String? relationshipId,
    String? photoUrl,
    String? avatarAsset,
    DateTime? birthday,
    String? gender,
    String? phone,
    String? email,
    String? accountId,
    bool? isLinked,
    bool? isOwner,
    String? notes,
    bool? isArchived,
    DateTime? archivedAt,
    int? transactionsCount,
    double? monthlySpent,
    int? goalsCount,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationshipId: relationshipId ?? this.relationshipId,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      accountId: accountId ?? this.accountId,
      isLinked: isLinked ?? this.isLinked,
      isOwner: isOwner ?? this.isOwner,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      monthlySpent: monthlySpent ?? this.monthlySpent,
      goalsCount: goalsCount ?? this.goalsCount,
    );
  }
}
