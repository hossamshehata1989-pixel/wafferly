import '../models/enums/account_enums.dart';

/// ==============================
/// Resolve Account Nature
/// ==============================
AccountNature resolveNature(String type) {
  switch (type) {
    // Liabilities
    case 'debt':
    case 'moneyBorrowed':
    case 'loan':
    case 'creditCard':
    case 'installment':
      return AccountNature.liability;

    default:
      return AccountNature.asset;
  }
}

/// ==============================
/// Resolve Account Group
/// ==============================
AccountGroup resolveGroup(String type) {
  switch (type) {
    // 💰 Money You Have
    case 'cash':
    case 'bank':
    case 'debitCard':
    case 'wallet':
      return AccountGroup.liquidity;

    // 🏦 Savings
    case 'realSaving':
    case 'virtualSaving':
    case 'savingCircle':
      return AccountGroup.savings;

    // 📈 Investments
    case 'investment':
    case 'gold':
    case 'stocks':
    case 'certificates':
      return AccountGroup.investments;

    // 💳 Money You Owe
    case 'debt':
    case 'moneyBorrowed':
    case 'loan':
    case 'creditCard':
    case 'installment':
      return AccountGroup.liabilities;

    // 🧾 Money You Will Get
    case 'lent':
    case 'receivable':
    case 'moneyLent':
      return AccountGroup.receivable;

    default:
      return AccountGroup.moneyYouHave;
  }
}
