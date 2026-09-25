import '../../core/money/money.dart';

final class EntryLine {
  final String accountId;
  final Money debit;
  final Money credit;

  EntryLine({
    required this.accountId,
    Money? debit,
    Money? credit,
  }) : debit = debit ?? Money.zero,
       credit = credit ?? Money.zero {
    assert(
      !this.debit.isNegative && !this.credit.isNegative,
      'Debit and credit must not be negative.',
    );
    assert(
      this.debit.isZero || this.credit.isZero,
      'A line cannot contain both debit and credit.',
    );
  }
}
