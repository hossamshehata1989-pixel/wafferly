import 'package:hive/hive.dart';

import '../../constants/transaction_constants.dart';
import '../../models/account.dart';
import '../../models/enums/account_enums.dart';
import '../../models/schedule_rule.dart';
import '../../models/transaction.dart';
import '../../core/money/money.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_conversion_event.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/financing/financing_schedule.dart';

const String financingContractBoxName = 'financing_contracts';
const String financingScheduleBoxName = 'financing_schedules';
const String financingInstallmentBoxName = 'financing_installments';
const String financingConversionEventBoxName = 'financing_conversion_events';
const String financingConversionCompleted = 'completed';
const String financingConversionStarted = 'started';

final class FinancingInstallmentDraft {
  final DateTime dueDate;
  final Money principal;
  final Money interest;
  final Money fees;

  FinancingInstallmentDraft({
    required this.dueDate,
    required this.principal,
    Money? interest,
    Money? fees,
  })  : interest = interest ?? Money.zero,
        fees = fees ?? Money.zero;

  Money get amount => principal + interest + fees;
}

final class CreditCardFinancingConversionRequest {
  final String conversionId;
  final String originChargeId;
  final String contractId;
  final String scheduleId;
  final String scheduleRuleId;
  final String liabilityAccountId;
  final String paymentFrequency;
  final DateTime firstDueDate;
  final List<FinancingInstallmentDraft> installments;
  final String? interestPolicyId;
  final DateTime effectiveDate;
  final DateTime createdAt;

  const CreditCardFinancingConversionRequest({
    required this.conversionId,
    required this.originChargeId,
    required this.contractId,
    required this.scheduleId,
    required this.scheduleRuleId,
    required this.liabilityAccountId,
    required this.paymentFrequency,
    required this.firstDueDate,
    required this.installments,
    required this.effectiveDate,
    required this.createdAt,
    this.interestPolicyId,
  });
}

final class CreditCardFinancingConversionResult {
  final FinancingContract contract;
  final FinancingSchedule schedule;
  final List<FinancingInstallment> installments;
  final bool alreadyCompleted;

  const CreditCardFinancingConversionResult({
    required this.contract,
    required this.schedule,
    required this.installments,
    required this.alreadyCompleted,
  });
}

/// Converts an already-posted Credit Card charge into contractual financing.
///
/// This service is intentionally outside the financial operation pipeline because the
/// MVP conversion creates no new financial effect. It only writes financing
/// domain persistence. Account/Transaction/Ledger/Balance/idempotency stores
/// are read-only inputs here.
final class CreditCardFinancingConversionOperation {
  final Box<Account> accounts;
  final Box<Transaction> transactions;
  final Box<FinancingContract> contracts;
  final Box<FinancingSchedule> schedules;
  final Box<FinancingInstallment> installments;
  final Box<FinancingConversionEvent> conversionEvents;
  final Box<ScheduleRule> scheduleRules;

  CreditCardFinancingConversionOperation({
    required this.accounts,
    required this.transactions,
    required this.contracts,
    required this.schedules,
    required this.installments,
    required this.conversionEvents,
    required this.scheduleRules,
  });

  Future<CreditCardFinancingConversionResult> execute(
    CreditCardFinancingConversionRequest request,
  ) async {
    _validateRequestShape(request);

    final existingEvent = conversionEvents.get(request.conversionId);
    if (existingEvent != null) {
      if (existingEvent.originChargeId != request.originChargeId ||
          existingEvent.contractId != request.contractId ||
          existingEvent.scheduleId != request.scheduleId) {
        throw StateError(
          'Conversion identity is already bound to a different financing plan.',
        );
      }

      final existingContract = contracts.get(existingEvent.contractId);
      final existingSchedule = schedules.get(existingEvent.scheduleId);
      if (existingContract != null && existingSchedule != null) {
        final existingInstallments = installments.values
            .where((item) => item.contractId == existingContract.contractId)
            .toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));

        if (existingEvent.status == financingConversionCompleted) {
          return CreditCardFinancingConversionResult(
            contract: existingContract,
            schedule: existingSchedule,
            installments: existingInstallments,
            alreadyCompleted: true,
          );
        }
      }
    }

    final charge = transactions.get(request.originChargeId);
    _validateOriginCharge(charge, request);

    final existingOriginConversion = conversionEvents.values.where(
      (event) =>
          event.originChargeId == request.originChargeId &&
          event.status == financingConversionCompleted &&
          event.conversionId != request.conversionId,
    ).toList();
    if (existingOriginConversion.isNotEmpty) {
      throw StateError('Originating charge is already converted into financing.');
    }

    final account = accounts.get(request.liabilityAccountId);
    _validateLiabilityAccount(account, request.liabilityAccountId);

    final principal = Money.fromDouble(charge!.amount);
    final installmentPrincipal = request.installments.fold(
      Money.zero,
      (sum, item) => sum + item.principal,
    );
    if (installmentPrincipal != principal) {
      throw ArgumentError(
        'Installment principal total must equal the originating charge amount.',
      );
    }

    final event = existingEvent ??
        FinancingConversionEvent(
          conversionId: request.conversionId,
          originChargeId: request.originChargeId,
          contractId: request.contractId,
          scheduleId: request.scheduleId,
          scheduleRuleId: request.scheduleRuleId,
          status: financingConversionStarted,
          createdAt: request.createdAt,
          updatedAt: request.createdAt,
        );

    await conversionEvents.put(request.conversionId, event);

    final createdInstallmentKeys = <String>[];
    var createdContract = false;
    var createdSchedule = false;

    try {
      final contract = contracts.get(request.contractId) ?? FinancingContract(
        contractId: request.contractId,
        liabilityAccountId: request.liabilityAccountId,
        originReference: request.originChargeId,
        principalValue: principal.toString(),
        installmentCount: request.installments.length,
        paymentFrequency: request.paymentFrequency,
        firstDueDate: request.firstDueDate,
        lifecycleState: 'active',
        effectiveDate: request.effectiveDate,
        createdAt: request.createdAt,
        interestPolicyId: request.interestPolicyId,
      );

      _validateExistingContract(contract, request, principal);
      if (contracts.get(request.contractId) == null) {
        await contracts.put(request.contractId, contract);
        createdContract = true;
      }

      final rule = scheduleRules.get(request.scheduleRuleId);
      if (rule == null) {
        throw StateError(
          'Financing conversion requires an existing ScheduleRule.',
        );
      }
      if (rule.startDate != request.firstDueDate) {
        throw StateError(
          'Existing ScheduleRule start date conflicts with conversion request.',
        );
      }

      final schedule = schedules.get(request.scheduleId) ?? FinancingSchedule(
        scheduleId: request.scheduleId,
        contractId: request.contractId,
        scheduleRuleId: request.scheduleRuleId,
        installmentCount: request.installments.length,
        status: 'active',
        createdAt: request.createdAt,
      );
      _validateExistingSchedule(schedule, request);
      if (schedules.get(request.scheduleId) == null) {
        await schedules.put(request.scheduleId, schedule);
        createdSchedule = true;
      }

      for (var index = 0; index < request.installments.length; index++) {
        final draft = request.installments[index];
        final installmentId = '${request.scheduleId}|${index + 1}';
        final item = FinancingInstallment(
          installmentId: installmentId,
          contractId: request.contractId,
          scheduleId: request.scheduleId,
          sequence: index + 1,
          dueDate: draft.dueDate,
          openingPrincipalValue: _openingPrincipal(
            principal,
            request.installments,
            index,
          ).toString(),
          principalComponentValue: draft.principal.toString(),
          interestComponentValue: draft.interest.toString(),
          feesValue: draft.fees.toString(),
          amountValue: draft.amount.toString(),
          status: 'scheduled',
        );

        final existing = installments.get(installmentId);
        if (existing != null) {
          _validateExistingInstallment(existing, item);
        } else {
          await installments.put(installmentId, item);
          createdInstallmentKeys.add(installmentId);
        }
      }

      final completedEvent = event.copyWith(
        status: financingConversionCompleted,
        updatedAt: DateTime.now(),
      );
      await conversionEvents.put(request.conversionId, completedEvent);

      final finalInstallments = installments.values
          .where((item) => item.contractId == request.contractId)
          .toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

      return CreditCardFinancingConversionResult(
        contract: contract,
        schedule: schedule,
        installments: finalInstallments,
        alreadyCompleted: false,
      );
    } catch (_) {
      for (final key in createdInstallmentKeys) {
        await installments.delete(key);
      }
      if (createdSchedule) {
        await schedules.delete(request.scheduleId);
      }
      if (createdContract) {
        await contracts.delete(request.contractId);
      }
      await conversionEvents.delete(request.conversionId);
      rethrow;
    }
  }

  void _validateRequestShape(CreditCardFinancingConversionRequest request) {
    if (request.conversionId.trim().isEmpty ||
        request.originChargeId.trim().isEmpty ||
        request.contractId.trim().isEmpty ||
        request.scheduleId.trim().isEmpty ||
        request.scheduleRuleId.trim().isEmpty) {
      throw ArgumentError('Conversion identities must not be empty.');
    }
    if (request.installments.isEmpty) {
      throw ArgumentError('At least one installment is required.');
    }
    if (request.installments.any((item) =>
        !item.principal.isPositive ||
        item.interest.isNegative ||
        item.fees.isNegative)) {
      throw ArgumentError('Installment monetary components are invalid.');
    }
    for (var i = 1; i < request.installments.length; i++) {
      if (!request.installments[i].dueDate.isAfter(
            request.installments[i - 1].dueDate,
          )) {
        throw ArgumentError('Installment due dates must be strictly increasing.');
      }
    }
  }

  void _validateOriginCharge(
    Transaction? charge,
    CreditCardFinancingConversionRequest request,
  ) {
    if (charge == null) {
      throw StateError('Originating charge was not found.');
    }
    if (charge.type != TransactionType.creditCardCharge ||
        charge.source != TransactionSource.creditCardCharge) {
      throw StateError('Origin transaction is not a Credit Card charge.');
    }
    if (charge.toAccountId != request.liabilityAccountId) {
      throw StateError('Origin charge does not belong to the target card account.');
    }
    if (charge.amount <= 0) {
      throw StateError('Originating charge amount must be positive.');
    }
  }

  void _validateLiabilityAccount(Account? account, String accountId) {
    if (account == null) {
      throw StateError('Credit Card liability account was not found.');
    }
    if (account.isArchived ||
        account.nature != AccountNature.liability ||
        account.type != 'creditCard') {
      throw StateError('Target account is not an active Credit Card liability.');
    }
  }

  void _validateExistingContract(
    FinancingContract contract,
    CreditCardFinancingConversionRequest request,
    Money principal,
  ) {
    if (contract.originReference != request.originChargeId ||
        contract.liabilityAccountId != request.liabilityAccountId ||
        contract.principal != principal ||
        contract.installmentCount != request.installments.length) {
      throw StateError('Existing financing contract conflicts with conversion request.');
    }
  }

  void _validateExistingSchedule(
    FinancingSchedule schedule,
    CreditCardFinancingConversionRequest request,
  ) {
    if (schedule.contractId != request.contractId ||
        schedule.scheduleRuleId != request.scheduleRuleId ||
        schedule.installmentCount != request.installments.length) {
      throw StateError('Existing financing schedule conflicts with conversion request.');
    }
  }

  void _validateExistingInstallment(
    FinancingInstallment existing,
    FinancingInstallment expected,
  ) {
    if (existing.contractId != expected.contractId ||
        existing.scheduleId != expected.scheduleId ||
        existing.sequence != expected.sequence ||
        existing.dueDate != expected.dueDate ||
        existing.principalComponent != expected.principalComponent ||
        existing.interestComponent != expected.interestComponent ||
        existing.fees != expected.fees ||
        existing.amount != expected.amount) {
      throw StateError(
        'Existing financing installment conflicts with conversion request.',
      );
    }
  }

  Money _openingPrincipal(
    Money total,
    List<FinancingInstallmentDraft> drafts,
    int index,
  ) {
    var opening = total;
    for (var i = 0; i < index; i++) {
      opening -= drafts[i].principal;
    }
    return opening;
  }

}
