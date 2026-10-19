import '../../core/money/money.dart';

/// The financial event described by an input message or user utterance.
///
/// This is a proposal only. It is not a financial transaction and must never
/// be persisted as financial truth directly by an input adapter or AI provider.
enum FinancialEventType {
  expense,
  income,
  transfer,
  creditCardPurchase,
  creditCardPayment,
  fee,
  installment,
  refund,
  reversal,
  unknown,
}

/// The direction of the event from the user's perspective.
enum FinancialEventDirection { debit, credit, transfer, unknown }

/// The status of the underlying financial event, not the draft review status.
enum FinancialEventStatus { pending, posted, reversed, unknown }

final class FinancialEventProposal {
  FinancialEventProposal({
    required this.eventType,
    required this.amount,
    this.direction = FinancialEventDirection.unknown,
    this.currencyCode,
    this.occurredAt,
    this.payee,
    this.sourceAccountHint,
    this.destinationAccountHint,
    this.eventStatus = FinancialEventStatus.unknown,
  }) {
    if (amount != null && !amount!.isPositive) {
      throw ArgumentError.value(
        amount,
        'amount',
        'A proposed event amount must be positive; represent direction and '
            'refund/reversal semantics separately.',
      );
    }

    if (currencyCode != null && currencyCode!.trim().isEmpty) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'Currency code must be omitted or non-empty.',
      );
    }
  }

  final FinancialEventType eventType;
  final FinancialEventDirection direction;

  /// Exact money value. Null means the amount was not reliably understood.
  final Money? amount;

  /// ISO-style currency code when known, e.g. EGP. Not inferred from amount.
  final String? currencyCode;

  final DateTime? occurredAt;
  final String? payee;
  final String? sourceAccountHint;
  final String? destinationAccountHint;
  final FinancialEventStatus eventStatus;
}
