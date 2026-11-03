-- Wafferly M3.3 SQLite capability spike (representative subset only).
-- This tests SQLite DDL/runtime behavior, NOT Drift's .drift parser/code generator.

PRAGMA foreign_keys = ON;

CREATE TABLE books (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  is_default INTEGER NOT NULL CHECK (is_default IN (0, 1))
);
CREATE UNIQUE INDEX uq_books_single_default
  ON books(is_default) WHERE is_default = 1;

CREATE TABLE currencies (
  code TEXT PRIMARY KEY NOT NULL CHECK (code = upper(code) AND length(code) = 3),
  minor_unit_scale INTEGER NOT NULL CHECK (typeof(minor_unit_scale) = 'integer' AND minor_unit_scale BETWEEN 0 AND 3)
);


CREATE TRIGGER currency_definition_immutable_update
BEFORE UPDATE OF code, minor_unit_scale ON currencies
WHEN NEW.code <> OLD.code OR NEW.minor_unit_scale <> OLD.minor_unit_scale
BEGIN
  SELECT RAISE(ABORT, 'currency code/scale requires an explicit migration');
END;

CREATE TRIGGER currency_definition_immutable_delete
BEFORE DELETE ON currencies
WHEN EXISTS (
  SELECT 1 FROM accounts a WHERE a.currency_code = OLD.code
) OR EXISTS (
  SELECT 1 FROM transactions t WHERE t.currency_code = OLD.code
) OR EXISTS (
  SELECT 1 FROM ledger_entries le WHERE le.currency_code = OLD.code
)
BEGIN
  SELECT RAISE(ABORT, 'referenced currency cannot be deleted');
END;

CREATE TABLE ledger_accounts (
  id TEXT PRIMARY KEY NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('asset','liability','expense','income','equity','system')),
  is_system INTEGER NOT NULL CHECK (is_system IN (0,1)),
  linked_account_nature TEXT CHECK (linked_account_nature IN ('asset','liability')),
  UNIQUE (id, linked_account_nature),
  CHECK (
    (linked_account_nature IS NULL AND type IN ('expense','income','equity','system'))
    OR (linked_account_nature = 'asset' AND type = 'asset' AND is_system = 0)
    OR (linked_account_nature = 'liability' AND type = 'liability' AND is_system = 0)
  )
);

CREATE TABLE accounts (
  book_id TEXT NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
  id TEXT NOT NULL,
  nature TEXT NOT NULL CHECK (nature IN ('asset','liability')),
  currency_code TEXT NOT NULL REFERENCES currencies(code),
  ledger_account_id TEXT NOT NULL UNIQUE,
  PRIMARY KEY (book_id, id),
  FOREIGN KEY (ledger_account_id, nature)
    REFERENCES ledger_accounts(id, linked_account_nature)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE transactions (
  book_id TEXT NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
  id TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN (
    'expense','income','transfer','credit_card_charge','initial_balance','balance_reconciliation'
  )),
  from_account_id TEXT,
  to_account_id TEXT,
  reconciliation_account_id TEXT,
  amount_minor INTEGER NOT NULL CHECK (typeof(amount_minor) = 'integer' AND amount_minor BETWEEN 0 AND 9000000000000000),
  currency_code TEXT NOT NULL REFERENCES currencies(code),
  date_at INTEGER NOT NULL,
  local_date TEXT NOT NULL CHECK (
    length(local_date) = 10 AND local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
  ),
  PRIMARY KEY (book_id, id),
  FOREIGN KEY (book_id, from_account_id) REFERENCES accounts(book_id, id),
  FOREIGN KEY (book_id, to_account_id) REFERENCES accounts(book_id, id),
  FOREIGN KEY (book_id, reconciliation_account_id) REFERENCES accounts(book_id, id),
  CHECK (
    (type = 'expense' AND from_account_id IS NOT NULL AND to_account_id IS NULL AND reconciliation_account_id IS NULL)
    OR (type = 'income' AND from_account_id IS NULL AND to_account_id IS NOT NULL AND reconciliation_account_id IS NULL)
    OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL AND from_account_id <> to_account_id AND reconciliation_account_id IS NULL)
    OR (type = 'credit_card_charge' AND from_account_id IS NULL AND to_account_id IS NOT NULL AND reconciliation_account_id IS NULL)
    OR (type = 'initial_balance' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL AND reconciliation_account_id IS NULL)
    OR (type = 'balance_reconciliation' AND reconciliation_account_id IS NOT NULL)
  )
);

CREATE TRIGGER transactions_account_nature_guard_insert
BEFORE INSERT ON transactions
BEGIN
  SELECT CASE
    WHEN NEW.type = 'expense' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.from_account_id AND a.nature = 'asset'
    ) THEN RAISE(ABORT, 'expense source must be asset')
    WHEN NEW.type = 'income' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.to_account_id AND a.nature = 'asset'
    ) THEN RAISE(ABORT, 'income destination must be asset')
    WHEN NEW.type = 'credit_card_charge' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.to_account_id AND a.nature = 'liability'
    ) THEN RAISE(ABORT, 'credit card charge destination must be liability')
    WHEN NEW.type = 'initial_balance' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.from_account_id AND a.nature = 'liability'
    ) THEN RAISE(ABORT, 'initial balance source must be liability')
  END;
END;

CREATE TRIGGER transactions_currency_matches_accounts_insert
BEFORE INSERT ON transactions
BEGIN
  SELECT CASE
    WHEN NEW.from_account_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.from_account_id AND a.currency_code = NEW.currency_code
    ) THEN RAISE(ABORT, 'from account currency mismatch')
    WHEN NEW.to_account_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.to_account_id AND a.currency_code = NEW.currency_code
    ) THEN RAISE(ABORT, 'to account currency mismatch')
    WHEN NEW.reconciliation_account_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.reconciliation_account_id AND a.currency_code = NEW.currency_code
    ) THEN RAISE(ABORT, 'reconciliation account currency mismatch')
  END;
END;

CREATE TRIGGER transactions_account_nature_guard_update
BEFORE UPDATE OF type, from_account_id, to_account_id, reconciliation_account_id ON transactions
BEGIN
  SELECT CASE
    WHEN NEW.type = 'expense' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.from_account_id AND a.nature = 'asset'
    ) THEN RAISE(ABORT, 'expense source must be asset')
    WHEN NEW.type = 'income' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.to_account_id AND a.nature = 'asset'
    ) THEN RAISE(ABORT, 'income destination must be asset')
    WHEN NEW.type = 'credit_card_charge' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.to_account_id AND a.nature = 'liability'
    ) THEN RAISE(ABORT, 'credit card charge destination must be liability')
    WHEN NEW.type = 'initial_balance' AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.from_account_id AND a.nature = 'liability'
    ) THEN RAISE(ABORT, 'initial balance source must be liability')
  END;
END;

CREATE TRIGGER transactions_currency_matches_accounts_update
BEFORE UPDATE OF from_account_id, to_account_id, reconciliation_account_id, currency_code ON transactions
BEGIN
  SELECT CASE
    WHEN NEW.from_account_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.from_account_id AND a.currency_code = NEW.currency_code
    ) THEN RAISE(ABORT, 'from account currency mismatch')
    WHEN NEW.to_account_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.to_account_id AND a.currency_code = NEW.currency_code
    ) THEN RAISE(ABORT, 'to account currency mismatch')
    WHEN NEW.reconciliation_account_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM accounts a WHERE a.book_id = NEW.book_id AND a.id = NEW.reconciliation_account_id AND a.currency_code = NEW.currency_code
    ) THEN RAISE(ABORT, 'reconciliation account currency mismatch')
  END;
END;

CREATE TABLE financial_corrections (
  book_id TEXT NOT NULL,
  correction_id TEXT NOT NULL,
  original_transaction_id TEXT NOT NULL,
  corrected_transaction_id TEXT NOT NULL,
  PRIMARY KEY (book_id, correction_id),
  UNIQUE (book_id, original_transaction_id),
  UNIQUE (book_id, corrected_transaction_id),
  CHECK (original_transaction_id <> corrected_transaction_id),
  FOREIGN KEY (book_id) REFERENCES books(id),
  FOREIGN KEY (book_id, original_transaction_id) REFERENCES transactions(book_id, id),
  FOREIGN KEY (book_id, corrected_transaction_id) REFERENCES transactions(book_id, id)
);

CREATE TABLE financial_invalidations (
  book_id TEXT NOT NULL,
  invalidation_id TEXT NOT NULL,
  original_transaction_id TEXT NOT NULL,
  PRIMARY KEY (book_id, invalidation_id),
  UNIQUE (book_id, original_transaction_id),
  FOREIGN KEY (book_id) REFERENCES books(id),
  FOREIGN KEY (book_id, original_transaction_id) REFERENCES transactions(book_id, id)
);

CREATE TRIGGER correction_terminal_source_guard
BEFORE INSERT ON financial_corrections
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1 FROM financial_invalidations i
    WHERE i.book_id = NEW.book_id AND i.original_transaction_id = NEW.original_transaction_id
  ) THEN RAISE(ABORT, 'original transaction already invalidated') END;
END;

CREATE TRIGGER invalidation_terminal_source_guard
BEFORE INSERT ON financial_invalidations
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1 FROM financial_corrections c
    WHERE c.book_id = NEW.book_id AND c.original_transaction_id = NEW.original_transaction_id
  ) THEN RAISE(ABORT, 'original transaction already corrected') END;
END;

CREATE TABLE ledger_entries (
  id TEXT PRIMARY KEY NOT NULL,
  book_id TEXT NOT NULL REFERENCES books(id),
  ledger_account_id TEXT NOT NULL REFERENCES ledger_accounts(id),
  transaction_id TEXT,
  correction_id TEXT,
  invalidation_id TEXT,
  correction_role TEXT CHECK (correction_role IN ('reversal','replacement')),
  entry_type TEXT NOT NULL CHECK (entry_type IN ('debit','credit')),
  amount_minor INTEGER NOT NULL CHECK (typeof(amount_minor) = 'integer' AND amount_minor BETWEEN 0 AND 9000000000000000),
  currency_code TEXT NOT NULL REFERENCES currencies(code),
  date_at INTEGER NOT NULL,
  local_date TEXT NOT NULL CHECK (
    length(local_date) = 10 AND local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
  ),
  CHECK (
    (transaction_id IS NOT NULL) + (correction_id IS NOT NULL) + (invalidation_id IS NOT NULL) = 1
  ),
  CHECK (
    (correction_id IS NOT NULL AND correction_role IN ('reversal','replacement'))
    OR (correction_id IS NULL AND correction_role IS NULL)
  ),
  FOREIGN KEY (book_id, transaction_id) REFERENCES transactions(book_id, id),
  FOREIGN KEY (book_id, correction_id) REFERENCES financial_corrections(book_id, correction_id),
  FOREIGN KEY (book_id, invalidation_id) REFERENCES financial_invalidations(book_id, invalidation_id)
);
CREATE INDEX ix_ledger_book_account_date ON ledger_entries(book_id, ledger_account_id, local_date, date_at);
CREATE INDEX ix_ledger_tx ON ledger_entries(book_id, transaction_id) WHERE transaction_id IS NOT NULL;
CREATE INDEX ix_ledger_correction ON ledger_entries(book_id, correction_id) WHERE correction_id IS NOT NULL;

CREATE TRIGGER ledger_entry_account_book_scope_insert
BEFORE INSERT ON ledger_entries
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1 FROM accounts a
    WHERE a.ledger_account_id = NEW.ledger_account_id
      AND a.book_id <> NEW.book_id
  ) THEN RAISE(ABORT, 'user ledger account belongs to another book') END;
END;

CREATE TRIGGER ledger_entry_source_consistency_insert
BEFORE INSERT ON ledger_entries
BEGIN
  SELECT CASE
    WHEN NEW.transaction_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.book_id = NEW.book_id AND t.id = NEW.transaction_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger direct transaction snapshot mismatch')
    WHEN NEW.correction_id IS NOT NULL AND NEW.correction_role = 'reversal' AND NOT EXISTS (
      SELECT 1 FROM financial_corrections c
      JOIN transactions t ON t.book_id = c.book_id AND t.id = c.original_transaction_id
      WHERE c.book_id = NEW.book_id AND c.correction_id = NEW.correction_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger correction reversal snapshot mismatch')
    WHEN NEW.correction_id IS NOT NULL AND NEW.correction_role = 'replacement' AND NOT EXISTS (
      SELECT 1 FROM financial_corrections c
      JOIN transactions t ON t.book_id = c.book_id AND t.id = c.corrected_transaction_id
      WHERE c.book_id = NEW.book_id AND c.correction_id = NEW.correction_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger correction replacement snapshot mismatch')
    WHEN NEW.invalidation_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM financial_invalidations i
      JOIN transactions t ON t.book_id = i.book_id AND t.id = i.original_transaction_id
      WHERE i.book_id = NEW.book_id AND i.invalidation_id = NEW.invalidation_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger invalidation snapshot mismatch')
  END;
END;

CREATE TABLE financial_idempotency (
  idempotency_key TEXT PRIMARY KEY NOT NULL,
  book_id TEXT NOT NULL REFERENCES books(id),
  request_fingerprint TEXT NOT NULL CHECK (length(trim(request_fingerprint)) > 0),
  record_format_version INTEGER NOT NULL CHECK (record_format_version > 0),
  result_type TEXT NOT NULL CHECK (result_type = 'operationSucceeded'),
  completed_at INTEGER NOT NULL,
  UNIQUE (idempotency_key, book_id)
);
CREATE TABLE financial_idempotency_transactions (
  idempotency_key TEXT NOT NULL,
  book_id TEXT NOT NULL,
  ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
  transaction_id TEXT NOT NULL,
  PRIMARY KEY (idempotency_key, ordinal),
  FOREIGN KEY (idempotency_key, book_id) REFERENCES financial_idempotency(idempotency_key, book_id),
  FOREIGN KEY (book_id, transaction_id) REFERENCES transactions(book_id, id)
);

CREATE TRIGGER ledger_entry_account_book_scope_update
BEFORE UPDATE OF book_id, ledger_account_id ON ledger_entries
BEGIN
  SELECT CASE WHEN EXISTS (
    SELECT 1 FROM accounts a
    WHERE a.ledger_account_id = NEW.ledger_account_id
      AND a.book_id <> NEW.book_id
  ) THEN RAISE(ABORT, 'user ledger account belongs to another book') END;
END;

CREATE TRIGGER ledger_entry_source_consistency_update
BEFORE UPDATE OF book_id, transaction_id, correction_id, invalidation_id, correction_role, amount_minor, currency_code, date_at, local_date ON ledger_entries
BEGIN
  SELECT CASE
    WHEN NEW.transaction_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.book_id = NEW.book_id AND t.id = NEW.transaction_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger direct transaction snapshot mismatch')
    WHEN NEW.correction_id IS NOT NULL AND NEW.correction_role = 'reversal' AND NOT EXISTS (
      SELECT 1 FROM financial_corrections c
      JOIN transactions t ON t.book_id = c.book_id AND t.id = c.original_transaction_id
      WHERE c.book_id = NEW.book_id AND c.correction_id = NEW.correction_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger correction reversal snapshot mismatch')
    WHEN NEW.correction_id IS NOT NULL AND NEW.correction_role = 'replacement' AND NOT EXISTS (
      SELECT 1 FROM financial_corrections c
      JOIN transactions t ON t.book_id = c.book_id AND t.id = c.corrected_transaction_id
      WHERE c.book_id = NEW.book_id AND c.correction_id = NEW.correction_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger correction replacement snapshot mismatch')
    WHEN NEW.invalidation_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM financial_invalidations i
      JOIN transactions t ON t.book_id = i.book_id AND t.id = i.original_transaction_id
      WHERE i.book_id = NEW.book_id AND i.invalidation_id = NEW.invalidation_id
        AND t.amount_minor = NEW.amount_minor AND t.currency_code = NEW.currency_code
        AND t.date_at = NEW.date_at AND t.local_date = NEW.local_date
    ) THEN RAISE(ABORT, 'ledger invalidation snapshot mismatch')
  END;
END;

CREATE TABLE schedule_rules (
  book_id TEXT NOT NULL REFERENCES books(id),
  id TEXT NOT NULL CHECK (instr(id, '|') = 0),
  frequency TEXT NOT NULL CHECK (frequency IN ('oneTime','daily','weekly','monthly','yearly')),
  start_date TEXT NOT NULL,
  next_due_date TEXT NOT NULL,
  PRIMARY KEY (book_id, id),
  CHECK (next_due_date >= start_date)
);
CREATE TABLE schedule_occurrences (
  book_id TEXT NOT NULL,
  id TEXT NOT NULL,
  schedule_rule_id TEXT NOT NULL,
  due_date TEXT NOT NULL CHECK (
    length(due_date) = 10 AND due_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
  ),
  status TEXT NOT NULL CHECK (status IN ('pending','skipped','completed')),
  PRIMARY KEY (book_id, id),
  UNIQUE (book_id, schedule_rule_id, due_date),
  FOREIGN KEY (book_id, schedule_rule_id) REFERENCES schedule_rules(book_id, id),
  CHECK (id = schedule_rule_id || '|' || due_date)
);

CREATE TABLE financing_contracts (
  book_id TEXT NOT NULL,
  contract_id TEXT NOT NULL,
  liability_account_id TEXT NOT NULL,
  origin_charge_transaction_id TEXT NOT NULL,
  principal_minor INTEGER NOT NULL CHECK (typeof(principal_minor) = 'integer' AND principal_minor BETWEEN 1 AND 9000000000000000),
  PRIMARY KEY (book_id, contract_id),
  UNIQUE (book_id, contract_id, liability_account_id),
  FOREIGN KEY (book_id, liability_account_id) REFERENCES accounts(book_id, id),
  FOREIGN KEY (book_id, origin_charge_transaction_id) REFERENCES transactions(book_id, id)
);
CREATE TABLE financing_schedules (
  book_id TEXT NOT NULL,
  schedule_id TEXT NOT NULL,
  contract_id TEXT NOT NULL,
  schedule_rule_id TEXT NOT NULL,
  PRIMARY KEY (book_id, schedule_id),
  UNIQUE (book_id, schedule_id, contract_id),
  UNIQUE (book_id, schedule_id, contract_id, schedule_rule_id),
  FOREIGN KEY (book_id, contract_id) REFERENCES financing_contracts(book_id, contract_id),
  FOREIGN KEY (book_id, schedule_rule_id) REFERENCES schedule_rules(book_id, id)
);
CREATE TABLE financing_installments (
  book_id TEXT NOT NULL,
  installment_id TEXT NOT NULL,
  contract_id TEXT NOT NULL,
  schedule_id TEXT NOT NULL,
  sequence INTEGER NOT NULL CHECK (sequence > 0),
  principal_component_minor INTEGER NOT NULL CHECK (typeof(principal_component_minor) = 'integer' AND principal_component_minor >= 0),
  interest_component_minor INTEGER NOT NULL CHECK (typeof(interest_component_minor) = 'integer' AND interest_component_minor >= 0),
  fees_minor INTEGER NOT NULL CHECK (typeof(fees_minor) = 'integer' AND fees_minor >= 0),
  amount_minor INTEGER NOT NULL CHECK (typeof(amount_minor) = 'integer' AND amount_minor >= 0),
  PRIMARY KEY (book_id, installment_id),
  UNIQUE (book_id, schedule_id, sequence),
  FOREIGN KEY (book_id, schedule_id, contract_id)
    REFERENCES financing_schedules(book_id, schedule_id, contract_id),
  CHECK (amount_minor = principal_component_minor + interest_component_minor + fees_minor)
);
CREATE TABLE financing_conversion_events (
  book_id TEXT NOT NULL,
  conversion_id TEXT NOT NULL,
  origin_charge_id TEXT NOT NULL,
  contract_id TEXT NOT NULL,
  schedule_id TEXT NOT NULL,
  schedule_rule_id TEXT NOT NULL,
  PRIMARY KEY (book_id, conversion_id),
  UNIQUE (book_id, origin_charge_id),
  FOREIGN KEY (book_id, origin_charge_id) REFERENCES transactions(book_id, id),
  FOREIGN KEY (book_id, contract_id) REFERENCES financing_contracts(book_id, contract_id),
  FOREIGN KEY (book_id, schedule_id, contract_id, schedule_rule_id)
    REFERENCES financing_schedules(book_id, schedule_id, contract_id, schedule_rule_id),
  FOREIGN KEY (book_id, schedule_rule_id) REFERENCES schedule_rules(book_id, id)
);
