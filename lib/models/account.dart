// lib/models/account.dart
import 'package:hive/hive.dart';
import 'package:wafferly/models/enums/account_enums.dart';
part 'account.g.dart';

@HiveType(typeId: 1)
class Account {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bookId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String type;          // يبقى String حالياً

  @HiveField(5)
  String currency;

  @HiveField(6)
  String? provider;

  @HiveField(7)
  String? accountNumber;

  @HiveField(8)
  String? color;

  @HiveField(9)
  String? icon;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  String memberId;

  @HiveField(14)
  AccountGroup group;

  @HiveField(15)
  bool isArchived;

  // الحقل الجديد: نفس رقم 13 الذي كان لـ natureEnum سابقاً
  @HiveField(13)
  AccountNature nature;

  Account({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.name,
    required this.type,
    required this.currency,
    required this.createdAt,
    required this.group,
    required this.nature,
    this.isArchived = false,
    this.provider,
    this.accountNumber,
    this.color,
    this.icon,
    this.notes,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    AccountNature resolvedNature;
    if (json['nature'] is String) {
      resolvedNature = AccountNatureExtension.fromString(json['nature']);
    } else if (json['natureEnum'] != null) {
      resolvedNature = AccountNature.values.firstWhere(
        (e) => e.toString() == json['natureEnum'],
        orElse: () => AccountNature.asset,
      );
    } else {
      resolvedNature = AccountNature.asset;
    }

    return Account(
      id: json['id'],
      bookId: json['bookId'],
      memberId: json['memberId'],
      name: json['name'],
      type: json['type'],
      currency: json['currency'],
      createdAt: DateTime.parse(json['createdAt']),
      group: AccountGroupExtension.fromString(json['group'] ?? 'moneyYouHave'),
      nature: resolvedNature,
      isArchived: json['isArchived'] ?? false,
      provider: json['provider'],
      accountNumber: json['accountNumber'],
      color: json['color'],
      icon: json['icon'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'memberId': memberId,
      'name': name,
      'type': type,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'group': group.string,
      'nature': nature.string,
      'isArchived': isArchived,
      'provider': provider,
      'accountNumber': accountNumber,
      'color': color,
      'icon': icon,
      'notes': notes,
    };
  }

  Account copyWith({
    String? id,
    String? bookId,
    String? memberId,
    String? name,
    String? type,
    String? currency,
    DateTime? createdAt,
    AccountGroup? group,
    bool? isArchived,
    AccountNature? nature,
    String? provider,
    String? accountNumber,
    String? color,
    String? icon,
    String? notes,
  }) {
    return Account(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      group: group ?? this.group,
      nature: nature ?? this.nature,
      isArchived: isArchived ?? this.isArchived,
      provider: provider ?? this.provider,
      accountNumber: accountNumber ?? this.accountNumber,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
    );
  }
}