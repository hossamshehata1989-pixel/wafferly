from __future__ import annotations

import sqlite3
from pathlib import Path

SCHEMA = Path(__file__).with_name("representative_schema.sql")


def new_db() -> sqlite3.Connection:
    con = sqlite3.connect(":memory:", isolation_level=None)
    con.execute("PRAGMA foreign_keys = ON")
    assert con.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    con.executescript(SCHEMA.read_text(encoding="utf-8"))
    assert con.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    return con


def expect_integrity_error(fn, label: str) -> None:
    try:
        fn()
    except sqlite3.IntegrityError:
        print(f"PASS negative: {label}")
    else:
        raise AssertionError(f"Expected sqlite3.IntegrityError: {label}")


def seed_reference_data(con: sqlite3.Connection) -> None:
    con.executemany(
        "INSERT INTO books(id,name,is_default) VALUES(?,?,?)",
        [("default", "Personal", 1), ("family", "Family", 0)],
    )
    con.execute("INSERT INTO currencies(code,minor_unit_scale) VALUES('EGP',2)")
    con.executemany(
        "INSERT INTO ledger_accounts(id,type,is_system,linked_account_nature) VALUES(?,?,?,?)",
        [
            ("la-bank-default", "asset", 0, "asset"),
            ("la-card-default", "liability", 0, "liability"),
            ("la-bank-family", "asset", 0, "asset"),
            ("la-expense", "expense", 1, None),
            ("la-equity", "equity", 1, None),
        ],
    )
    con.executemany(
        "INSERT INTO accounts(book_id,id,nature,currency_code,ledger_account_id) VALUES(?,?,?,?,?)",
        [
            ("default", "bank-1", "asset", "EGP", "la-bank-default"),
            ("default", "card-1", "liability", "EGP", "la-card-default"),
            ("family", "bank-2", "asset", "EGP", "la-bank-family"),
        ],
    )


def insert_tx(con, book, tx_id, tx_type, *, amount=10000, currency="EGP", date_at=1793493000000, local_date="2026-11-01", from_account=None, to_account=None, reconciliation=None):
    con.execute(
        """INSERT INTO transactions(
          book_id,id,type,from_account_id,to_account_id,reconciliation_account_id,
          amount_minor,currency_code,date_at,local_date
        ) VALUES(?,?,?,?,?,?,?,?,?,?)""",
        (book, tx_id, tx_type, from_account, to_account, reconciliation,
         amount, currency, date_at, local_date),
    )


def insert_ledger(con, *, row_id, book, ledger_account, amount=10000, currency="EGP", date_at=1793493000000,
                  local_date="2026-11-01", tx=None, correction=None, invalidation=None, role=None, entry_type="debit"):
    con.execute(
        """INSERT INTO ledger_entries(
          id,book_id,ledger_account_id,transaction_id,correction_id,invalidation_id,correction_role,
          entry_type,amount_minor,currency_code,date_at,local_date
        ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)""",
        (row_id,book,ledger_account,tx,correction,invalidation,role,entry_type,amount,currency,date_at,local_date),
    )


def test_partial_unique_and_composite_nature() -> None:
    con = new_db(); seed_reference_data(con)
    expect_integrity_error(
        lambda: con.execute("INSERT INTO books VALUES('second-default','Other',1)"),
        "partial unique index permits only one default Book",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO accounts VALUES('default','wrong-nature','liability','EGP','la-bank-default')"),
        "composite FK rejects Account nature mismatch",
    )
    # Shared Chart row has NULL linked_account_nature and remains shared.
    insert_tx(con, "default", "tx-exp", "expense", from_account="bank-1")
    insert_ledger(con, row_id="le-exp-shared", book="default", ledger_account="la-expense", tx="tx-exp")
    print("PASS positive: shared Chart account can be used in a Book")
    con.close()


def test_book_scope_and_sources() -> None:
    con = new_db(); seed_reference_data(con)
    insert_tx(con, "default", "tx-exp", "expense", from_account="bank-1", amount=10000, date_at=1000, local_date="2026-11-01")
    insert_tx(con, "default", "tx-corrected", "expense", from_account="bank-1", amount=8000, date_at=2000, local_date="2026-11-02")
    insert_tx(con, "default", "tx-to-invalidate", "expense", from_account="bank-1", amount=5000, date_at=3000, local_date="2026-11-03")

    # Direct source, shared Chart account and matching snapshot.
    insert_ledger(con, row_id="le-direct", book="default", ledger_account="la-expense", tx="tx-exp", amount=10000, date_at=1000, local_date="2026-11-01")
    print("PASS positive: direct Transaction source snapshot")

    expect_integrity_error(
        lambda: insert_ledger(con, row_id="le-direct-bad", book="default", ledger_account="la-expense", tx="tx-exp", amount=9999, date_at=1000, local_date="2026-11-01"),
        "direct source snapshot rejects wrong amount",
    )
    expect_integrity_error(
        lambda: insert_ledger(con, row_id="le-cross-book", book="default", ledger_account="la-bank-family", tx="tx-exp", amount=10000, date_at=1000, local_date="2026-11-01"),
        "user Ledger counterpart cannot be posted in another Book",
    )

    con.execute(
        "INSERT INTO financial_corrections(book_id,correction_id,original_transaction_id,corrected_transaction_id) VALUES('default','cor-1','tx-exp','tx-corrected')"
    )
    insert_ledger(con, row_id="le-reversal", book="default", ledger_account="la-expense", correction="cor-1", role="reversal", amount=10000, date_at=1000, local_date="2026-11-01")
    insert_ledger(con, row_id="le-replacement", book="default", ledger_account="la-expense", correction="cor-1", role="replacement", amount=8000, date_at=2000, local_date="2026-11-02")
    print("PASS positive: correction reversal and replacement can follow different source snapshots")
    expect_integrity_error(
        lambda: insert_ledger(con, row_id="le-replacement-bad", book="default", ledger_account="la-expense", correction="cor-1", role="replacement", amount=8000, date_at=1000, local_date="2026-11-01"),
        "replacement must match corrected Transaction snapshot",
    )
    con.execute(
        "INSERT INTO financial_invalidations(book_id,invalidation_id,original_transaction_id) VALUES('default','inv-1','tx-to-invalidate')"
    )
    insert_ledger(con, row_id="le-invalidation", book="default", ledger_account="la-expense", invalidation="inv-1", amount=5000, date_at=3000, local_date="2026-11-03")
    print("PASS positive: invalidation source snapshot")
    expect_integrity_error(
        lambda: con.execute("INSERT INTO financial_invalidations(book_id,invalidation_id,original_transaction_id) VALUES('default','inv-conflict','tx-exp')"),
        "terminal source guard rejects invalidating an already corrected Transaction",
    )
    expect_integrity_error(
        lambda: insert_ledger(con, row_id="le-no-source", book="default", ledger_account="la-expense"),
        "exactly-one source CHECK rejects source-less Ledger Entry",
    )
    con.close()


def test_transactions_shape_nature_and_currency() -> None:
    con = new_db(); seed_reference_data(con)
    insert_tx(con, "default", "tx-exp", "expense", from_account="bank-1")
    print("PASS positive: Expense uses Asset source")
    expect_integrity_error(
        lambda: insert_tx(con, "default", "tx-charge-wrong", "credit_card_charge", to_account="bank-1"),
        "credit-card charge rejects Asset destination",
    )
    expect_integrity_error(
        lambda: insert_tx(con, "default", "tx-transfer-cross", "transfer", from_account="bank-1", to_account="bank-2"),
        "composite account FK rejects cross-Book Transaction",
    )
    expect_integrity_error(
        lambda: insert_tx(con, "default", "tx-bad-shape", "expense", to_account="bank-1"),
        "Transaction type-shape CHECK rejects Expense with destination only",
    )
    con.close()


def test_schedule_and_financing_order_atomicity() -> None:
    con = new_db(); seed_reference_data(con)
    insert_tx(con, "default", "charge-1", "credit_card_charge", to_account="card-1", amount=12000)
    # The event cannot be inserted first because its FKs are immediate by default.
    expect_integrity_error(
        lambda: con.execute("INSERT INTO financing_conversion_events VALUES('default','conv-early','charge-1','contract-1','schedule-1','rule-1')"),
        "conversion receipt cannot be inserted before Contract/Schedule/Rule",
    )
    # Required order in one transaction: Contract -> Rule -> Schedule -> Installments -> Receipt.
    con.execute("BEGIN")
    con.execute("INSERT INTO financing_contracts VALUES('default','contract-1','card-1','charge-1',12000)")
    con.execute("INSERT INTO schedule_rules VALUES('default','rule-1','monthly','2026-12-01','2026-12-01')")
    con.execute("INSERT INTO financing_schedules VALUES('default','schedule-1','contract-1','rule-1')")
    con.execute("INSERT INTO financing_installments VALUES('default','inst-1','contract-1','schedule-1',1,12000,0,0,12000)")
    con.execute("INSERT INTO financing_conversion_events VALUES('default','conv-1','charge-1','contract-1','schedule-1','rule-1')")
    con.commit()
    print("PASS positive: Financing Conversion inserts in dependency order")

    expect_integrity_error(
        lambda: con.execute("INSERT INTO financing_contracts VALUES('default','contract-fractional','card-1','charge-1',1.5)"),
        "financing principal must reject fractional Minor Units",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO financing_installments VALUES('default','inst-fractional-principal','contract-1','schedule-1',2,1.5,0.5,0,2)"),
        "installment component Minor Units must be stored as integers",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO financing_installments VALUES('default','inst-fractional-interest','contract-1','schedule-1',2,0.5,1.5,0,2)"),
        "installment interest Minor Units must be stored as integers",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO financing_installments VALUES('default','inst-fractional-fees','contract-1','schedule-1',2,0.5,0,1.5,2)"),
        "installment fee Minor Units must be stored as integers",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO financing_installments VALUES('default','inst-fractional-total','contract-1','schedule-1',2,1,1,0,2.5)"),
        "installment total Minor Units must be stored as integers",
    )
    # A separate transaction failure after Contract insertion rolls back all dependent writes.
    try:
        con.execute("BEGIN")
        con.execute("INSERT INTO financing_contracts VALUES('default','contract-rollback','card-1','charge-1',1000)")
        con.execute("INSERT INTO schedule_rules VALUES('default','rule-rollback','monthly','2026-12-01','2026-12-01')")
        raise RuntimeError("simulated failure before Schedule insert")
    except RuntimeError:
        con.rollback()
    assert con.execute("SELECT count(*) FROM financing_contracts WHERE contract_id='contract-rollback'").fetchone()[0] == 0
    assert con.execute("SELECT count(*) FROM schedule_rules WHERE id='rule-rollback'").fetchone()[0] == 0
    print("PASS positive: SQLite rollback removes all earlier writes in transaction")
    # Occurrence identity is canonical from rule and civil date.
    con.execute("INSERT INTO schedule_occurrences VALUES('default','rule-1|2026-12-01','rule-1','2026-12-01','pending')")
    expect_integrity_error(
        lambda: con.execute("INSERT INTO schedule_occurrences VALUES('default','rule-1|2026-12-01T00:00:00.000','rule-1','2026-12-01','pending')"),
        "Occurrence CHECK rejects non-canonical timestamp-based identity",
    )
    con.close()



def test_integer_storage_and_update_guards() -> None:
    con = new_db(); seed_reference_data(con)
    insert_tx(con, "default", "tx-valid", "expense", from_account="bank-1")
    expect_integrity_error(
        lambda: insert_tx(con, "default", "tx-fractional", "expense", from_account="bank-1", amount=12.5),
        "INTEGER affinity alone is insufficient; typeof CHECK rejects fractional minor units",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO ledger_entries(id,book_id,ledger_account_id,transaction_id,entry_type,amount_minor,currency_code,date_at,local_date) VALUES('le-fractional','default','la-expense','tx-valid','debit',1.25,'EGP',1793493000000,'2026-11-01')"),
        "Ledger amount must reject fractional Minor Units",
    )
    expect_integrity_error(
        lambda: con.execute("INSERT INTO currencies(code,minor_unit_scale) VALUES('XYZ',1.5)"),
        "currency scale must be stored as an integer",
    )
    expect_integrity_error(
        lambda: con.execute("UPDATE currencies SET minor_unit_scale=3 WHERE code='EGP'"),
        "currency scale cannot be changed in place",
    )
    # UPDATE triggers must enforce the same invariant as INSERT triggers.
    expect_integrity_error(
        lambda: con.execute("UPDATE transactions SET from_account_id='card-1' WHERE id='tx-valid' AND book_id='default'"),
        "Transaction UPDATE cannot change Expense source to Liability",
    )
    expect_integrity_error(
        lambda: con.execute("UPDATE transactions SET amount_minor=1.25 WHERE id='tx-valid' AND book_id='default'"),
        "Transaction UPDATE cannot store fractional Minor Units",
    )
    con.execute("INSERT INTO ledger_entries(id,book_id,ledger_account_id,transaction_id,entry_type,amount_minor,currency_code,date_at,local_date) VALUES('le-update','default','la-expense','tx-valid','debit',10000,'EGP',1793493000000,'2026-11-01')")
    expect_integrity_error(
        lambda: con.execute("UPDATE ledger_entries SET ledger_account_id='la-bank-family' WHERE id='le-update'"),
        "Ledger Account Book scope is enforced on UPDATE",
    )
    expect_integrity_error(
        lambda: con.execute("UPDATE ledger_entries SET amount_minor=9999 WHERE id='le-update'"),
        "Ledger source snapshot is enforced on UPDATE",
    )
    con.close()


def test_idempotency_receipt_atomicity() -> None:
    con = new_db(); seed_reference_data(con)
    try:
        con.execute("BEGIN")
        insert_tx(con, "default", "tx-atomic", "expense", from_account="bank-1")
        insert_ledger(con, row_id="le-atomic", book="default", ledger_account="la-expense", tx="tx-atomic")
        con.execute(
            "INSERT INTO financial_idempotency VALUES('idem-atomic','default','fingerprint-1',2,'operationSucceeded',1793493000000)"
        )
        con.execute(
            "INSERT INTO financial_idempotency_transactions VALUES('idem-atomic','default',0,'tx-atomic')"
        )
        raise RuntimeError("simulated failure before commit")
    except RuntimeError:
        con.rollback()
    assert con.execute("SELECT count(*) FROM transactions WHERE id='tx-atomic'").fetchone()[0] == 0
    assert con.execute("SELECT count(*) FROM ledger_entries WHERE id='le-atomic'").fetchone()[0] == 0
    assert con.execute("SELECT count(*) FROM financial_idempotency WHERE idempotency_key='idem-atomic'").fetchone()[0] == 0
    assert con.execute("SELECT count(*) FROM financial_idempotency_transactions WHERE idempotency_key='idem-atomic'").fetchone()[0] == 0
    print("PASS positive: transaction, ledger, Idempotency receipt and result rows roll back together")
    con.close()


def main() -> None:
    con = sqlite3.connect(":memory:")
    print(f"SQLite engine: {sqlite3.sqlite_version}")
    print("Foreign keys are OFF by default:", con.execute("PRAGMA foreign_keys").fetchone()[0])
    con.close()
    test_partial_unique_and_composite_nature()
    test_book_scope_and_sources()
    test_transactions_shape_nature_and_currency()
    test_schedule_and_financing_order_atomicity()
    test_integer_storage_and_update_guards()
    test_idempotency_receipt_atomicity()
    print("\nALL SQLITE SPIKE TESTS PASSED")


if __name__ == "__main__":
    main()
