import 'package:flutter/foundation.dart';

/// A read-only row used by the Reserved Money management screen.
///
/// This is a projection of active Planning allocations; it is not a
/// financial ledger/event record.
@immutable
class ReservedMoneyItem {
  const ReservedMoneyItem({
    required this.allocationId,
    required this.sourceId,
    required this.sourceType,
    required this.sourceName,
    required this.accountId,
    required this.accountName,
    required this.amount,
    required this.createdAt,
  });

  final String allocationId;
  final String sourceId;
  final String sourceType;
  final String sourceName;
  final String accountId;
  final String accountName;
  final double amount;
  final DateTime createdAt;
}

@immutable
class ReservedMoneyCategory {
  const ReservedMoneyCategory({
    required this.key,
    required this.title,
    required this.items,
    required this.total,
  });

  final String key;
  final String title;
  final List<ReservedMoneyItem> items;
  final double total;
}

@immutable
class ReservedMoneyAccountSummary {
  const ReservedMoneyAccountSummary({
    required this.accountId,
    required this.accountName,
    required this.reserved,
  });

  final String accountId;
  final String accountName;
  final double reserved;
}

@immutable
class ReservedMoneyProjection {
  const ReservedMoneyProjection({
    required this.totalReserved,
    required this.items,
    required this.categories,
    required this.accounts,
  });

  final double totalReserved;
  final List<ReservedMoneyItem> items;
  final List<ReservedMoneyCategory> categories;
  final List<ReservedMoneyAccountSummary> accounts;
}
