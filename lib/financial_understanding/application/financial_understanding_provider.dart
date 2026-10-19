import '../domain/canonical_financial_draft.dart';
import '../domain/financial_event_proposal.dart';
import '../domain/financial_input_channel.dart';

final class FinancialUnderstandingRequest {
  const FinancialUnderstandingRequest({
    required this.normalizedText,
    required this.inputChannel,
    required this.receivedAt,
    this.providerHint,
  });

  /// Normalized text held in memory for processing; do not persist it as a draft.
  final String normalizedText;
  final FinancialInputChannel inputChannel;
  final DateTime receivedAt;

  /// A locally mapped issuer ID/name. Must not be a raw phone number or address.
  final String? providerHint;
}

sealed class FinancialUnderstandingResult {
  const FinancialUnderstandingResult();
}

/// Provider recognized the input well enough to propose a structured event.
final class FinancialInterpretationFound extends FinancialUnderstandingResult {
  FinancialInterpretationFound({
    required this.proposal,
    required this.providerId,
    required this.providerVersion,
    this.confidence,
    Set<FinancialDraftField> unresolvedFields = const <FinancialDraftField>{},
    this.providerHint,
  }) : unresolvedFields = Set<FinancialDraftField>.unmodifiable(
         unresolvedFields,
       ) {
    if (confidence != null &&
        (!confidence!.isFinite || confidence! < 0 || confidence! > 1)) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'Confidence must be a finite value between 0 and 1.',
      );
    }
    if (providerId.trim().isEmpty || providerVersion.trim().isEmpty) {
      throw ArgumentError('Provider ID and version must not be empty.');
    }
  }

  final FinancialEventProposal proposal;
  final String providerId;
  final String providerVersion;
  final double? confidence;
  final Set<FinancialDraftField> unresolvedFields;
  final String? providerHint;
}

/// Input may be financial, but required meaning/fields are unclear.
final class FinancialInterpretationNeedsClarification
    extends FinancialUnderstandingResult {
  FinancialInterpretationNeedsClarification({
    required this.reasonCode,
    this.partialProposal,
    Set<FinancialDraftField> unresolvedFields = const <FinancialDraftField>{},
  }) : unresolvedFields = Set<FinancialDraftField>.unmodifiable(
         unresolvedFields,
       ) {
    if (reasonCode.trim().isEmpty) {
      throw ArgumentError.value(
        reasonCode,
        'reasonCode',
        'A clarification result must provide a reason code.',
      );
    }
  }

  final String reasonCode;
  final FinancialEventProposal? partialProposal;
  final Set<FinancialDraftField> unresolvedFields;
}

/// This provider has no safe interpretation for the current input. A registry
/// may try a later provider; it must not turn this result into a transaction.
final class FinancialInterpretationNoMatch extends FinancialUnderstandingResult {
  const FinancialInterpretationNoMatch();
}

/// Common IFUP contract implemented by deterministic templates and AI adapters.
///
/// Implementations return proposals only. They must not read/write financial
/// persistence or execute FinancialOperationEngine operations.
abstract interface class FinancialUnderstandingProvider {
  String get providerId;
  String get providerVersion;

  Future<FinancialUnderstandingResult> understand(
    FinancialUnderstandingRequest request,
  );
}
