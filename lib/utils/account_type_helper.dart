// lib/utils/account_type_helper.dart

import '../l10n/app_localizations.dart';

/// Get display name for account type (UI only)
/// لا يؤثر على Runtime classification أو Hive storage
String getAccountTypeDisplayName(String type, AppLocalizations t) {
  switch (type) {
    case 'cash':
      return t.cash;
    case 'bank':
      return t.bank;
    case 'wallet':
      return t.wallet;
    case 'debitCard':
      return t.debitCard;
    case 'debt':
      return t.moneyBorrowed;
    case 'loan':
      return t.loan;
    case 'creditCard':
      return t.creditCard;
    case 'installment':
      return t.installment;
    case 'investment':
      return t.investment;
    case 'gold':
      return t.gold;
    case 'stocks':
      return t.stocks;
    case 'certificates':
      return t.certificates;
    case 'lent':
      return t.lent;
    case 'savingCircle':
      return t.savingCircle;
    default:
      return type
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
          .trim()
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : word,
          )
          .join(' ');
  }
}
