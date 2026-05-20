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
    case 'wallet':
    case 'debitCard':
      return AccountGroup.moneyYouHave;

    // 📈 Investments
    case 'investment':
    case 'gold':
    case 'stock':
    case 'stocks':
    case 'certificate':
    case 'certificates':
    case 'rosca':
      return AccountGroup.investments;

    // 💳 Money You Owe
    case 'debt':
    case 'moneyBorrowed':
    case 'loan':
    case 'creditCard':
    case 'installment':
      return AccountGroup.moneyYouOwe;

    // 🧾 Money You Will Get
    case 'lent':
    case 'receivable':
    case 'moneyLent':
      return AccountGroup.moneyYouWillGet;

    default:
      return AccountGroup.moneyYouHave;
  }
}
