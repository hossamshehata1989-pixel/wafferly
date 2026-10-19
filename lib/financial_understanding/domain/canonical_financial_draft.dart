import 'financial_event_proposal.dart';
import 'financial_input_channel.dart';

/// Lifecycle of a proposal awaiting user review.
///
/// Do not confuse these values with [FinancialEventStatus], which describes
/// the underlying bank/payment event.
enum FinancialDraftStatus {
  pendingReview,
  needsClarification,
  confirmedSaved,
  rejected,
  matchedExisting,
  expired,
}

enum FinancialDraftField {
  eventType,
  direction,
  amount,
  currencyCode,
  occurredAt,
  payee,
  sourceAccount,
  destinationAccount,
  eventStatus,
}

/// Processing provenance only. This intentionally contains no raw SMS body,
/// sender phone number, AI chain-of-thought, or secret key material.
final class FinancialDraftProvenance {
  FinancialDraftProvenance({
    required this.inputChannel,
    required this.providerId,
    required this.providerVersion,
    this.confidence,
    this.providerHint,
  }) {
    if (confidence != null &&
        (!confidence!.isFinite || confidence! < 0 || confidence! > 1)) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'Confidence must be a finite value between 0 and 1.',
      );
    }
  }

  final FinancialInputChannel inputChannel;
  final String providerId;
  final String providerVersion;
  final double? confidence;

  /// A locally resolved issuer/provider identifier, never a raw sender address.
  final String? providerHint;
}

/// A reviewable draft, not an authoritative financial transaction.
///
/// Message fingerprints and financial idempotency keys are separate identities
/// and intentionally do not live on this model.
final class CanonicalFinancialDraft {
  CanonicalFinancialDraft({
    required this.candidateId,
    required this.proposal,
    required this.provenance,
    required this.status,
    required Set<FinancialDraftField> unresolvedFields,
    required this.createdAt,
    required this.updatedAt,
    this.resultingTransactionId,
  }) : unresolvedFields = Set<FinancialDraftField>.unmodifiable(
         unresolvedFields,
       ) {
    if (candidateId.trim().isEmpty) {
      throw ArgumentError.value(
        candidateId,
        'candidateId',
        'Candidate ID must not be empty.',
      );
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Updated time cannot be earlier than creation time.',
      );
    }
    if (status == FinancialDraftStatus.confirmedSaved &&
        (resultingTransactionId == null ||
            resultingTransactionId!.trim().isEmpty)) {
      throw ArgumentError(
        'A saved draft must identify the resulting financial transaction.',
      );
    }
  }

  final String candidateId;
  final FinancialEventProposal proposal;
  final FinancialDraftProvenance provenance;
  final FinancialDraftStatus status;
  final Set<FinancialDraftField> unresolvedFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resultingTransactionId;

  /// Confidence never authorizes saving. This helper only says whether the
  /// draft's review fields are complete; supported-operation and execution
  /// checks still belong to the financial application/engine boundary.
  bool get isCompleteForReview => unresolvedFields.isEmpty;
}
