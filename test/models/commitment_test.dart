import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/models/commitment.dart';
import 'package:wafferly/models/enums/commitment_amount_mode.dart';
import 'package:wafferly/models/enums/commitment_status.dart';
import 'package:wafferly/models/enums/commitment_type.dart';

void main() {
  Commitment buildCommitment({Money? amount}) {
    return Commitment(
      id: 'commitment-1',
      title: 'Test Commitment',
      type: CommitmentType.expense,
      status: CommitmentStatus.active,
      amount: amount ?? Money.parse('125.50'),
      amountMode: CommitmentAmountMode.fixed,
      scheduleRuleId: 'schedule-1',
    );
  }

  group('Commitment.amount migration', () {
    test('stores amount as Money in the domain model', () {
      final commitment = buildCommitment();

      expect(commitment.amount, Money.parse('125.50'));
expect(commitment.amount, Money.parse('125.50'));    });

    test('copyWith preserves the existing Money amount when omitted', () {
      final commitment = buildCommitment();

      final updated = commitment.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.amount, Money.parse('125.50'));
    });

    test('copyWith accepts and replaces amount with Money', () {
      final commitment = buildCommitment();

      final updated = commitment.copyWith(
        amount: Money.parse('0.10'),
      );

      expect(updated.amount, Money.parse('0.10'));
    });
  });
}
