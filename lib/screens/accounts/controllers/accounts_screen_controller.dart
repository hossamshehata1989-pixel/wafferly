import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../models/enums/section_type.dart';
import '../../../services/balance_service.dart';
import '../models/accounts_screen_data.dart';

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

  List<Account> getLiquidityAccounts(List<Account> accounts) {
    return accounts.where((a) => a.group == AccountGroup.liquidity).toList();
  }

  List<Account> getSavingsAccounts(List<Account> accounts) {
    return accounts.where((a) => a.group == AccountGroup.savings).toList();
  }

  List<Account> getInvestmentAccounts(List<Account> accounts) {
    return accounts.where((a) => a.group == AccountGroup.investments).toList();
  }

  List<Account> getLiabilityAccounts(List<Account> accounts) {
    return accounts.where((a) => a.group == AccountGroup.liabilities).toList();
  }

  List<Account> getReceivableAccounts(List<Account> accounts) {
    return accounts.where((a) => a.group == AccountGroup.receivable).toList();
  }

  SectionType getSectionType(String title) {
    switch (title) {
      case 'Savings':
        return SectionType.savings;

      case 'Investments':
        return SectionType.investments;

      case 'liabilities':
        return SectionType.liabilities;

      case 'Receivable':
        return SectionType.receivable;

      default:
        return SectionType.liquidity;
    }
  }

  bool isSavingsSection(String title) {
    return title == 'Savings';
  }

  AccountsScreenData buildScreenData(
    List<Account> accounts,
    BalanceService balanceService,
  ) {
    return AccountsScreenData(
      netWorth: calculateNetWorth(accounts, balanceService),

      totalAssets: calculateTotalByNature(
        accounts,
        balanceService,
        AccountNature.asset,
      ),

      totalLiabilities: calculateTotalByNature(
        accounts,
        balanceService,
        AccountNature.liability,
      ),

      liquidity: getLiquidityAccounts(accounts),

      savings: getSavingsAccounts(accounts),

      investments: getInvestmentAccounts(accounts),

      liabilities: getLiabilityAccounts(accounts),
      receivable: getReceivableAccounts(accounts),
    );
  }
}
