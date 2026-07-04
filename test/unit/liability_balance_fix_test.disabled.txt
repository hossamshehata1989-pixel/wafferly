// test/unit/liability_balance_fix_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/services/balance_service.dart';

const String TEST_BOX_NAME = 'test_transactions_fix';

class TestableBalanceService extends BalanceService {
  final Box<Transaction> customTxBox;
  
  TestableBalanceService(this.customTxBox);
  
  @override
  Box<Transaction> get txBox => customTxBox;
}

void main() async {
  late Box<Transaction> testTxBox;
  late Box<Account> testAccountBox;
  
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
    
    testAccountBox = await Hive.openBox<Account>('test_accounts_fix');
    testTxBox = await Hive.openBox<Transaction>(TEST_BOX_NAME);
  });
  
  tearDownAll(() async {
    await testAccountBox.clear();
    await testTxBox.clear();
    await Hive.deleteBoxFromDisk('test_accounts_fix');
    await Hive.deleteBoxFromDisk(TEST_BOX_NAME);
  });
  
  tearDown(() async {
    await testAccountBox.clear();
    await testTxBox.clear();
  });
  
  class TestAccountService {
    Future<Account> createAccount({
      required String name,
      required String type,
      required String currency,
    }) async {
      final account = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: 'test',
        memberId: 'tester',
        name: name,
        type: type,
        currency: currency,
        createdAt: DateTime.now(),
        group: type == 'loan' ? AccountGroup.moneyYouOwe : AccountGroup.moneyYouHave,
        nature: type == 'loan' ? AccountNature.liability : AccountNature.asset,
        isArchived: false,
      );
      await testAccountBox.put(account.id, account);
      return account;
    }
  }
  
  group('Initial Liability Balance Fix - Runtime Verification', () {
    
    late TestAccountService accountService;
    late TestableBalanceService balanceService;
    
    setUp(() {
      accountService = TestAccountService();
      balanceService = TestableBalanceService(testTxBox);
    });
    
    test('TEST 1: Asset account initial balance is positive', () async {
      const initialAmount = 10000.0;
      
      final account = await accountService.createAccount(
        name: 'Cash',
        type: 'cash',
        currency: 'EGP',
      );
      
      final initialTx = Transaction.create(
        amount: initialAmount,
        type: TransactionType.initialBalance,
        toAccountId: account.id,
        fromAccountId: null,
        categoryId: 'initial_balance',
        date: DateTime.now(),
        source: TransactionSource.accountCreation,
      );
      await testTxBox.put(initialTx.id, initialTx);
      
      final balance = balanceService.getBalance(account.id);
      
      expect(balance, initialAmount);
    });
    
    test('TEST 2: Liability account initial balance is NEGATIVE', () async {
      const initialAmount = 50000.0;
      
      final account = await accountService.createAccount(
        name: 'Loan',
        type: 'loan',
        currency: 'EGP',
      );
      
      final initialTx = Transaction.create(
        amount: initialAmount,
        type: TransactionType.initialBalance,
        toAccountId: null,
        fromAccountId: account.id,
        categoryId: 'initial_balance',
        date: DateTime.now(),
        source: TransactionSource.accountCreation,
      );
      await testTxBox.put(initialTx.id, initialTx);
      
      final balance = balanceService.getBalance(account.id);
      
      expect(balance, -initialAmount);
    });
    
    test('TEST 3: Liability with transfer preserves negative balance', () async {
      const initialAmount = 50000.0;
      const paymentAmount = 10000.0;
      
      final loanAccount = await accountService.createAccount(
        name: 'Loan',
        type: 'loan',
        currency: 'EGP',
      );
      
      final cashAccount = await accountService.createAccount(
        name: 'Cash',
        type: 'cash',
        currency: 'EGP',
      );
      
      final initialTx = Transaction.create(
        amount: initialAmount,
        type: TransactionType.initialBalance,
        toAccountId: null,
        fromAccountId: loanAccount.id,
        categoryId: 'initial_balance',
        date: DateTime.now(),
        source: TransactionSource.accountCreation,
      );
      await testTxBox.put(initialTx.id, initialTx);
      
      final cashInitialTx = Transaction.create(
        amount: 20000,
        type: TransactionType.initialBalance,
        toAccountId: cashAccount.id,
        fromAccountId: null,
        categoryId: 'initial_balance',
        date: DateTime.now(),
        source: TransactionSource.accountCreation,
      );
      await testTxBox.put(cashInitialTx.id, cashInitialTx);
      
      final paymentTx = Transaction.create(
        amount: paymentAmount,
        type: TransactionType.transfer,
        fromAccountId: cashAccount.id,
        toAccountId: loanAccount.id,
        categoryId: 'loan_payment',
        date: DateTime.now(),
        source: TransactionSource.manual,
      );
      await testTxBox.put(paymentTx.id, paymentTx);
      
      final loanBalance = balanceService.getBalance(loanAccount.id);
      final expectedLoanBalance = -(initialAmount - paymentAmount);
      
      expect(loanBalance, expectedLoanBalance);
    });
    
    test('TEST 4: Liability historical balance at date works', () async {
      const initialAmount = 50000.0;
      const paymentAmount = 10000.0;
      
      final date1 = DateTime(2024, 1, 1);
      final date2 = DateTime(2024, 2, 1);
      
      final loanAccount = await accountService.createAccount(
        name: 'Loan',
        type: 'loan',
        currency: 'EGP',
      );
      
      final cashAccount = await accountService.createAccount(
        name: 'Cash',
        type: 'cash',
        currency: 'EGP',
      );
      
      final initialTx = Transaction.create(
        amount: initialAmount,
        type: TransactionType.initialBalance,
        toAccountId: null,
        fromAccountId: loanAccount.id,
        categoryId: 'initial_balance',
        date: date1,
        source: TransactionSource.accountCreation,
      );
      await testTxBox.put(initialTx.id, initialTx);
      
      final cashInitialTx = Transaction.create(
        amount: 20000,
        type: TransactionType.initialBalance,
        toAccountId: cashAccount.id,
        fromAccountId: null,
        categoryId: 'initial_balance',
        date: date1,
        source: TransactionSource.accountCreation,
      );
      await testTxBox.put(cashInitialTx.id, cashInitialTx);
      
      final paymentTx = Transaction.create(
        amount: paymentAmount,
        type: TransactionType.transfer,
        fromAccountId: cashAccount.id,
        toAccountId: loanAccount.id,
        categoryId: 'loan_payment',
        date: date2,
        source: TransactionSource.manual,
      );
      await testTxBox.put(paymentTx.id, paymentTx);
      
      final balanceAtDate1 = balanceService.getBalanceAtDate(loanAccount.id, date1);
      final balanceAtDate2 = balanceService.getBalanceAtDate(loanAccount.id, date2);
      
      expect(balanceAtDate1, -initialAmount);
      expect(balanceAtDate2, -(initialAmount - paymentAmount));
    });
  });
}