import 'package:hive/hive.dart';
import 'enums/entry_type.dart';
import 'enums/ledger_purpose.dart';

part 'ledger_entry.g.dart';

@HiveType(typeId: 22) // ID جديد غير مستخدم
class LedgerEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String transactionId; // معرف المعاملة الأصلية

  @HiveField(2)
  final String accountId;

  @HiveField(3)
  final EntryType entryType;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final LedgerPurpose purpose;

  LedgerEntry({
    required this.id,
    required this.transactionId,
    required this.accountId,
    required this.entryType,
    required this.amount,
    required this.date,
    required this.purpose,
  });

  // JSON serialization (للاستيراد/التصدير المستقبلي)
  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'],
      transactionId: json['transactionId'],
      accountId: json['accountId'],
      entryType: EntryTypeExtension.fromString(json['entryType']),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      purpose: LedgerPurposeExtension.fromString(json['purpose']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'accountId': accountId,
      'entryType': entryType.string,
      'amount': amount,
      'date': date.toIso8601String(),
      'purpose': purpose.string,
    };
  }

  LedgerEntry copyWith({
    String? id,
    String? transactionId,
    String? accountId,
    EntryType? entryType,
    double? amount,
    DateTime? date,
    LedgerPurpose? purpose,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      purpose: purpose ?? this.purpose,
    );
  }

  @override
  String toString() {
    return 'LedgerEntry(id: $id, transactionId: $transactionId, accountId: $accountId, entryType: ${entryType.string}, amount: $amount, date: $date, purpose: ${purpose.string})';
  }
}