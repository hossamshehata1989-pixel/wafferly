import 'package:flutter/material.dart';

enum AccountTypeOption {
  cash('cash', 'Cash', Icons.attach_money, Colors.green),
  bank('bank', 'Bank', Icons.account_balance, Colors.blue),
  wallet('wallet', 'Wallet', Icons.account_balance_wallet, Colors.orange),
  debitCard('debitCard', 'Debit Card', Icons.credit_card, Colors.teal),

  debt('debt', 'Debt', Icons.money_off, Colors.red),
  loan('loan', 'Loan', Icons.request_page, Colors.deepOrange),
  creditCard('creditCard', 'Credit Card Due', Icons.credit_card, Colors.pink),
  installment(
    'installment',
    'Installments',
    Icons.calendar_month,
    Colors.purple,
  ),

  investment('investment', 'Investment', Icons.trending_up, Colors.teal),
  gold('gold', 'Gold', Icons.workspace_premium, Colors.amber),
  stocks('stocks', 'Stocks', Icons.show_chart, Colors.green),
  certificates('certificates', 'Certificates', Icons.description, Colors.blue),

  lent('lent', 'Money Lent', Icons.handshake, Colors.cyan),
  rosca('rosca', 'ROSCA', Icons.group, Colors.indigo),

  realSaving('realSaving', 'Real Saving', Icons.savings, Colors.teal),
  savingCircle('savingCircle', 'Saving Circle', Icons.group, Colors.indigo);

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const AccountTypeOption(this.id, this.name, this.icon, this.color);
}
