import 'package:hive_flutter/hive_flutter.dart';
import '../../core/money/money.dart';
import '../../financing/domain/credit_card_financing_conversion.dart';
import '../../models/account.dart';
import '../../models/enums/account_enums.dart';
import '../../models/schedule_rule.dart';
import '../../models/transaction.dart';
import '../../models/enums/frequency.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_schedule.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/financing/financing_conversion_event.dart';

/// Application boundary for Credit Card financing actions.
///
/// The UI supplies user intent; the existing financing domain operation owns
/// persistence and invariants. This service does not create a second financial
/// transaction during conversion.
final class CreditCardFinancingApplicationService {
  CreditCardFinancingApplicationService({
    Box<Account>? accounts,
    Box<Transaction>? transactions,
    Box<FinancingContract>? contracts,
    Box<FinancingSchedule>? schedules,
    Box<FinancingInstallment>? installments,
    Box<FinancingConversionEvent>? conversionEvents,
    Box<ScheduleRule>? scheduleRules,
  })  : _accounts = accounts ?? Hive.box<Account>('accounts'),
        _transactions = transactions ?? Hive.box<Transaction>('transactions'),
        _contracts = contracts ?? Hive.box<FinancingContract>('financing_contracts'),
        _schedules = schedules ?? Hive.box<FinancingSchedule>('financing_schedules'),
        _installments = installments ?? Hive.box<FinancingInstallment>('financing_installments'),
        _conversionEvents = conversionEvents ?? Hive.box<FinancingConversionEvent>('financing_conversion_events'),
        _scheduleRules = scheduleRules ?? Hive.box<ScheduleRule>('schedule_rules');

  final Box<Account> _accounts;
  final Box<Transaction> _transactions;
  final Box<FinancingContract> _contracts;
  final Box<FinancingSchedule> _schedules;
  final Box<FinancingInstallment> _installments;
  final Box<FinancingConversionEvent> _conversionEvents;
  final Box<ScheduleRule> _scheduleRules;


  Future<CreditCardFinancingConversionResult> convertCharge({
    required Transaction charge,
    required int installmentCount,
    required DateTime firstDueDate,
  }) async {
    if (charge.type != 'credit_card_charge' || charge.toAccountId == null) {
      throw ArgumentError('A Credit Card charge is required for conversion.');
    }
    if (installmentCount < 1) {
      throw ArgumentError('Installment count must be at least 1.');
    }

    final account = _accounts.get(charge.toAccountId);
    if (account == null || account.type != 'creditCard' || account.nature != AccountNature.liability) {
      throw StateError('The originating account is not a valid Credit Card.');
    }

    final totalCents = (charge.amount * 100).round();
    final baseCents = totalCents ~/ installmentCount;
    final remainder = totalCents % installmentCount;
    // Financing conversion is a logical operation tied to one immutable
    // origin charge. These identities MUST remain stable across retries; a
    // fresh UUID per attempt would make a retry look like a new financing
    // operation even when the charge already exists.
    final conversionId = 'conversion-cc-charge-${charge.id}';
    final contractId = 'contract-cc-charge-${charge.id}';
    final scheduleId = 'schedule-cc-charge-${charge.id}';
    final ruleId = 'rule-cc-charge-${charge.id}';
    final now = DateTime.now();

    final rule = ScheduleRule(
      id: ruleId,
      frequency: Frequency.monthly,
      startDate: firstDueDate,
      nextDueDate: firstDueDate,
    );
    await _scheduleRules.put(rule.id, rule);

    final drafts = List<FinancingInstallmentDraft>.generate(
      installmentCount,
      (index) {
        final cents = baseCents + (index == installmentCount - 1 ? remainder : 0);
        final value = (cents / 100).toStringAsFixed(2);
        final dueDate = _addMonths(firstDueDate, index);
        return FinancingInstallmentDraft(
          dueDate: dueDate,
          principal: Money.parse(value),
          interest: Money.zero,
          fees: Money.zero,
        );
      },
    );

    final operation = CreditCardFinancingConversionOperation(
      accounts: _accounts,
      transactions: _transactions,
      contracts: _contracts,
      schedules: _schedules,
      installments: _installments,
      conversionEvents: _conversionEvents,
      scheduleRules: _scheduleRules,
    );

    try {
      return await operation.execute(
        CreditCardFinancingConversionRequest(
          conversionId: conversionId,
          originChargeId: charge.id,
          contractId: contractId,
          scheduleId: scheduleId,
          scheduleRuleId: ruleId,
          liabilityAccountId: account.id,
          paymentFrequency: 'monthly',
          firstDueDate: firstDueDate,
          installments: drafts,
          effectiveDate: charge.date,
          createdAt: now,
        ),
      );
    } catch (_) {
      await _scheduleRules.delete(ruleId);
      rethrow;
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(target.year, target.month, day);
  }
}
