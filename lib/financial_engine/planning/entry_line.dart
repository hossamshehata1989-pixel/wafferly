final class EntryLine {
  final String accountId;

  final double debit;

  final double credit;

  const EntryLine({required this.accountId, this.debit = 0, this.credit = 0})
    : assert(
        debit >= 0 && credit >= 0,
        'Debit and credit must not be negative.',
      ),
      assert(
        debit == 0 || credit == 0,
        'A line cannot contain both debit and credit.',
      );
}
