import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../services/balance_service.dart';

class AccountsScreenController {
  double calculateNetWorth(
    List<Account> accounts,
    BalanceService balanceService,
  ) {
    double assets = 0;
    double liabilities = 0;

    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);

      if (acc.nature == AccountNature.asset) {
        assets += balance;
      } else if (acc.nature == AccountNature.liability) {
        liabilities += balance.abs();
      }
    }

    return assets - liabilities;
  }

  double calculateTotalByNature(
    List<Account> accounts,
    BalanceService balanceService,
    AccountNature nature,
  ) {
    double total = 0;

    for (final acc in accounts.where((a) => a.nature == nature)) {
      final balance = balanceService.getBalance(acc.id);

      if (nature == AccountNature.liability) {
        total += balance.abs();
      } else {
        total += balance;
      }
    }

    return total;
  }

  double calculateSectionTotal(
    List<Account> accounts,
    BalanceService balanceService,
  ) {
    double total = 0;

    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);

      if (acc.nature == AccountNature.liability) {
        total += balance.abs();
      } else {
        total += balance;
      }
    }

    return total;
  }
}
