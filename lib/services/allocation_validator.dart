import 'package:flutter/foundation.dart';
import 'balance_service.dart';

class AllocationValidator {
  final BalanceService _balanceService = BalanceService();

  bool canAllocate({required String accountId, required double amount}) {
    final available = _balanceService.getAvailableBalance(accountId);

    debugPrint('ACCOUNT = $accountId');
    debugPrint('AVAILABLE = $available');
    debugPrint('AMOUNT = $amount');

    return available >= amount;
  }
}
