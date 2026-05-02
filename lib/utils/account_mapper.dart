import '../models/account_enums.dart';

AccountNature resolveNature(String type) {
  switch (type) {
    case 'cash':
    case 'bank':
    case 'wallet':
    case 'debitCard':
    case 'investment':
    case 'gold':
    case 'stocks':
    case 'certificates':
    case 'lent':
    case 'rosca':
      return AccountNature.asset;
    case 'credit':
    case 'debt':
    case 'loan':
    case 'creditCard':
    case 'installment':
      return AccountNature.liability;
    default:
      return AccountNature.asset;
  }
}

AccountGroup resolveGroup(String type) {
  switch (type) {
    case 'cash':
    case 'bank':
    case 'wallet':
    case 'debitCard':
      return AccountGroup.moneyYouHave;
    case 'investment':
    case 'gold':
    case 'stocks':
    case 'certificates':
      return AccountGroup.investments;
    case 'credit':
    case 'debt':
    case 'loan':
    case 'creditCard':
    case 'installment':
      return AccountGroup.moneyYouOwe;
    case 'lent':
    case 'rosca':
      return AccountGroup.moneyYouWillGet;
    default:
      return resolveNature(type) == AccountNature.asset
          ? AccountGroup.moneyYouHave
          : AccountGroup.moneyYouOwe;
  }
}