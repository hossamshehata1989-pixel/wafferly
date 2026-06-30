sealed class FinancialMutation {
  const FinancialMutation();
}

class CreateTransaction extends FinancialMutation {
  const CreateTransaction();
}

class CreateLedgerEntry extends FinancialMutation {
  const CreateLedgerEntry();
}

class CreateScheduledAction extends FinancialMutation {
  const CreateScheduledAction();
}
