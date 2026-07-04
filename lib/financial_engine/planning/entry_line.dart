final class EntryLine {
  final String accountId;

  final double debit;

  final double credit;

  const EntryLine({required this.accountId, this.debit = 0, this.credit = 0})
    : assert(
        (debit == 0) != (credit == 0),
        'Exactly one of debit or credit must be greater than zero.',
      );
}
