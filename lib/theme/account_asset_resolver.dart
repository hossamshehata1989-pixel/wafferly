import '../models/enums/section_type.dart';
import 'account_assets.dart';

class AccountAssetResolver {
  const AccountAssetResolver._();

  static String defaultIcon(SectionType section) {
    switch (section) {
      case SectionType.liquidity:
        return AccountAssets.defaultLiquidity;

      case SectionType.savings:
        return AccountAssets.defaultSavings;

      case SectionType.investments:
        return AccountAssets.defaultInvestment;

      case SectionType.liabilities:
        return AccountAssets.defaultLiability;

      case SectionType.receivable:
        return AccountAssets.defaultReceivable;
    }
  }

  static String _folder(SectionType section) {
    switch (section) {
      case SectionType.liquidity:
        return 'liquidity';

      case SectionType.savings:
        return 'savings';

      case SectionType.investments:
        return 'investments';

      case SectionType.liabilities:
        return 'liabilities';

      case SectionType.receivable:
        return 'receivable';
    }
  }

  static List<String> iconsForType(SectionType section, String accountType) {
    const base = 'assets/icons/financial/accounts';
    final folder = _folder(section);

    switch (accountType) {
      case 'cash':
        return List.generate(4, (i) => '$base/$folder/cash${i + 1}.svg');

      case 'bank':
        return List.generate(2, (i) => '$base/$folder/bank${i + 1}.svg');

      case 'wallet':
        return List.generate(4, (i) => '$base/$folder/wallet${i + 1}.svg');

      case 'investment':
        return List.generate(5, (i) => '$base/$folder/investment${i + 1}.svg');

      default:
        return [];
    }
  }
}
