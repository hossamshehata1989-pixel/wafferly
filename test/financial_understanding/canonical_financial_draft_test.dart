import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_understanding/domain/financial_input_channel.dart';
import 'package:wafferly/financial_understanding/domain/canonical_financial_draft.dart';
import 'package:wafferly/financial_understanding/domain/financial_event_proposal.dart';

void main() {
  final createdAt = DateTime(2026, 10, 18, 12);

  test('event status and draft review status are separate concepts', () {
    final draft = CanonicalFinancialDraft(
      candidateId: 'candidate-1',
      proposal: FinancialEventProposal(
        eventType: FinancialEventType.expense,
        direction: FinancialEventDirection.debit,
        amount: Money.parse('125.50'),
        currencyCode: 'EGP',
        eventStatus: FinancialEventStatus.posted,
      ),
      provenance: FinancialDraftProvenance(
        inputChannel: FinancialInputChannel.sms,
        providerId: 'synthetic-test-provider',
        providerVersion: '1',
        confidence: 0.95,
      ),
      status: FinancialDraftStatus.pendingReview,
      unresolvedFields: const <FinancialDraftField>{},
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(draft.proposal.eventStatus, FinancialEventStatus.posted);
    expect(draft.status, FinancialDraftStatus.pendingReview);
    expect(draft.isCompleteForReview, isTrue);
  });

  test('an amount remains exact and must be positive', () {
    final proposal = FinancialEventProposal(
      eventType: FinancialEventType.refund,
      direction: FinancialEventDirection.credit,
      amount: Money.parse('12.30'),
      currencyCode: 'EGP',
    );

    expect(proposal.amount, Money.parse('12.30'));
    expect(
      () => FinancialEventProposal(
        eventType: FinancialEventType.expense,
        amount: Money.parse('0'),
      ),
      throwsArgumentError,
    );
  });

  test('a saved draft must point to its resulting transaction', () {
    expect(
      () => CanonicalFinancialDraft(
        candidateId: 'candidate-2',
        proposal: FinancialEventProposal(
          eventType: FinancialEventType.income,
          amount: Money.parse('10'),
        ),
        provenance: FinancialDraftProvenance(
          inputChannel: FinancialInputChannel.sms,
          providerId: 'test',
          providerVersion: '1',
        ),
        status: FinancialDraftStatus.confirmedSaved,
        unresolvedFields: const <FinancialDraftField>{},
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsArgumentError,
    );
  });

  test('confidence must be finite and between zero and one', () {
    expect(
      () => FinancialDraftProvenance(
        inputChannel: FinancialInputChannel.sms,
        providerId: 'test',
        providerVersion: '1',
        confidence: 1.5,
      ),
      throwsArgumentError,
    );
  });
}
