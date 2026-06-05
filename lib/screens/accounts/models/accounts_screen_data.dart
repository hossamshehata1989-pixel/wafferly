import '../../../models/account.dart';

class AccountsScreenData {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;

  final List<Account> moneyHave;
  final List<Account> savings;
  final List<Account> investments;
  final List<Account> liabilities;
  final List<Account> receivables;

  const AccountsScreenData({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.moneyHave,
    required this.savings,
    required this.investments,
    required this.liabilities,
    required this.receivables,
  });
}
