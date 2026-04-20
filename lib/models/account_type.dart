// lib/models/account_type.dart
enum AccountNature {
  asset,
  liability,
  investment,
  receivable,
}

enum AccountType {
  // Assets
  cash,
  bank,
  wallet,
  debitCard,
  
  // Liabilities
  creditCard,
  loan,
  
  // Investments
  gold,
  stocks,
  certificates,
  
  // Receivables
  moneyLent,
  rosca,
}

extension AccountTypeExtension on AccountType {
  String get string {
    switch (this) {
      case AccountType.cash: return 'cash';
      case AccountType.bank: return 'bank';
      case AccountType.wallet: return 'wallet';
      case AccountType.debitCard: return 'debitCard';
      case AccountType.creditCard: return 'creditCard';
      case AccountType.loan: return 'loan';
      case AccountType.gold: return 'gold';
      case AccountType.stocks: return 'stocks';
      case AccountType.certificates: return 'certificates';
      case AccountType.moneyLent: return 'moneyLent';
      case AccountType.rosca: return 'rosca';
    }
  }
  
  AccountNature get nature {
    switch (this) {
      case AccountType.cash:
      case AccountType.bank:
      case AccountType.wallet:
      case AccountType.debitCard:
        return AccountNature.asset;
        
      case AccountType.creditCard:
      case AccountType.loan:
        return AccountNature.liability;
        
      case AccountType.gold:
      case AccountType.stocks:
      case AccountType.certificates:
        return AccountNature.investment;
        
      case AccountType.moneyLent:
      case AccountType.rosca:
        return AccountNature.receivable;
    }
  }
  
  String get displayName {
    switch (this) {
      case AccountType.cash: return 'Cash';
      case AccountType.bank: return 'Bank';
      case AccountType.wallet: return 'Wallet';
      case AccountType.debitCard: return 'Debit Card';
      case AccountType.creditCard: return 'Credit Card';
      case AccountType.loan: return 'Loan';
      case AccountType.gold: return 'Gold';
      case AccountType.stocks: return 'Stocks';
      case AccountType.certificates: return 'Certificates';
      case AccountType.moneyLent: return 'Money Lent';
      case AccountType.rosca: return 'ROSCA';
    }
  }
  
  static AccountType fromString(String value) {
    switch (value) {
      case 'cash': return AccountType.cash;
      case 'bank': return AccountType.bank;
      case 'wallet': return AccountType.wallet;
      case 'debitCard': return AccountType.debitCard;
      case 'creditCard': return AccountType.creditCard;
      case 'loan': return AccountType.loan;
      case 'gold': return AccountType.gold;
      case 'stocks': return AccountType.stocks;
      case 'certificates': return AccountType.certificates;
      case 'moneyLent': return AccountType.moneyLent;
      case 'rosca': return AccountType.rosca;
      default: return AccountType.cash;
    }
  }
}