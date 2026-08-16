
import '../../../models/account.dart';

class AccountDetailsData {
  const AccountDetailsData({
    required this.account,
    required this.balance,
    required this.available,
    required this.reserved,
    required this.monthIn,
    required this.monthOut,
    required this.chart,
    required this.activity,
    required this.recurring,
    required this.health,
  });

  final Account account;
  final double balance;
  final double available;
  final double reserved;
  final double monthIn;
  final double monthOut;
  final List<BalancePoint> chart;
  final List<AccountActivityItem> activity;
  final List<RecurringAccountItem> recurring;
  final AccountHealthData health;
}

class BalancePoint {
  const BalancePoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class AccountActivityItem {
  const AccountActivityItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isIncome;
}

class RecurringAccountItem {
  const RecurringAccountItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.nextOccurrence,
    required this.isIncome,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final DateTime? nextOccurrence;
  final bool isIncome;
}

class AccountHealthData {
  const AccountHealthData({
    required this.score,
    required this.label,
    required this.points,
  });

  final int score;
  final String label;
  final List<String> points;
}
