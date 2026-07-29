import '../../../models/account.dart';

class AccountsScreenData {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;

  final List<Account> liquidity;
  final List<Account> savings;
  final List<Account> investments;
  final List<Account> liabilities;
  final List<Account> receivable;

  const AccountsScreenData({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.liquidity,
    required this.savings,
    required this.investments,
    required this.liabilities,
    required this.receivable,
  });
}
