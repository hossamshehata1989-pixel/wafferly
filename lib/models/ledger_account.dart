import 'package:hive/hive.dart';
import 'enums/ledger_account_type.dart';

part 'ledger_account.g.dart';

@HiveType(typeId: 31)
class LedgerAccount {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final LedgerAccountType type;

  @HiveField(3)
  final String? categoryId; // Temporary link to UI category (Sprint 3C)

  @HiveField(4)
  final bool isSystem;

  @HiveField(5)
  final String? parentId; // For future hierarchy (Chart of Accounts)

  LedgerAccount({
    required this.id,
    required this.name,
    required this.type,
    this.categoryId,
    this.isSystem = false,
    this.parentId,
  });

  factory LedgerAccount.fromJson(Map<String, dynamic> json) {
    return LedgerAccount(
      id: json['id'],
      name: json['name'],
      type: LedgerAccountTypeExtension.fromString(json['type']),
      categoryId: json['categoryId'],
      isSystem: json['isSystem'] ?? false,
      parentId: json['parentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.string,
      'categoryId': categoryId,
      'isSystem': isSystem,
      'parentId': parentId,
    };
  }

  LedgerAccount copyWith({
    String? id,
    String? name,
    LedgerAccountType? type,
    String? categoryId,
    bool? isSystem,
    String? parentId,
  }) {
    return LedgerAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      isSystem: isSystem ?? this.isSystem,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  String toString() {
    return 'LedgerAccount(id: $id, name: $name, type: ${type.string}, isSystem: $isSystem)';
  }
}
