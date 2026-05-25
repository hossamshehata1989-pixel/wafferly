// lib/features/members/models/member_model.dart

import 'package:flutter/material.dart';

class MemberModel {
  final String id;

  // Basic
  final String name;
  final String relationship;
  final String? photoUrl;

  // Personal
  final DateTime? birthday;
  final String? gender;

  // Contact (Future Share / Sync)
  final String? phone;
  final String? email;

  // Identity (Future)
  final String? accountId;
  final bool isLinked;

  // Notes
  final String? notes;

  // Stats (calculated later)
  final int transactionsCount;
  final double monthlySpent;
  final int goalsCount;

  const MemberModel({
    required this.id,
    required this.name,
    required this.relationship,

    this.photoUrl,

    this.birthday,
    this.gender,

    this.phone,
    this.email,

    this.accountId,
    this.isLinked = false,

    this.notes,

    this.transactionsCount = 0,
    this.monthlySpent = 0,
    this.goalsCount = 0,
  });

  MemberModel copyWith({
    String? id,
    String? name,
    String? relationship,
    String? photoUrl,
    DateTime? birthday,
    String? gender,
    String? phone,
    String? email,
    String? accountId,
    bool? isLinked,
    String? notes,
    int? transactionsCount,
    double? monthlySpent,
    int? goalsCount,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      photoUrl: photoUrl ?? this.photoUrl,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      accountId: accountId ?? this.accountId,
      isLinked: isLinked ?? this.isLinked,
      notes: notes ?? this.notes,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      monthlySpent: monthlySpent ?? this.monthlySpent,
      goalsCount: goalsCount ?? this.goalsCount,
    );
  }
}
