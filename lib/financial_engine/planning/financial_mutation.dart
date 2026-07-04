abstract base class FinancialMutation {
  const FinancialMutation();
}

/// Represents accounting truth.
///
/// These mutations participate in accounting integrity
/// (e.g. debits must equal credits).
abstract base class AccountingMutation extends FinancialMutation {
  const AccountingMutation();
}

/// Represents non-accounting domain state changes.
///
/// These mutations do NOT participate in accounting balance.
abstract base class DomainMutation extends FinancialMutation {
  const DomainMutation();
}
