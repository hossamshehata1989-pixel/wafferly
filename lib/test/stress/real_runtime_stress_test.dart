// test/stress/real_runtime_stress_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/models/reserved_money.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/reserved_money_type.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/services/account_service.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/transaction_service.dart';
import 'package:wafferly/services/reserved_money_service.dart';

void main() async {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountNatureAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(ReservedMoneyAdapter());
    }
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(ReservedMoneyTypeAdapter());
    }
    
    await Hive.openBox<Account>('test_stress_accounts');
    await Hive.openBox<Transaction>('test_stress_transactions');
    await Hive.openBox<ReservedMoney>('test_stress_reserved');
  });
  
  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('test_stress_accounts');
    await Hive.deleteBoxFromDisk('test_stress_transactions');
    await Hive.deleteBoxFromDisk('test_stress_reserved');
  });
  
  tearDown(() async {
    await Hive.box<Account>('test_stress_accounts').clear();
    await Hive.box<Transaction>('test_stress_transactions').clear();
    await Hive.box<ReservedMoney>('test_stress_reserved').clear();
  });
  
  class StressTestAccountService extends AccountService {
    @override
    Box<Account> get box => Hive.box<Account>('test_stress_accounts');
  }
  
  class StressTestTransactionService {
    static const String _boxName = 'test_stress_transactions';
    Box<Transaction> get _box => Hive.box<Transaction>(_boxName);
    
    Future<void> addTransaction(Transaction transaction) async {
      await _box.put(transaction.id, transaction);
    }
    
    Future<void> updateTransaction(Transaction transaction) async {
      await _box.put(transaction.id, transaction);
    }
    
    Future<void> deleteTransaction(String id) async {
      await _box.delete(id);
    }
  }
  
  class StressTestReservedService extends ReservedMoneyService {
    @override
    Box<ReservedMoney> get _box => Hive.box<ReservedMoney>('test_stress_reserved');
  }
  
  class StressTestBalanceService extends BalanceService {
    final Box<Transaction> customTxBox;
    
    StressTestBalanceService(this.customTxBox);
    
    @override
    Box<Transaction> get txBox => customTxBox;
  }
  
  test('TEST 1: Create asset account with initial balance', () async {
    final accountService = StressTestAccountService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    const initialAmount = 10000.0;
    
    final account = await accountService.createAccount(
      name: 'Test Cash',
      type: 'cash',
      currency: 'EGP',
    );
    
    final initialTransaction = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: account.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await txBox.put(initialTransaction.id, initialTransaction);
    
    final balance = balanceService.getBalance(account.id);
    
    expect(balance, initialAmount);
  });
  
  test('TEST 2: Create liability account with initial balance - FIXED', () async {
    final accountService = StressTestAccountService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    const initialAmount = 50000.0;
    
    final account = await accountService.createAccount(
      name: 'Test Loan',
      type: 'loan',
      currency: 'EGP',
    );
    
    final initialTransaction = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: null,
      fromAccountId: account.id,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await txBox.put(initialTransaction.id, initialTransaction);
    
    final balance = balanceService.getBalance(account.id);
    
    expect(balance, -initialAmount);
  });
  
  test('TEST 3: Transfer between accounts', () async {
    final accountService = StressTestAccountService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    final sourceAccount = await accountService.createAccount(
      name: 'Source Account',
      type: 'cash',
      currency: 'EGP',
    );
    
    final destAccount = await accountService.createAccount(
      name: 'Destination Account',
      type: 'bank',
      currency: 'EGP',
    );
    
    const initialAmount = 10000.0;
    final initialTx = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: sourceAccount.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await txBox.put(initialTx.id, initialTx);
    
    const transferAmount = 3000.0;
    final transferTx = Transaction.create(
      amount: transferAmount,
      type: TransactionType.transfer,
      fromAccountId: sourceAccount.id,
      toAccountId: destAccount.id,
      categoryId: 'transfer',
      date: DateTime.now(),
      source: TransactionSource.manual,
    );
    await txBox.put(transferTx.id, transferTx);
    
    final sourceBalance = balanceService.getBalance(sourceAccount.id);
    final destBalance = balanceService.getBalance(destAccount.id);
    
    expect(sourceBalance, initialAmount - transferAmount);
    expect(destBalance, transferAmount);
  });
  
  test('TEST 4: Update transaction', () async {
    final accountService = StressTestAccountService();
    final transactionService = StressTestTransactionService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    final account = await accountService.createAccount(
      name: 'Test Account',
      type: 'cash',
      currency: 'EGP',
    );
    
    const initialAmount = 10000.0;
    final initialTx = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: account.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await transactionService.addTransaction(initialTx);
    
    const originalExpenseAmount = 1000.0;
    final expenseTx = Transaction.create(
      amount: originalExpenseAmount,
      type: TransactionType.expense,
      fromAccountId: account.id,
      toAccountId: null,
      categoryId: 'food',
      date: DateTime.now(),
      source: TransactionSource.manual,
    );
    await transactionService.addTransaction(expenseTx);
    
    const updatedExpenseAmount = 2000.0;
    final updatedExpenseTx = expenseTx.copyWith(amount: updatedExpenseAmount);
    await transactionService.updateTransaction(updatedExpenseTx);
    
    final finalBalance = balanceService.getBalance(account.id);
    
    expect(finalBalance, initialAmount - updatedExpenseAmount);
  });
  
  test('TEST 5: Delete transaction', () async {
    final accountService = StressTestAccountService();
    final transactionService = StressTestTransactionService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    final account = await accountService.createAccount(
      name: 'Test Account',
      type: 'cash',
      currency: 'EGP',
    );
    
    const initialAmount = 10000.0;
    final initialTx = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: account.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await transactionService.addTransaction(initialTx);
    
    const expenseAmount = 1000.0;
    final expenseTx = Transaction.create(
      amount: expenseAmount,
      type: TransactionType.expense,
      fromAccountId: account.id,
      toAccountId: null,
      categoryId: 'food',
      date: DateTime.now(),
      source: TransactionSource.manual,
    );
    await transactionService.addTransaction(expenseTx);
    
    await transactionService.deleteTransaction(expenseTx.id);
    
    final finalBalance = balanceService.getBalance(account.id);
    
    expect(finalBalance, initialAmount);
  });
  
  test('TEST 6: Archive account - UI vs Financial impact', () async {
    final accountService = StressTestAccountService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    final account = await accountService.createAccount(
      name: 'Account to Archive',
      type: 'cash',
      currency: 'EGP',
    );
    
    const initialAmount = 5000.0;
    final initialTx = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: account.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await txBox.put(initialTx.id, initialTx);
    
    final balanceBeforeArchive = balanceService.getBalance(account.id);
    
    await accountService.archiveAccount(account.id);
    
    final balanceAfterArchive = balanceService.getBalance(account.id);
    final activeAccounts = accountService.getAllActiveAccounts();
    final isAccountVisible = activeAccounts.any((a) => a.id == account.id);
    
    expect(isAccountVisible, false);
    expect(balanceAfterArchive, balanceBeforeArchive);
  });
  
  test('TEST 7: Reserved money affects available balance', () async {
    final accountService = StressTestAccountService();
    final reservedService = StressTestReservedService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    final account = await accountService.createAccount(
      name: 'Test Account',
      type: 'cash',
      currency: 'EGP',
    );
    
    const initialAmount = 10000.0;
    final initialTx = Transaction.create(
      amount: initialAmount,
      type: TransactionType.initialBalance,
      toAccountId: account.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await txBox.put(initialTx.id, initialTx);
    
    const reservedAmount = 2000.0;
    final reservedItem = ReservedMoney.create(
      accountId: account.id,
      title: 'Emergency Fund',
      amount: reservedAmount,
      type: ReservedMoneyType.fixed,
    );
    await reservedService.add(reservedItem);
    
    final realBalance = balanceService.getBalance(account.id);
    final reservedTotal = reservedService.getReservedAmount(account.id);
    final availableBalance = balanceService.getAvailableBalance(account.id);
    
    expect(realBalance, initialAmount);
    expect(reservedTotal, reservedAmount);
    expect(availableBalance, initialAmount - reservedAmount);
  });
  
  test('TEST 8: Full scenario - Money Conservation Law', () async {
    final accountService = StressTestAccountService();
    final reservedService = StressTestReservedService();
    final transactionService = StressTestTransactionService();
    final txBox = Hive.box<Transaction>('test_stress_transactions');
    final balanceService = StressTestBalanceService(txBox);
    
    double initialTotalMoney = 0;
    
    final cashAccount = await accountService.createAccount(
      name: 'Cash',
      type: 'cash',
      currency: 'EGP',
    );
    const cashInitial = 10000.0;
    final cashInitialTx = Transaction.create(
      amount: cashInitial,
      type: TransactionType.initialBalance,
      toAccountId: cashAccount.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await transactionService.addTransaction(cashInitialTx);
    initialTotalMoney += cashInitial;
    
    final bankAccount = await accountService.createAccount(
      name: 'Bank',
      type: 'bank',
      currency: 'EGP',
    );
    const bankInitial = 5000.0;
    final bankInitialTx = Transaction.create(
      amount: bankInitial,
      type: TransactionType.initialBalance,
      toAccountId: bankAccount.id,
      fromAccountId: null,
      categoryId: 'initial_balance',
      date: DateTime.now(),
      source: TransactionSource.accountCreation,
    );
    await transactionService.addTransaction(bankInitialTx);
    initialTotalMoney += bankInitial;
    
    const transferAmount = 2000.0;
    final transferTx = Transaction.create(
      amount: transferAmount,
      type: TransactionType.transfer,
      fromAccountId: cashAccount.id,
      toAccountId: bankAccount.id,
      categoryId: 'transfer',
      date: DateTime.now(),
      source: TransactionSource.manual,
    );
    await transactionService.addTransaction(transferTx);
    
    const expenseAmount = 1000.0;
    final expenseTx = Transaction.create(
      amount: expenseAmount,
      type: TransactionType.expense,
      fromAccountId: cashAccount.id,
      toAccountId: null,
      categoryId: 'food',
      date: DateTime.now(),
      source: TransactionSource.manual,
    );
    await transactionService.addTransaction(expenseTx);
    
    const reservedAmount = 500.0;
    final reservedItem = ReservedMoney.create(
      accountId: cashAccount.id,
      title: 'Savings Bucket',
      amount: reservedAmount,
      type: ReservedMoneyType.bucket,
    );
    await reservedService.add(reservedItem);
    
    double finalTotalMoney = 0;
    finalTotalMoney += balanceService.getBalance(cashAccount.id);
    finalTotalMoney += balanceService.getBalance(bankAccount.id);
    
    final totalReserved = reservedService.getReservedAmount(cashAccount.id);
    
    expect(initialTotalMoney, finalTotalMoney + totalReserved);
  });
}