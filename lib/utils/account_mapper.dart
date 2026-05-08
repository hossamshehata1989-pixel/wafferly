import '../models/account_enums.dart';

/// ==============================
/// 🧠 Resolve Account Nature
/// ==============================
AccountNature resolveNature(String type) {
  switch (type) {
    case 'liability':
      return AccountNature.liability;

    default:
      return AccountNature.asset;
  }
}

/// ==============================
/// 🧠 Resolve Account Group
/// ==============================
AccountGroup resolveGroup(String type) {
  switch (type) {
    // 💰 فلوس معاك
    case 'cash':
    case 'bank':
    case 'wallet':
      return AccountGroup.moneyYouHave;

    // 📈 استثمارات
    case 'investment':
      return AccountGroup.investments;

    // 💳 ديون عليك
    case 'liability':
    case 'debt':
      return AccountGroup.moneyYouOwe;

    // 🧾 فلوس ليك
    case 'receivable':
      return AccountGroup.moneyYouWillGet;

    // 🔒 fallback (احتياطي)
    default:
      return AccountGroup.moneyYouHave;
  }
}